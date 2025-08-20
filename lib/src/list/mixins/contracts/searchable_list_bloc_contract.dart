import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx/src/list/bloc/list_bloc.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/list/use_cases/search_use_case.dart';

abstract interface class SearchableListBlocContract<T extends ListEntity<T>, P> {
  String searchText = "";
  FutureOr search(ListEventSearch<T> event, Emitter<ListState<T>> emit);
  FutureOr clearSearch(ListEventClearSearch<T> event, Emitter<ListState<T>> emit);
  void initSearch();
  SearchUseCase<T, P>? searchUseCase(String searchText);
}
