import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';

mixin ExpandableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  Set<String> expandedItemIds = {};

  void initExpandable() {
    on<ListEventExpandItem<T>>(expandItem);
    on<ListEventCollapseItem<T>>(collapseItem);
  }

  FutureOr<void> expandItem(ListEventExpandItem<T> event, Emitter<ListState<T>> emit) {
    expandedItemIds.add(event.item.identifier);
    emitState(emit);
  }

  FutureOr<void> collapseItem(ListEventCollapseItem<T> event, Emitter<ListState<T>> emit) {
    expandedItemIds.remove(event.item.identifier);
    emitState(emit);
  }
}
