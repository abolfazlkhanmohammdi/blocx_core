---
name: blocx-core
description: >-
  Architect, implement, refactor, and test pure-Dart domain models, use cases,
  event-hub command streams, collection blocs, and form blocs using the blocx_core
  package. Use this skill whenever working with blocx_core, BlocxBaseBloc,
  BlocxCollectionBloc, BlocxFormBloc, BlocxBaseEntity, BlocxBaseFormEntity,
  BlocxBaseUseCase, BlocxPaginatedUseCase, BlocxSearchUseCase, BlocxUseCaseTask,
  BlocxPaginatedUseCaseTask, BlocxEventHub, BlocxSimpleEventHub, BlocxCommandType,
  BlocxCollectionSyncStreamMixin, BlocxFormSyncStreamMixin, BlocxFormValidator,
  ScreenManagerCubit, BlocxErrorTranslator, or BlocXLocalizations.
---

# `blocx_core` Comprehensive Architecture & Implementation Skill

`blocx_core` is a pure-Dart state-management and domain-orchestration library built on `package:bloc`. It provides standardized abstractions for **Entities**, **UseCases**, **EventHub CRUD command broadcasting**, **Paginated/Interactive Collection BLoCs**, **Validated/Multi-step Form BLoCs**, **Error Translation**, and **Screen Management**.

---

## 1. Barrel Exports & Imports

`blocx_core` exposes three barrel files. Import only what your file needs:

```dart
// 1. Core: BlocxBaseEntity, BlocxBaseUseCase, BlocxSearchUseCase, BlocxUseCaseResult,
//    BlocxUseCaseTask, BlocxPaginatedUseCaseTask, BlocxBaseBloc, ScreenManagerCubit,
//    BlocxEventHub, BlocxSimpleEventHub, BlocxAppEvent, BlocxEntityEvent, BlocxCommandType,
//    BlocxEventHubMixin, ReadableError, BlocxErrorTranslator, BlocXErrorCode, BlocXLocalizations
import 'package:blocx_core/blocx_core.dart';

// 2. Collection BLoC: BlocxCollectionBloc, BlocxCollectionEvent*, BlocxCollectionState*,
//    ListStateExtensions, BlocxPage, BlocxPaginatedUseCase, BlocxPaginatedInput,
//    BlocxInfiniteListBloc, SelectionChangedData, and all 10 Collection Mixins
import 'package:blocx_core/collection_bloc.dart';

// 3. Form BLoC: BlocxFormBloc, BlocxFormEvent*, BlocxFormState*, BlocxBaseFormEntity,
//    BlocxFormValidator, BlocxFieldValidator, TimedErrorMessage, FormValidationMode,
//    all 5 Form Mixins, and 35+ built-in Field Validators
import 'package:blocx_core/form_bloc.dart';
```

---

## 2. Six Non-Negotiable Architectural Rules

### Rule 1: Pure Dart Only
`blocx_core` has zero Flutter dependencies. Never import `package:flutter/...` or `BuildContext` inside `blocx_core` entities, use cases, validators, or BLoCs. UI feedback (snackbars, error pages, back navigation) is signaled through the pure-Dart `ScreenManagerCubit` owned by `BlocxBaseBloc`.

### Rule 2: Only UseCases Emit App Events — BLoCs Never Do
- **Why**: App-wide state changes (`create`, `read`, `update`, `delete`) originate from domain business operations (UseCases), not from UI state holders (BLoCs).
- **UseCases** accept an optional `BlocxEventHub? eventHub` and `commandType` / `commandTypes` in `super(eventHub: eventHub, commandType: ...)` (or by overriding the `commandType` / `commandTypes` getters). When `useCase.execute(input)` succeeds, `BlocxBaseUseCase` automatically resolves affected `BlocxBaseEntity` instances and emits `BlocxEntityEvent`s to `eventHub`.
- **Base BLoCs** (`BlocxBaseBloc`, `BlocxCollectionBloc`, `BlocxFormBloc`) **do not** accept or expose `eventHub` and **must never emit** to `BlocxEventHub`.
- **BLoCs only listen** to `BlocxEventHub` by mixing in:
  - `BlocxCollectionSyncStreamMixin<Entity, Payload>` (for collection BLoCs)
  - `BlocxFormSyncStreamMixin<F, P, E, WatchedEntity>` (for form BLoCs)
  - `BlocxEventHubMixin<E, S>` (listener-only helper for custom `BlocxBaseBloc` subclasses)

