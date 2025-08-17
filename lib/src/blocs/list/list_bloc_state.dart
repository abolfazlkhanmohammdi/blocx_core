part of 'list_bloc.dart';

sealed class ListBlocState<T extends ListEntity<T>> extends BaseBlocState {
  final List<T> list;
  ListBlocState({required this.list});
}

class ListBlocStateLoading<T extends ListEntity<T>> extends ListBlocState<T> {
  ListBlocStateLoading() : super(list: const []);
}

class ListBlocStateLoaded<T extends ListEntity<T>> extends ListBlocState<T> {
  ListBlocStateLoaded({required super.list});
}
