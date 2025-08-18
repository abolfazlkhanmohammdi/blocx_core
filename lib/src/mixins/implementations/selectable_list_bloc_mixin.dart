import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/blocs/list/list_bloc.dart';
import 'package:blocx/src/core/list_entity_extensions.dart';
import 'package:blocx/src/core/models/list_entity.dart';
import 'package:blocx/src/mixins/contracts/selectable_list_bloc_contract.dart';

mixin SelectableListBlocMixin<T extends ListEntity<T>> on ListBloc<T> implements SelectableBlocContract<T> {
  @override
  FutureOr<void> deSelectItem(ListBlocEventSelectItem<T> event, Emitter<ListBlocState<T>> emit) {
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
}
