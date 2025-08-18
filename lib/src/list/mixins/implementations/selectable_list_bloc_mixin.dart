import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/core/list_entity_extensions.dart';
import 'package:blocx/src/list/mixins/contracts/selectable_list_bloc_contract.dart';
import 'package:blocx/src/list/models/list_entity.dart';

mixin SelectableListBlocMixin<T extends ListEntity<T>, P> on ListBloc<T, P>
    implements SelectableBlocContract<T> {
  @override
  FutureOr<void> deSelectItem(ListBlocEventDeSelectItem<T> event, Emitter<ListBlocState<T>> emit) {
    list.deselectItem(event.item);
    emitState(emit);
  }

  @override
  FutureOr<void> selectItem(ListBlocEventSelectItem<T> event, Emitter<ListBlocState<T>> emit) {
    if (isSingleSelect) list.clearSelection();
    list.selectItem(event.item);
    emitState(emit);
  }

  @override
  bool get isSingleSelect => true;

  @override
  void initSelectionMixin() {
    on<ListBlocEventSelectItem<T>>(selectItem);
    on<ListBlocEventDeSelectItem<T>>(deSelectItem);
  }
}
