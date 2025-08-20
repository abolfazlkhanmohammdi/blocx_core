import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/models/list_entity.dart';

abstract class HighlightableListBlocContract<T extends ListEntity<T>> {
  FutureOr<void> highlightItem(ListEventHighlightItem<T> event, Emitter<ListState<T>> emit);
  FutureOr<void> clearHighlightedItem(ListEventClearHighlightedItem<T> event, Emitter<ListState<T>> emit);
  Duration get highlightDuration;
  bool get autoClearHighlight => true;
  void initHighlightMixin();
}