### Rule 3: Exact Generic Type Signatures
Do not invent extra type parameters on base classes:
- `BlocxBaseBloc<E extends BlocxBaseEvent, S extends BlocxBaseState>` (**2** type params)
- `BlocxCollectionBloc<Entity extends BlocxBaseEntity, Payload>` (**2** type params — use `void` for `Payload` when no initial payload is needed)
- `BlocxFormBloc<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>` (**3** type params — `F`: form entity, `P`: edit hydration payload or `void`, `E`: field enum)
- `BlocxBaseUseCase<Input, Output>` (**2** type params)
- `BlocxPaginatedUseCase<Input extends BlocxPaginatedInput, Entity extends BlocxBaseEntity>` (**2** type params)
- `BlocxSearchUseCase<Input extends BlocxSearchInput, Entity extends BlocxBaseEntity>` (**2** type params)

### Rule 4: Internal `ScreenManagerCubit`
`BlocxBaseBloc` constructs and closes its own `ScreenManagerCubit` internally.
- Never pass `ScreenManagerCubit` into a BLoC constructor.
- Call `super(initialState)` in `BlocxBaseBloc`, `super()` in `BlocxCollectionBloc`, and `super(initialFormData)` in `BlocxFormBloc`.
- Trigger screen actions from inside BLoCs using built-in methods: `pop()`, `displayInfoSnackbar(msg)`, `displayWarningSnackbar(msg)`, `displayErrorSnackbar(msg)`, `displayErrorWidget(readableError)`, or `handleError(error, emit, stacktrace: st)`.

### Rule 5: Auto-Initialized Mixins & Constructor Field Ordering
`BlocxCollectionBloc` and `BlocxFormBloc` automatically call every mixin's `init*()` method (`initRefresh()`, `initInfiniteList()`, `initSearch()`, `initSelection()`, `initDeletable()`, `initHighlight()`, `initExpandable()`, `initScrollable()`, `initFilters()`, `initStreams()`, `initValidation()`, `initStepped()`, `initUniqueFieldChecker()`, `initInfoFetcher()`) inside their `super()` constructor body.
- **Never** call `initRefresh()`, `initStreams()`, etc. manually in your subclass constructor body—doing so registers duplicate `on<Event>` handlers.
- **Critical**: Because `super()` calls `initStreams()` immediately, any field accessed by `init*()` (such as `@override final BlocxEventHub eventHub;`) **must** be initialized in the constructor parameter/initializer list (`MyBloc({required this.eventHub}) : super()`), **never** inside the `{ ... }` constructor body.

### Rule 6: UseCase `perform(input)` vs `execute(input)` & Lazy Task Wrappers
- **Inside a UseCase**: Override `Future<BlocxUseCaseResult<Output>> perform(Input input)` and wrap the return value with `return success(data);` (exceptions thrown inside `perform` are automatically caught by `execute` and converted via `failureResult`).
- **Calling a UseCase**: Always call `await useCase.execute(input)`.
- **Connecting BLoCs to UseCases**: Use lazy task wrappers so inputs are constructed at execution time with the latest state:
  - `BlocxUseCaseTask<Input, Output>(useCase: ..., inputBuilder: () => ...)`
  - `BlocxPaginatedUseCaseTask<Input, Entity>(useCase: ..., inputBuilder: (offset, limit) => ...)` *(Note: `(offset, limit)` are positional parameters).*

---

## 3. Core Workflows & Code Blueprints

### Blueprint A: Domain Entity & UseCases with EventHub Broadcasting

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

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

  TaskEntity copyWith({String? id, String? title, bool? isCompleted}) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// 1. Paginated Read UseCase (defaults to BlocxCommandType.read)
class LoadTasksUseCase extends BlocxPaginatedUseCase<BlocxPaginatedInput, TaskEntity> {
  LoadTasksUseCase({super.eventHub});

  @override
  Future<BlocxUseCaseResult<BlocxPage<TaskEntity>>> perform(BlocxPaginatedInput input) async {
    return success(
      BlocxPage<TaskEntity>(
        items: const [],
        offset: input.offset,
        limit: input.limit,
      ),
    );
  }
}

