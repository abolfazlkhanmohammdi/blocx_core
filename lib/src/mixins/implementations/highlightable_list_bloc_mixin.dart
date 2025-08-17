import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/blocs/list/list_bloc.dart';
import 'package:blocx/src/core/list_entity_extensions.dart';
import 'package:blocx/src/core/models/list_entity.dart';
import 'package:blocx/src/mixins/contracts/highlightable_list_bloc_contract.dart';

mixin HighlightableListBlocMixin<T extends ListEntity<T>> on ListBloc<T>
    implements HighlightableListBlocContract<T> {
  @override
  Future<void> clearHighlightedItem(
    ListBlocEventClearHighlightedItem<T> event,
    Emitter<ListBlocState<T>> emit,
  ) async {
    await Future.delayed(highlightDuration);
    list.clearHighlightedItem(event.item);
    emitState(emit);
  }

  @override
  Duration get highlightDuration => Duration(seconds: 3);

  @override
  FutureOr<void> highlightItem(ListBlocEventHighlightItem<T> event, Emitter<ListBlocState<T>> emit) async {
    list.highlightItem(event.item);
    emitState(emit);
    if (!autoClearHighlight) return;
    add(ListBlocEventClearHighlightedItem(item: event.item));
  }

  @override
  bool get autoClearHighlight => true;
}
