import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart'
    show
        BlocxCollectionBloc,
        BlocxCollectionEventAddItem,
        BlocxCollectionEventDeselectMultipleItems,
        BlocxCollectionEventRemoveFromList,
        BlocxCollectionEventUpdateItem;
import 'package:meta/meta.dart';

/// Synchronizes a [BlocxCollectionBloc] with entity command events emitted on
/// [eventHub] (or optional custom streams).
///
/// Automatically subscribes during bloc initialization and cancels all
/// subscriptions when the bloc is closed.
///
/// ## Usage
///
/// ```dart
/// class OrdersBloc extends BlocxCollectionBloc<Order, void>
///     with BlocxCollectionSyncStreamMixin<Order, void> {
///   @override
///   final BlocxEventHub eventHub;
///
///   OrdersBloc(this.eventHub) : super();
///
///   @override
///   List<BlocxCommandType> get listenedCommands => const [
///     BlocxCommandType.create,
///     BlocxCommandType.update,
///     BlocxCommandType.delete,
///   ];
/// }
/// ```
mixin BlocxCollectionSyncStreamMixin<T extends BlocxBaseEntity, P>
    on BlocxCollectionBloc<T, P> {
  StreamSubscription<BlocxEntityEvent<T>>? _entityEventSub;
  StreamSubscription<T>? _createSub;
  StreamSubscription<T>? _updateSub;
  StreamSubscription<String>? _deleteSub;

  /// The [BlocxEventHub] this collection bloc listens to for entity commands.
  BlocxEventHub? get eventHub => null;

  /// The command types this collection bloc listens and reacts to.
  ///
  /// Defaults to all CRUD commands: `create`, `read`, `update`, and `delete`.
  List<BlocxCommandType> get listenedCommands => const <BlocxCommandType>[
    BlocxCommandType.create,
    BlocxCommandType.read,
    BlocxCommandType.update,
    BlocxCommandType.delete,
  ];

  /// Filter hook to decide whether an incoming [entity] for [command] belongs
  /// to this collection instance (e.g., matching a parent ID in `payload` or
  /// active filter criteria).
  bool shouldSyncEntity(T entity, BlocxCommandType command) => true;

  /// Whether a `create` command should update an item if an item with the same
  /// `identifier` already exists in [list].
  bool get updateExistingOnCreate => false;

  /// Whether a `read` command should insert an item if it is not yet in [list].
  bool get insertMissingOnRead => false;

  @override
  bool initStreams() {
    final hub = eventHub;
    if (hub != null && listenedCommands.isNotEmpty) {
      _entityEventSub = hub
          .onEntity<T>(commands: listenedCommands)
          .listen(_handleEntityCommandEvent);
    }

    _createSub = itemCreationStream?.listen((T value) {
      onCreateCommand(<T>[value]);
    });

    _updateSub = itemUpdateStream?.listen((T value) {
      onUpdateCommand(<T>[value]);
    });

    _deleteSub = itemDeleteStream?.listen((String id) {
      final index = list.indexWhere((e) => e.identifier == id);
      if (index != -1) {
        onDeleteCommand(<T>[list[index]]);
      }
    });

    return true;
  }

  void _handleEntityCommandEvent(BlocxEntityEvent<T> event) {
    if (isClosed) return;

    final relevant = event.entities
        .where((item) => shouldSyncEntity(item, event.command))
        .toList();
    if (relevant.isEmpty) return;

    switch (event.command) {
      case BlocxCommandType.create:
        onCreateCommand(relevant);
      case BlocxCommandType.read:
        onReadCommand(relevant);
      case BlocxCommandType.update:
        onUpdateCommand(relevant);
      case BlocxCommandType.delete:
        onDeleteCommand(relevant);
    }
  }

  /// Handles incoming `create` command entities.
  @protected
  void onCreateCommand(List<T> items) {
    for (final item in items) {
      final exists = list.any((e) => e.identifier == item.identifier);
      if (!exists) {
        add(
          BlocxCollectionEventAddItem<T>(
            item: item,
            index: getInsertIndexForItem(item),
          ),
        );
      } else if (updateExistingOnCreate) {
        add(BlocxCollectionEventUpdateItem<T>(item: item));
      }
    }
  }

  /// Handles incoming `read` command entities.
  ///
  /// By default, updates any item already present in [list] with the freshly
  /// read entity, or inserts it when [insertMissingOnRead] is `true`.
  @protected
  void onReadCommand(List<T> items) {
    for (final item in items) {
      final exists = list.any((e) => e.identifier == item.identifier);
      if (exists) {
        add(BlocxCollectionEventUpdateItem<T>(item: item));
      } else if (insertMissingOnRead) {
        add(
          BlocxCollectionEventAddItem<T>(
            item: item,
            index: getInsertIndexForItem(item),
          ),
        );
      }
    }
  }

  /// Handles incoming `update` command entities.
  @protected
  void onUpdateCommand(List<T> items) {
    for (final item in items) {
      if (list.any((e) => e.identifier == item.identifier)) {
        add(BlocxCollectionEventUpdateItem<T>(item: item));
      }
    }
  }

  /// Handles incoming `delete` command entities.
  @protected
  void onDeleteCommand(List<T> items) {
    for (final item in items) {
      if (beingRemovedItemIds.contains(item.identifier)) continue;
      if (list.any((e) => e.identifier == item.identifier)) {
        if (isSelectable && selectedItemIds.contains(item.identifier)) {
          add(BlocxCollectionEventDeselectMultipleItems<T>(items: <T>[item]));
        }
        add(BlocxCollectionEventRemoveFromList<T>(item: item));
      }
    }
  }

  /// Optional standalone stream for item creation.
  Stream<T>? get itemCreationStream => null;

  /// Optional standalone stream for item deletion by identifier.
  Stream<String>? get itemDeleteStream => null;

  /// Optional standalone stream for item updates.
  Stream<T>? get itemUpdateStream => null;

  /// Returns the target insertion index for a newly created [value].
  ///
  /// Uses [sortComparator] if provided, or defaults to index 0.
  @override
  int getInsertIndexForItem(T value) {
    return super.getInsertIndexForItem(value);
  }

  /// Cancels all active stream subscriptions.
  void closeStreams() {
    _entityEventSub?.cancel();
    _createSub?.cancel();
    _updateSub?.cancel();
    _deleteSub?.cancel();
  }
}