// 2. Create/Update UseCase (Output is TaskEntity -> auto-resolved for EventHub)
class SaveTaskUseCase extends BlocxBaseUseCase<TaskEntity, TaskEntity> {
  SaveTaskUseCase({bool isCreate = true, super.eventHub})
      : super(
          commandType: isCreate ? BlocxCommandType.create : BlocxCommandType.update,
        );

  @override
  Future<BlocxUseCaseResult<TaskEntity>> perform(TaskEntity input) async {
    return success(input);
  }
}

// 3. Delete UseCase (Input is TaskEntity, Output is bool -> auto-resolved by default,
//    or override resolveCommandEntities when Input is an ID/DTO)
class DeleteTaskUseCase extends BlocxBaseUseCase<TaskEntity, bool> {
  DeleteTaskUseCase({super.eventHub})
      : super(commandType: BlocxCommandType.delete);

  @override
  Future<BlocxUseCaseResult<bool>> perform(TaskEntity input) async {
    return success(true);
  }
}
```

### Blueprint B: Full-Featured `BlocxCollectionBloc`

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

class TasksCollectionBloc extends BlocxCollectionBloc<TaskEntity, void>
    with
        BlocxCollectionInfiniteMixin<TaskEntity, void>,
        BlocxCollectionRefreshableMixin<TaskEntity, void>,
        BlocxCollectionSearchableMixin<TaskEntity, void>,
        BlocxCollectionSelectableMixin<TaskEntity, void>,
        BlocxCollectionDeletableMixin<TaskEntity, void>,
        BlocxCollectionSyncStreamMixin<TaskEntity, void> {
  final LoadTasksUseCase loadTasksUseCase;
  final BlocxSearchUseCase<BlocxSearchInput, TaskEntity> searchTasksUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;

  @override
  final BlocxEventHub eventHub;

  TasksCollectionBloc({
    required this.loadTasksUseCase,
    required this.searchTasksUseCase,
    required this.deleteTaskUseCase,
    required this.eventHub,
  }) : super();

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TaskEntity>? get paginationTask {
    return BlocxPaginatedUseCaseTask<BlocxPaginatedInput, TaskEntity>(
      useCase: loadTasksUseCase,
      inputBuilder: (offset, limit) => BlocxPaginatedInput(offset: offset, limit: limit),
    );
  }

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, TaskEntity>? get searchUseCaseTask {
    return BlocxPaginatedUseCaseTask<BlocxSearchInput, TaskEntity>(
      useCase: searchTasksUseCase,
      inputBuilder: (offset, limit) => BlocxSearchInput(
        searchText: searchText,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  BlocxUseCaseTask<Object?, bool>? deleteItemTask(TaskEntity item) {
    return BlocxUseCaseTask<TaskEntity, bool>(
      useCase: deleteTaskUseCase,
      inputBuilder: () => item,
    );
  }

  @override
  bool shouldSyncEntity(TaskEntity entity, BlocxCommandType command) => true;
}
```

### Blueprint C: Validated Edit `BlocxFormBloc` with Live Stream Sync

```dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';

enum TaskFormField { title }

class TaskFormEntity extends BlocxBaseFormEntity<TaskFormEntity, TaskFormField> {
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

class TaskFormValidator extends BlocxFormValidator<TaskFormEntity, TaskFormField> {
  @override
  List<TaskFormField> formKeys() => TaskFormField.values;

  @override
  List<BlocxFieldValidator<TaskFormEntity, TaskFormField, dynamic>> getValidatorsByKey(
    TaskFormEntity formData,
    TaskFormField key,
  ) => switch (key) {
    TaskFormField.title => [
      BlocxStringRequiredValidator(),
      const BlocxStringMinLengthValidator(3),
    ],
  };
}

class TaskFormBloc extends BlocxFormBloc<TaskFormEntity, TaskEntity, TaskFormField>
    with
        BlocxFormValidationMixin<TaskFormEntity, TaskEntity, TaskFormField>,
        BlocxFormSyncStreamMixin<TaskFormEntity, TaskEntity, TaskFormField, TaskEntity> {
  final SaveTaskUseCase saveTaskUseCase;

  @override
  final BlocxEventHub eventHub;

  @override
  final BlocxFormValidator<TaskFormEntity, TaskFormField> validator = TaskFormValidator();

  TaskFormBloc({
    required this.saveTaskUseCase,
    required this.eventHub,
  }) : super(const TaskFormEntity());

  @override
  List<TaskFormField> get formKeysList => TaskFormField.values;

  @override
  FormValidationMode get formValidationMode => FormValidationMode.onUserInteraction;

  @override
  FutureOr<TaskFormEntity> applyPayloadToFormData(TaskEntity payload) {
    return formData.copyWith(id: payload.id, title: payload.title);
  }

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

  @override
  bool get popOnEntityDeleted => true;

  @override
  FutureOr<TaskFormEntity?> mapSyncedEntityToFormData(
    TaskEntity entity,
    BlocxCommandType command,
  ) {
    return formData.copyWith(id: entity.id, title: entity.title);
  }
}
```

