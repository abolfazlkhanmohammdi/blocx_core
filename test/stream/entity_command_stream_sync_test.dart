import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:test/test.dart';

class NoteEntity extends BlocxBaseEntity {
  final String id;
  final String title;
  final int userId;

  const NoteEntity({required this.id, required this.title, this.userId = 1});

  @override
  String get identifier => id;
}

class OtherEntity extends BlocxBaseEntity {
  final String id;
  const OtherEntity(this.id);

  @override
  String get identifier => id;
}

class CreateNoteUseCase extends BlocxBaseUseCase<NoteEntity, NoteEntity> {
  CreateNoteUseCase(BlocxEventHub eventHub)
    : super(eventHub: eventHub, commandType: BlocxCommandType.create);

  @override
  Future<BlocxUseCaseResult<NoteEntity>> perform(NoteEntity input) async {
    return success(input);
  }
}

class UpdateNoteUseCase extends BlocxBaseUseCase<NoteEntity, NoteEntity> {
  UpdateNoteUseCase(BlocxEventHub eventHub)
    : super(eventHub: eventHub, commandType: BlocxCommandType.update);

  @override
  Future<BlocxUseCaseResult<NoteEntity>> perform(NoteEntity input) async {
    return success(input);
  }
}

class ReadNoteUseCase extends BlocxBaseUseCase<NoteEntity, NoteEntity> {
  ReadNoteUseCase(BlocxEventHub eventHub)
    : super(eventHub: eventHub, commandType: BlocxCommandType.read);

  @override
  Future<BlocxUseCaseResult<NoteEntity>> perform(NoteEntity input) async {
    return success(input);
  }
}

class DeleteNoteUseCase extends BlocxBaseUseCase<NoteEntity, bool> {
  final bool shouldSucceed;
  final bool shouldThrow;

  DeleteNoteUseCase(
    BlocxEventHub eventHub, {
    this.shouldSucceed = true,
    this.shouldThrow = false,
  }) : super(eventHub: eventHub, commandType: BlocxCommandType.delete);

  @override
  Future<BlocxUseCaseResult<bool>> perform(NoteEntity input) async {
    if (shouldThrow) throw Exception('Delete failed');
    return success(shouldSucceed);
  }
}

class BulkDeleteNotesUseCase extends BlocxBaseUseCase<List<NoteEntity>, bool> {
  BulkDeleteNotesUseCase(BlocxEventHub eventHub)
    : super(eventHub: eventHub, commandType: BlocxCommandType.delete);

  @override
  Future<BlocxUseCaseResult<bool>> perform(List<NoteEntity> input) async {
    return success(true);
  }
}

class MultiCommandUseCase extends BlocxBaseUseCase<NoteEntity, NoteEntity> {
  MultiCommandUseCase(BlocxEventHub eventHub)
    : super(
        eventHub: eventHub,
        commandTypes: const [BlocxCommandType.read, BlocxCommandType.update],
      );

  @override
  Future<BlocxUseCaseResult<NoteEntity>> perform(NoteEntity input) async {
    return success(input);
  }
}

class FetchNotesPageUseCase
    extends BlocxPaginatedUseCase<BlocxPaginatedInput, NoteEntity> {
  const FetchNotesPageUseCase({super.eventHub, super.commandType});

  @override
  Future<BlocxUseCaseResult<BlocxPage<NoteEntity>>> perform(
    BlocxPaginatedInput input,
  ) async {
    final items = List.generate(
      3,
      (i) => NoteEntity(id: '${i + 1}', title: 'Note ${i + 1}'),
    );
    return successResult(items: items, input: input);
  }
}

