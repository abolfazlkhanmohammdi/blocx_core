import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:blocx_core/form_bloc.dart';

// ---------------------------------------------------------------------------
// 1. Domain Entity
// ---------------------------------------------------------------------------

class TaskEntity extends BlocxBaseEntity {
  final String id;
  final String title;
  final bool isCompleted;

  const TaskEntity({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  @override
  String get identifier => id;
}

// ---------------------------------------------------------------------------
// 2. Use Cases (with automatic EventHub command broadcasting)
// ---------------------------------------------------------------------------

class LoadTasksUseCase
    extends BlocxPaginatedUseCase<BlocxPaginatedInput, TaskEntity> {
  LoadTasksUseCase({super.eventHub});

  @override
  Future<BlocxUseCaseResult<BlocxPage<TaskEntity>>> perform(
    BlocxPaginatedInput input,
  ) async {
    return success(
      BlocxPage<TaskEntity>(
        items: const [
          TaskEntity(id: '1', title: 'Design BlocX Architecture'),
          TaskEntity(id: '2', title: 'Publish blocx_core 1.0.0'),
        ],
        offset: input.offset,
        limit: input.limit,
      ),
    );
  }
}

class SaveTaskUseCase extends BlocxBaseUseCase<TaskEntity, TaskEntity> {
  SaveTaskUseCase({bool isCreate = true, super.eventHub})
    : super(
        commandType: isCreate
            ? BlocxCommandType.create
            : BlocxCommandType.update,
      );

  @override
  Future<BlocxUseCaseResult<TaskEntity>> perform(TaskEntity input) async {
    return success(input);
  }
}

// ---------------------------------------------------------------------------
// 3. Collection BLoC
// ---------------------------------------------------------------------------

class TasksCollectionBloc extends BlocxCollectionBloc<TaskEntity, void>
    with
        BlocxCollectionInfiniteMixin<TaskEntity, void>,
        BlocxCollectionRefreshableMixin<TaskEntity, void>,
        BlocxCollectionSyncStreamMixin<TaskEntity, void> {
  final LoadTasksUseCase loadTasksUseCase;

  @override
  final BlocxEventHub eventHub;

  TasksCollectionBloc({required this.loadTasksUseCase, required this.eventHub})
    : super();

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TaskEntity>?
  get paginationTask {
    return BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TaskEntity>(
      useCase: loadTasksUseCase,
      inputBuilder: (offset, limit) =>
          BlocxPaginatedInput(offset: offset, limit: limit),
    );
  }

  @override
  bool shouldSyncEntity(TaskEntity entity, BlocxCommandType command) => true;
}

// ---------------------------------------------------------------------------
// 4. Form BLoC & Validation
// ---------------------------------------------------------------------------

enum TaskFormField { title }

class TaskFormEntity
    extends BlocxBaseFormEntity<TaskFormEntity, TaskFormField> {
  final String id;
  final String title;

  const TaskFormEntity({this.id = 'new', this.title = ''});

  @override
  String get identifier => id;

  TaskFormEntity copyWith({String? id, String? title}) =>
      TaskFormEntity(id: id ?? this.id, title: title ?? this.title);

  @override
  TaskFormEntity updateByKey(TaskFormField key, dynamic value) => switch (key) {
    TaskFormField.title => copyWith(title: value as String? ?? ''),
  };

  @override
  dynamic getValueByKey(TaskFormField key) => switch (key) {
    TaskFormField.title => title,
  };
}

class TaskFormValidator
    extends BlocxFormValidator<TaskFormEntity, TaskFormField> {
  @override
  List<TaskFormField> formKeys() => TaskFormField.values;

  @override
  List<BlocxFieldValidator<TaskFormEntity, TaskFormField, dynamic>>
  getValidatorsByKey(TaskFormEntity formData, TaskFormField key) =>
      switch (key) {
        TaskFormField.title => [
          BlocxStringRequiredValidator(),
          const BlocxStringMinLengthValidator(3),
        ],
      };
}

class TaskFormBloc
    extends BlocxFormBloc<TaskFormEntity, TaskEntity, TaskFormField>
    with BlocxFormValidationMixin<TaskFormEntity, TaskEntity, TaskFormField> {
  final SaveTaskUseCase saveTaskUseCase;

  @override
  final BlocxFormValidator<TaskFormEntity, TaskFormField> validator =
      TaskFormValidator();

  TaskFormBloc({required this.saveTaskUseCase}) : super(const TaskFormEntity());

  @override
  List<TaskFormField> get formKeysList => TaskFormField.values;

  @override
  FormValidationMode get formValidationMode =>
      FormValidationMode.onUserInteraction;

  @override
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask {
    return BlocxUseCaseTask<TaskEntity, TaskEntity>(
      useCase: saveTaskUseCase,
      inputBuilder: () => TaskEntity(id: formData.id, title: formData.title),
    );
  }

  @override
  FutureOr<bool> onFormSubmitted(
    Emitter<BlocxFormState<TaskFormEntity, TaskFormField>> emit,
    BlocxUseCaseResult<Object?> result,
  ) {
    displayInfoSnackbar('Task saved');
    return true;
  }
}

// ---------------------------------------------------------------------------
// 5. Run Example
// ---------------------------------------------------------------------------

Future<void> main() async {
  final eventHub = BlocxSimpleEventHub();

  final tasksBloc = TasksCollectionBloc(
    loadTasksUseCase: LoadTasksUseCase(eventHub: eventHub),
    eventHub: eventHub,
  );
  final formBloc = TaskFormBloc(
    saveTaskUseCase: SaveTaskUseCase(isCreate: true, eventHub: eventHub),
  );

  // 1. Load initial collection page
  tasksBloc.add(BlocxCollectionEventLoadInitialPage(payload: null));
  await Future<void>.delayed(const Duration(milliseconds: 50));
  print(
    'Initial tasks (${tasksBloc.list.length}): '
    '${tasksBloc.list.map((t) => t.title).toList()}',
  );

  // 2. Update & submit the form — SaveTaskUseCase broadcasts a create command
  //    to eventHub, which automatically syncs into TasksCollectionBloc!
  formBloc.add(
    BlocxFormEventUpdateData(
      key: TaskFormField.title,
      data: 'Write blocx_core example',
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 50));
  formBloc.add(BlocxFormEventSubmit());
  await Future<void>.delayed(const Duration(milliseconds: 50));

  print(
    'Tasks after form submission (${tasksBloc.list.length}): '
    '${tasksBloc.list.map((t) => t.title).toList()}',
  );

  await formBloc.close();
  await tasksBloc.close();
  eventHub.dispose();
}
