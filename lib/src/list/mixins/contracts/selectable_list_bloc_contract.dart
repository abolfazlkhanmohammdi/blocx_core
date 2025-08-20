import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/models/list_entity.dart';

abstract interface class SelectableBlocContract<T extends ListEntity<T>> {
  FutureOr<void> selectItem(ListEventSelectItem<T> event, Emitter<ListState<T>> emit);
  FutureOr<void> deselectItem(ListEventDeselectItem<T> event, Emitter<ListState<T>> emit);
  bool get isSingleSelect;
  void initSelectionMixin();
  BaseUseCase<bool>? get selectItemUseCase;
  BaseUseCase<bool>? get deselectItemUseCase;
}