class SyncedNotesCollectionBloc extends BlocxCollectionBloc<NoteEntity, int?>
    with
        BlocxCollectionSelectableMixin<NoteEntity, int?>,
        BlocxCollectionSyncStreamMixin<NoteEntity, int?> {
  @override
  final BlocxEventHub eventHub;
  final List<BlocxCommandType>? customCommands;
  final bool customUpdateExistingOnCreate;
  final bool customInsertMissingOnRead;

  SyncedNotesCollectionBloc(
    this.eventHub, {
    this.customCommands,
    this.customUpdateExistingOnCreate = false,
    this.customInsertMissingOnRead = false,
  }) : super();

  @override
  List<BlocxCommandType> get listenedCommands =>
      customCommands ?? super.listenedCommands;

  @override
  bool get updateExistingOnCreate => customUpdateExistingOnCreate;

  @override
  bool get insertMissingOnRead => customInsertMissingOnRead;

  @override
  bool shouldSyncEntity(NoteEntity entity, BlocxCommandType command) {
    if (payload != null) {
      return entity.userId == payload;
    }
    return true;
  }

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, NoteEntity>?
  get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: const FetchNotesPageUseCase(),
    inputBuilder: (offset, limit) =>
        BlocxPaginatedInput(offset: offset, limit: limit),
  );
}

class SortedNotesCollectionBloc extends BlocxCollectionBloc<NoteEntity, int?>
    with BlocxCollectionSyncStreamMixin<NoteEntity, int?> {
  @override
  final BlocxEventHub eventHub;

  SortedNotesCollectionBloc(this.eventHub) : super();

  @override
  Comparator<NoteEntity>? get sortComparator =>
      (a, b) => a.title.compareTo(b.title);
}

enum NoteFormField { title }

class NoteFormData extends BlocxBaseFormEntity<NoteFormData, NoteFormField> {
  final String id;
  final String title;

  const NoteFormData({required this.id, required this.title});

  @override
  String get identifier => id;

  @override
  NoteFormData updateByKey(NoteFormField key, dynamic value) {
    return switch (key) {
      NoteFormField.title => NoteFormData(id: id, title: value as String),
    };
  }

  @override
  dynamic getValueByKey(NoteFormField key) {
    return switch (key) {
      NoteFormField.title => title,
    };
  }
}

class SlowSubmitUseCase extends BlocxBaseUseCase<NoteFormData, NoteEntity> {
  final Completer<void>? completer;

  SlowSubmitUseCase({this.completer});

  @override
  Future<BlocxUseCaseResult<NoteEntity>> perform(NoteFormData input) async {
    if (completer != null) {
      await completer!.future;
    }
    return success(NoteEntity(id: input.id, title: input.title));
  }
}

class SyncedNoteFormBloc
    extends BlocxFormBloc<NoteFormData, NoteEntity, NoteFormField>
    with
        BlocxFormSyncStreamMixin<
          NoteFormData,
          NoteEntity,
          NoteFormField,
          NoteEntity
        > {
  @override
  final BlocxEventHub eventHub;
  final Completer<void>? submitCompleter;

  SyncedNoteFormBloc(super.initialData, this.eventHub, {this.submitCompleter});

  @override
  NoteFormData? mapSyncedEntityToFormData(
    NoteEntity entity,
    BlocxCommandType command,
  ) {
    return NoteFormData(id: entity.id, title: entity.title);
  }

  @override
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask => BlocxUseCaseTask(
    useCase: SlowSubmitUseCase(completer: submitCompleter),
    inputBuilder: () => formData,
  );
}

