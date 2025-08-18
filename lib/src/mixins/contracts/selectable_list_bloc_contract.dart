import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/blocs/list/list_bloc.dart';
import 'package:blocx/src/core/models/list_entity.dart';

abstract interface class SelectableBlocContract<T extends ListEntity<T>> {
  FutureOr<void> selectItem(ListBlocEventSelectItem<T> event, Emitter<ListBlocState<T>> emit);
  FutureOr<void> deSelectItem(ListBlocEventSelectItem<T> event, Emitter<ListBlocState<T>> emit);
  bool get isSingleSelect;
}
