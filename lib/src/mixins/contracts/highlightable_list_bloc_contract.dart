import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/blocs/list/list_bloc.dart';
import 'package:blocx/src/core/models/list_entity.dart';

abstract class HighlightableListBlocContract<T extends ListEntity<T>> {
  FutureOr<void> highlightItem(ListBlocEventHighlightItem<T> event, Emitter<ListBlocState<T>> emit);
  FutureOr<void> clearHighlightedItem(
    ListBlocEventClearHighlightedItem<T> event,
    Emitter<ListBlocState<T>> emit,
  );
  Duration get highlightDuration;
  bool get autoClearHighlight => true;
}
