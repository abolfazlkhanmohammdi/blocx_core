import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/core/list_entity_extensions.dart';
import 'package:blocx/src/list/mixins/contracts/highlightable_list_bloc_contract.dart';
import 'package:blocx/src/list/models/list_entity.dart';

mixin HighlightableListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
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
  Duration get highlightDuration => const Duration(seconds: 3);

  @override
  FutureOr<void> highlightItem(ListBlocEventHighlightItem<T> event, Emitter<ListBlocState<T>> emit) async {
    list.highlightItem(event.item);
    emitState(emit);
    if (!autoClearHighlight) return;
    add(ListBlocEventClearHighlightedItem(item: event.item));
  }

  @override
  bool get autoClearHighlight => true;

  @override
  void initHighlightMixin() {
    on<ListBlocEventHighlightItem<T>>(highlightItem);
    on<ListBlocEventClearHighlightedItem<T>>(clearHighlightedItem);
  }
}
