import 'dart:async';

import 'package:blocx_core/blocx_core.dart';

mixin ListBlocSyncStreamMixin<T extends BaseEntity, P> on BaseBloc<ListEvent<T>, ListState<T>> {
  StreamSubscription<T>? _createSub;
  StreamSubscription<T>? _updateSub;
  StreamSubscription<String>? _deleteSub;
  initStreams() {
    _createSub = itemCreationStream?.listen((T value) {
      int index = getInsertIndexForItem(value);
      add(ListEventAddItem(item: value, index: index));
    });

    _updateSub = itemUpdateStream?.listen((T value) {
      add(ListEventUpdateItem(item: value));
    });

    _deleteSub = itemDeleteStream?.listen((String id) {
      add(ListEventRemoveItemById(identifier: id));
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
