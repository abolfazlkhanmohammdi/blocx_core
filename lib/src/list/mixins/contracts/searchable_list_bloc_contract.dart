import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/models/list_entity.dart';

abstract class SearchableListBlocContract<T extends ListEntity<T>> {
  FutureOr search(ListBlocEventSearch<T> event, Emitter<ListBlocState<T>> emit);
  FutureOr clearSearch(ListBlocEventClearSearch<T> event, Emitter<ListBlocState<T>> emit);
  void initSearch();
}
