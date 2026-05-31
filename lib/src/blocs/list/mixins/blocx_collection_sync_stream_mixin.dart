import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxCollectionEvent,
        BlocxCollectionState,
        BlocxCollectionEventAddItem,
        BlocxCollectionEventUpdateItem,
        BlocxCollectionEventRemoveItemById;

mixin BlocxCollectionSyncStreamMixin<T extends BlocxBaseEntity, P>
    on BaseBloc<BlocxCollectionEvent<T>, BlocxCollectionState<T>> {
  StreamSubscription<T>? _createSub;
  StreamSubscription<T>? _updateSub;
  StreamSubscription<String>? _deleteSub;
  initStreams() {
    _createSub = itemCreationStream?.listen((T value) {
      int index = getInsertIndexForItem(value);
      add(BlocxCollectionEventAddItem(item: value, index: index));
    });

    _updateSub = itemUpdateStream?.listen((T value) {
      add(BlocxCollectionEventUpdateItem(item: value));
    });

    _deleteSub = itemDeleteStream?.listen((String id) {
      add(BlocxCollectionEventRemoveItemById(identifier: id));
    });
  }

  Stream<T>? get itemCreationStream => null;
  Stream<String>? get itemDeleteStream => null;
  Stream<T>? get itemUpdateStream => null;

  int getInsertIndexForItem(T value) {
    return 0;
  }

  closeStreams() {
    _createSub?.cancel();
    _updateSub?.cancel();
    _deleteSub?.cancel();
  }
}