void main() {
  group('UseCase Command & BlocxEventHub', () {
    late BlocxSimpleEventHub eventHub;

    setUp(() {
      eventHub = BlocxSimpleEventHub();
    });

    tearDown(() {
      eventHub.dispose();
    });

    test('UseCase broadcasts typed entity command events on success', () async {
      final receivedEvents = <BlocxEntityEvent<NoteEntity>>[];
      final sub = eventHub.onEntity<NoteEntity>().listen(receivedEvents.add);

      final createUseCase = CreateNoteUseCase(eventHub);
      final updateUseCase = UpdateNoteUseCase(eventHub);
      final readUseCase = ReadNoteUseCase(eventHub);
      final deleteUseCase = DeleteNoteUseCase(eventHub);

      const note = NoteEntity(id: '10', title: 'Created');
      await createUseCase.execute(note);
      await updateUseCase.execute(const NoteEntity(id: '10', title: 'Updated'));
      await readUseCase.execute(const NoteEntity(id: '10', title: 'Read'));
      await deleteUseCase.execute(note);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(receivedEvents.length, equals(4));
      expect(receivedEvents[0].command, equals(BlocxCommandType.create));
      expect(receivedEvents[0].entity.title, equals('Created'));
      expect(receivedEvents[1].command, equals(BlocxCommandType.update));
      expect(receivedEvents[1].entity.title, equals('Updated'));
      expect(receivedEvents[2].command, equals(BlocxCommandType.read));
      expect(receivedEvents[2].entity.title, equals('Read'));
      expect(receivedEvents[3].command, equals(BlocxCommandType.delete));
      expect(receivedEvents[3].entity.id, equals('10'));

      await sub.cancel();
    });

    test(
      'UseCase with multiple commandTypes emits an event for each command',
      () async {
        final receivedEvents = <BlocxEntityEvent<NoteEntity>>[];
        final sub = eventHub.onEntity<NoteEntity>().listen(receivedEvents.add);

        final multiUseCase = MultiCommandUseCase(eventHub);
        await multiUseCase.execute(const NoteEntity(id: '7', title: 'Multi'));

        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(receivedEvents.length, equals(2));
        expect(
          receivedEvents.map((e) => e.command).toList(),
          equals([BlocxCommandType.read, BlocxCommandType.update]),
        );

        await sub.cancel();
      },
    );

    test(
      'Paginated and bulk UseCases resolve entity lists automatically',
      () async {
        final receivedEvents = <BlocxEntityEvent<NoteEntity>>[];
        final sub = eventHub.onEntity<NoteEntity>().listen(receivedEvents.add);

        final paginatedReadUseCase = FetchNotesPageUseCase(
          eventHub: eventHub,
          commandType: BlocxCommandType.read,
        );
        await paginatedReadUseCase.execute(
          const BlocxPaginatedInput(limit: 3, offset: 0),
        );

        final bulkDeleteUseCase = BulkDeleteNotesUseCase(eventHub);
        await bulkDeleteUseCase.execute(const [
          NoteEntity(id: '1', title: 'Note 1'),
          NoteEntity(id: '2', title: 'Note 2'),
        ]);

        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(receivedEvents.length, equals(2));
        expect(receivedEvents[0].command, equals(BlocxCommandType.read));
        expect(receivedEvents[0].entities.length, equals(3));
        expect(receivedEvents[1].command, equals(BlocxCommandType.delete));
        expect(receivedEvents[1].entities.length, equals(2));

        await sub.cancel();
      },
    );

    test(
      'DeleteUseCase returning false or throwing exception does not broadcast',
      () async {
        final receivedEvents = <BlocxEntityEvent<NoteEntity>>[];
        final sub = eventHub.onEntity<NoteEntity>().listen(receivedEvents.add);

        final falseDelete = DeleteNoteUseCase(eventHub, shouldSucceed: false);
        final throwingDelete = DeleteNoteUseCase(eventHub, shouldThrow: true);

        await falseDelete.execute(const NoteEntity(id: '1', title: 'Note 1'));
        await throwingDelete.execute(
          const NoteEntity(id: '1', title: 'Note 1'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(receivedEvents, isEmpty);

        await sub.cancel();
      },
    );

    test('onEntity filters by entity type and command list', () async {
      final received = <BlocxEntityEvent<NoteEntity>>[];
      final sub = eventHub
          .onEntity<NoteEntity>(commands: [BlocxCommandType.update])
          .listen(received.add);

      eventHub.emitEntity(const OtherEntity('99'), BlocxCommandType.update);
      eventHub.emitEntity(
        const NoteEntity(id: '1', title: 'Created'),
        BlocxCommandType.create,
      );
      eventHub.emitEntity(
        const NoteEntity(id: '1', title: 'Updated'),
        BlocxCommandType.update,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(received.length, equals(1));
      expect(received.first.command, equals(BlocxCommandType.update));
      expect(received.first.entity.title, equals('Updated'));

      await sub.cancel();
    });
  });

  group('BlocxCollectionSyncStreamMixin', () {
    late BlocxSimpleEventHub eventHub;
    late SyncedNotesCollectionBloc bloc;

    setUp(() async {
      eventHub = BlocxSimpleEventHub();
      bloc = SyncedNotesCollectionBloc(eventHub);
      bloc.add(BlocxCollectionEventLoadInitialPage(payload: 1));
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });

    tearDown(() async {
      await bloc.close();
      eventHub.dispose();
    });

    test(
      'syncs create, update, read, and delete commands from UseCases',
      () async {
        expect(bloc.list.length, equals(3));

        // 1. Create command inserts new item at index 0 and avoids duplicates
        final createUseCase = CreateNoteUseCase(eventHub);
        await createUseCase.execute(
          const NoteEntity(id: '100', title: 'Created via UseCase', userId: 1),
        );
        await createUseCase.execute(
          const NoteEntity(id: '100', title: 'Duplicate Create', userId: 1),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(bloc.list.length, equals(4));
        expect(bloc.list.first.id, equals('100'));
        expect(bloc.list.first.title, equals('Created via UseCase'));

        // 2. Update command updates item in list
        final updateUseCase = UpdateNoteUseCase(eventHub);
        await updateUseCase.execute(
          const NoteEntity(id: '2', title: 'Note 2 Updated', userId: 1),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final note2 = bloc.list.firstWhere((e) => e.id == '2');
        expect(note2.title, equals('Note 2 Updated'));

        // 3. Read command refreshes existing item in list
        final readUseCase = ReadNoteUseCase(eventHub);
        await readUseCase.execute(
          const NoteEntity(id: '3', title: 'Note 3 Hydrated', userId: 1),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final note3 = bloc.list.firstWhere((e) => e.id == '3');
        expect(note3.title, equals('Note 3 Hydrated'));

        // 4. Select item 2, then Delete command removes and deselects it
        bloc.add(BlocxCollectionEventSelectItem(item: note2));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.selectedItemIds, contains('2'));

        final deleteUseCase = DeleteNoteUseCase(eventHub);
        await deleteUseCase.execute(note2);
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(bloc.list.any((e) => e.id == '2'), isFalse);
        expect(bloc.selectedItemIds, isNot(contains('2')));
      },
    );

    test('respects shouldSyncEntity filter and listenedCommands', () async {
      // Entity for different user (userId: 99 != payload: 1) should be ignored
      final createUseCase = CreateNoteUseCase(eventHub);
      await createUseCase.execute(
        const NoteEntity(id: '500', title: 'Other User Note', userId: 99),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(bloc.list.any((e) => e.id == '500'), isFalse);

      // Collection bloc listening only to delete should ignore create
      final deleteOnlyBloc = SyncedNotesCollectionBloc(
        eventHub,
        customCommands: const [BlocxCommandType.delete],
      );
      deleteOnlyBloc.add(BlocxCollectionEventLoadInitialPage(payload: 1));
      await Future<void>.delayed(const Duration(milliseconds: 40));

      await createUseCase.execute(
        const NoteEntity(id: '600', title: 'Ignored Create', userId: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(deleteOnlyBloc.list.any((e) => e.id == '600'), isFalse);

      final deleteUseCase = DeleteNoteUseCase(eventHub);
      await deleteUseCase.execute(
        const NoteEntity(id: '1', title: 'Note 1', userId: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(deleteOnlyBloc.list.any((e) => e.id == '1'), isFalse);
      await deleteOnlyBloc.close();
    });

    test(
      'supports updateExistingOnCreate and insertMissingOnRead flags',
      () async {
        final customBloc = SyncedNotesCollectionBloc(
          eventHub,
          customUpdateExistingOnCreate: true,
          customInsertMissingOnRead: true,
        );
        customBloc.add(BlocxCollectionEventLoadInitialPage(payload: 1));
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final createUseCase = CreateNoteUseCase(eventHub);
        await createUseCase.execute(
          const NoteEntity(id: '1', title: 'Updated via Create', userId: 1),
        );

        final readUseCase = ReadNoteUseCase(eventHub);
        await readUseCase.execute(
          const NoteEntity(id: '777', title: 'Inserted via Read', userId: 1),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(
          customBloc.list.firstWhere((e) => e.id == '1').title,
          equals('Updated via Create'),
        );
        expect(customBloc.list.any((e) => e.id == '777'), isTrue);

        await customBloc.close();
      },
    );

    test(
      'sortComparator inserts items at sorted position rather than index 0',
      () async {
        final sortedBloc = SortedNotesCollectionBloc(eventHub);
        await sortedBloc.insertToList(
          [
            const NoteEntity(id: '10', title: 'B Note'),
            const NoteEntity(id: '30', title: 'D Note'),
          ],
          false,
          DataInsertSource.init,
        );

        // Create Note with title 'A Note' -> should be inserted at index 0
        final createA = CreateNoteUseCase(eventHub);
        await createA.execute(const NoteEntity(id: '5', title: 'A Note'));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Create Note with title 'C Note' -> should be inserted between B and D
        final createC = CreateNoteUseCase(eventHub);
        await createC.execute(const NoteEntity(id: '20', title: 'C Note'));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Create Note with title 'E Note' -> should be inserted at end
        final createE = CreateNoteUseCase(eventHub);
        await createE.execute(const NoteEntity(id: '40', title: 'E Note'));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final titles = sortedBloc.state.list.map((n) => n.title).toList();
        expect(
          titles,
          equals(['A Note', 'B Note', 'C Note', 'D Note', 'E Note']),
        );
        await sortedBloc.close();
      },
    );
  });

  group('BlocxFormSyncStreamMixin', () {
    late BlocxSimpleEventHub eventHub;
    late SyncedNoteFormBloc formBloc;

    setUp(() {
      eventHub = BlocxSimpleEventHub();
      formBloc = SyncedNoteFormBloc(
        const NoteFormData(id: '1', title: 'Initial Title'),
        eventHub,
      );
    });

    tearDown(() async {
      await formBloc.close();
      eventHub.dispose();
    });

    test(
      'updates formData and emits controller sync state on update command',
      () async {
        final states = <BlocxFormState<NoteFormData, NoteFormField>>[];
        final sub = formBloc.stream.listen(states.add);

        final updateUseCase = UpdateNoteUseCase(eventHub);
        await updateUseCase.execute(
          const NoteEntity(id: '1', title: 'Externally Updated Title'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(formBloc.formData.title, equals('Externally Updated Title'));
        expect(
          states.any(
            (s) =>
                s
                    is BlocxFormStateApplyInitialDataToForm<
                      NoteFormData,
                      NoteFormField
                    >,
          ),
          isTrue,
        );

        await sub.cancel();
      },
    );

    test('ignores entity events for unrelated entity identifiers', () async {
      final updateUseCase = UpdateNoteUseCase(eventHub);
      await updateUseCase.execute(
        const NoteEntity(id: '999', title: 'Other Note Title'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(formBloc.formData.title, equals('Initial Title'));
    });

    test('ignores incoming events while form is actively submitting', () async {
      final completer = Completer<void>();
      final submittingFormBloc = SyncedNoteFormBloc(
        const NoteFormData(id: '1', title: 'Submitting Title'),
        eventHub,
        submitCompleter: completer,
      );

      submittingFormBloc.add(BlocxFormEventSubmit());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        submittingFormBloc.state,
        isA<BlocxFormStateSubmittingForm<NoteFormData, NoteFormField>>(),
      );

      final updateUseCase = UpdateNoteUseCase(eventHub);
      await updateUseCase.execute(
        const NoteEntity(id: '1', title: 'Concurrent External Update'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      completer.complete();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(submittingFormBloc.formData.title, equals('Submitting Title'));
      await submittingFormBloc.close();
    });

    test(
      'triggers pop on ScreenManagerCubit when watched entity is deleted',
      () async {
        final screenStates = <ScreenManagerCubitState>[];
        final sub = formBloc.screenManagerCubit.stream.listen(screenStates.add);

        final deleteUseCase = DeleteNoteUseCase(eventHub);
        await deleteUseCase.execute(
          const NoteEntity(id: '1', title: 'Deleted Note'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(
          screenStates.any((s) => s is ScreenManagerCubitStatePop),
          isTrue,
        );

        await sub.cancel();
      },
    );
  });
}
