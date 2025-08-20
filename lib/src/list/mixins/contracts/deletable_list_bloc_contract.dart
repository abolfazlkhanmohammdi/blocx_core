import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/blocx.dart';
import 'package:blocx/src/core/use_cases/base_use_case.dart';

abstract interface class DeletableListBlocContract<T extends ListEntity<T>> {
  void initDeletable();
  FutureOr removeItem(ListEventRemoveItem<T> event, Emitter<ListState<T>> emit);
  BaseUseCase<bool>? deleteItemUseCase(T item);
}