---

## 4. Reference Manuals (Progressive Disclosure)

Consult the appropriate reference guide in `./references/` when implementing specific features:

1. **[`references/use_cases_and_event_hub.md`](./references/use_cases_and_event_hub.md)**
   - `BlocxBaseEntity` equality & extensions
   - `BlocxBaseUseCase` (`perform(input)` vs `execute(input)`, `success(data)`, `failureResult`, `handleError`), `BlocxUseCaseResult` (`when(onSuccess: ..., onFailure: ...)`, `dataOrThrow`)
   - `BlocxPaginatedUseCase`, `BlocxPaginatedInput`, `BlocxPage({required items, required offset, required limit})`, `BlocxSearchUseCase`, `BlocxSearchInput`
   - `BlocxUseCaseTask` and `BlocxPaginatedUseCaseTask`
   - `BlocxEventHub`, `BlocxSimpleEventHub`, `BlocxCommandType` (`create`, `read`, `update`, `delete`), single vs multi-command UseCases, `resolveCommandEntities`, `shouldBroadcastCommandResult`, and listener-only `BlocxEventHubMixin`
2. **[`references/collection_bloc.md`](./references/collection_bloc.md)**
   - `BlocxCollectionBloc<Entity, Payload>` & `BlocxCollectionCoreMixin` methods (`insertToList`, `modifyListBeforeInsert`, `doAfterInsert`, `replaceList`, `sortList`, `additionalInfo`)
   - All core events (`BlocxCollectionEventLoadInitialPage`, `BlocxCollectionEventAddItem`, `BlocxCollectionEventUpdateItem`, `BlocxCollectionEventReplaceList`, `BlocxCollectionEventRemoveFromList`)
   - All states (`BlocxCollectionStateLoading`, `BlocxCollectionStateLoaded`, `BlocxCollectionStateError`, `BlocxCollectionStateScrollToItem`, `BlocxCollectionStateSelectionChanged`) and `ListStateExtensions`
   - Complete API & event reference for all 10 collection mixins (`Infinite`, `Refreshable`, `Searchable`, `Selectable`, `Deletable`, `Highlightable`, `Expandable`, `Scrollable`, `Filter`, `SyncStream`)
3. **[`references/form_bloc.md`](./references/form_bloc.md)**
   - `BlocxBaseFormEntity<F, E>`, debug assertion in `updateByKeySafe`, and `getFormattedValueByKey`
   - `BlocxFormBloc<F, P, E>`, `BlocxFormCoreMixin`, `BlocxFormErrorsMixin` (persistent & timed field errors)
   - All form events (`BlocxFormEventInit`, `BlocxFormEventUpdateData`, `BlocxFormEventSubmit`, `BlocxFormEventUpdateFormData`, `BlocxFormEventSyncFormData`, error events) and states (`Initial`, `Loaded`, `ApplyInitialDataToForm`, `SubmittingForm`, `FormSubmitted`, `FormUpdated`)
   - `BlocxFormValidationMixin`, `FormValidationMode`, `BlocxFormValidator`, and the complete constructor table of all 35+ built-in field validators
   - All optional form mixins (`BlocxUniqueFieldValidatorMixin`, `BlocxFormPrefetchMixin`, `BlocxFormSteppedMixin`, `BlocxFormSyncStreamMixin`)
4. **[`references/error_handling_and_localization.md`](./references/error_handling_and_localization.md)**
   - `BlocxBaseBloc` helpers, `ErrorDisplayPolicy` (`snackBar` vs `page`), `ScreenManagerCubit` & `ScreenManagerCubitState`s
   - `BlocxErrorTranslator`, `ReadableError`, `BlocXErrorCode`
   - Customizing `BlocXLocalizations`
   - Pure-Dart unit testing patterns for UseCases, Collection BLoCs, Form BLoCs, and EventHub streams
