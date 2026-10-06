import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart'
    show
        BlocxBaseFormEntity,
        BlocxFormBloc,
        BlocxFormEventSyncFormData,
        BlocxFormStateSubmittingForm;
import 'package:meta/meta.dart';

/// Synchronizes a [BlocxFormBloc] with entity command events emitted on
/// [eventHub].
///
/// Automatically subscribes during bloc initialization and cancels the
/// subscription when the bloc is closed.
///
/// ## Usage
///
/// ```dart
/// class EditUserFormBloc
///     extends BlocxFormBloc<UserFormEntity, User, UserFormField>
///     with BlocxFormSyncStreamMixin<UserFormEntity, User, UserFormField, User> {
///   @override
///   final BlocxEventHub eventHub;
///
///   EditUserFormBloc(this.eventHub) : super(const UserFormEntity());
///
///   @override
///   FutureOr<UserFormEntity?> mapSyncedEntityToFormData(
///     User entity,
///     BlocxCommandType command,
///   ) {
///     return UserFormEntity.fromDomain(entity);
///   }
/// }
/// ```
mixin BlocxFormSyncStreamMixin<F extends BlocxBaseFormEntity<F, E>, P,
    E extends Enum, Entity extends BlocxBaseEntity> on BlocxFormBloc<F, P, E> {
  StreamSubscription<BlocxEntityEvent<Entity>>? _entityEventSub;

  /// The [BlocxEventHub] this form bloc listens to for entity commands.
  BlocxEventHub get eventHub;

  /// The command types this form bloc listens and reacts to.
  ///
  /// Defaults to `create`, `read`, `update`, and `delete`.
  List<BlocxCommandType> get listenedCommands => const <BlocxCommandType>[
        BlocxCommandType.create,
        BlocxCommandType.read,
        BlocxCommandType.update,
        BlocxCommandType.delete,
      ];

  /// Filter hook to decide whether an incoming [entity] for [command] applies
  /// to this form instance.
  ///
  /// By default, matches when `formData.identifier` is empty or equals
  /// `entity.identifier`.
  bool shouldSyncEntity(Entity entity, BlocxCommandType command) {
    if (formData.identifier.isEmpty) return true;
    return entity.identifier == formData.identifier;
  }

  /// Whether incoming stream events should be ignored while the form is
  /// actively executing its own submission.
  bool get ignoreEventsWhileSubmitting => true;

  /// Whether the form should automatically emit a back-navigation [pop] signal
  /// when the watched entity is deleted externally.
  bool get popOnEntityDeleted => true;

  /// Whether synced form data should also refresh managed UI text controllers.
  bool get applySyncedDataToControllers => true;

  /// Whether synced form data should trigger form validation.
  bool get validateOnEntitySync => false;

  @override
  bool initStreams() {
    if (listenedCommands.isNotEmpty) {
      _entityEventSub = eventHub
          .onEntity<Entity>(commands: listenedCommands)
          .listen(_handleEntityCommandEvent);
    }
    return true;
  }

  Future<void> _handleEntityCommandEvent(
    BlocxEntityEvent<Entity> event,
  ) async {
    if (isClosed) return;
    if (ignoreEventsWhileSubmitting &&
        state is BlocxFormStateSubmittingForm<F, E>) {
      return;
    }

    final relevant = event.entities
        .where((item) => shouldSyncEntity(item, event.command))
        .toList();
    if (relevant.isEmpty) return;

    switch (event.command) {
      case BlocxCommandType.create:
        await onCreateCommand(relevant);
      case BlocxCommandType.read:
        await onReadCommand(relevant);
      case BlocxCommandType.update:
        await onUpdateCommand(relevant);
      case BlocxCommandType.delete:
        await onDeleteCommand(relevant);
    }
  }

  /// Handles incoming `create` command entities.
  @protected
  FutureOr<void> onCreateCommand(List<Entity> items) async {
    await _syncFromEntity(items.last, BlocxCommandType.create);
  }

  /// Handles incoming `read` command entities.
  @protected
  FutureOr<void> onReadCommand(List<Entity> items) async {
    await _syncFromEntity(items.last, BlocxCommandType.read);
  }

  /// Handles incoming `update` command entities.
  @protected
  FutureOr<void> onUpdateCommand(List<Entity> items) async {
    await _syncFromEntity(items.last, BlocxCommandType.update);
  }

  /// Handles incoming `delete` command entities.
  @protected
  FutureOr<void> onDeleteCommand(List<Entity> items) {
    onWatchedEntityDeleted(items.last);
  }

  Future<void> _syncFromEntity(
    Entity entity,
    BlocxCommandType command,
  ) async {
    final updatedFormData = await mapSyncedEntityToFormData(entity, command);
    if (updatedFormData == null || isClosed) return;

    add(
      BlocxFormEventSyncFormData<F>(
        formData: updatedFormData,
        applyToControllers: applySyncedDataToControllers,
        validate: validateOnEntitySync,
      ),
    );
  }

  /// Converts a synced [Entity] into updated form data [F].
  ///
  /// If [Entity] is already of type [F], returns `entity as F` by default.
  /// Otherwise, override this method to map the domain [Entity] into [F].
  @protected
  FutureOr<F?> mapSyncedEntityToFormData(
    Entity entity,
    BlocxCommandType command,
  ) {
    if (entity is F) return entity as F;
    return null;
  }

  /// Called when an entity matching [shouldSyncEntity] is deleted.
  ///
  /// Calls [pop] by default when [popOnEntityDeleted] is `true`.
  @protected
  void onWatchedEntityDeleted(Entity entity) {
    if (popOnEntityDeleted) {
      pop();
    }
  }

  /// Cancels active stream subscriptions.
  @override
  void closeStreams() {
    _entityEventSub?.cancel();
  }
}
