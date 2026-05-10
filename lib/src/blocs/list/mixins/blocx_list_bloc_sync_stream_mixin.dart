import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart'
    show
        BlocxListEvent,
        BlocxListState,
        BlocxListEventAddItem,
        BlocxListEventUpdateItem,
        BlocxListEventRemoveItemById;

mixin BlocxListBlocSyncStreamMixin<T extends BlocxBaseEntity, P>
    on BaseBloc<BlocxListEvent<T>, BlocxListState<T>> {
  StreamSubscription<T>? _createSub;
  StreamSubscription<T>? _updateSub;
  StreamSubscription<String>? _deleteSub;
  initStreams() {
    _createSub = itemCreationStream?.listen((T value) {
      int index = getInsertIndexForItem(value);
      add(BlocxListEventAddItem(item: value, index: index));
    });

    _updateSub = itemUpdateStream?.listen((T value) {
      add(BlocxListEventUpdateItem(item: value));
    });

    _deleteSub = itemDeleteStream?.listen((String id) {
      add(BlocxListEventRemoveItemById(identifier: id));
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
