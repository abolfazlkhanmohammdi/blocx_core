import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/core/list_entity_extensions.dart';

mixin ToIndexScrollableListBlocMixin<T extends BaseEntity, P> on ListBloc<T, P> {
  void initScrollable() {
    on<ListEventScrollToItem<T>>(scrollToItem);
  }

  FutureOr<void> scrollToItem(ListEventScrollToItem<T> event, Emitter<ListState<T>> emit) {
    var index = list.indexById(event.item);
    if(event.highlightItem){
      highlightItem(event.item);
    }
    emit(ListStateScrollToItem(item: event.item, index: index));
    emitState(emit);
  }

  void highlightItem(T item) {
    if(this is! HighlightableListBlocMixin<T,P>){
      throw
    }
  }
}
