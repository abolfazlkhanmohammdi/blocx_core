import 'package:blocx/src/core/base_bloc/base_bloc.dart';
import 'package:blocx/src/list/mixins/contracts/highlightable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/contracts/searchable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/contracts/selectable_list_bloc_contract.dart';
import 'package:blocx/src/list/mixins/implementations/list_bloc_data_mixin.dart';
import 'package:blocx/src/list/models/list_entity.dart';
import 'package:blocx/src/screen_manager/screen_manager_cubit.dart';
part 'list_bloc_event.dart';
part 'list_bloc_state.dart';

abstract class ListBloc<T extends ListEntity<T>, P> extends BaseBloc<ListBlocEvent<T>, ListBlocState<T>>
    with ListBlocDataMixin<T, P> {
  final ScreenManagerCubit _screenManagerCubit;
  ListBloc({required ScreenManagerCubit screenManagerCubit})
    : _screenManagerCubit = screenManagerCubit,
      super(ListBlocStateLoading()) {
    initDataMixin();
    if (this is SelectableBlocContract) (this as SelectableBlocContract).initSelectionMixin();
    if (this is HighlightableListBlocContract) (this as HighlightableListBlocContract).initHighlightMixin();
    if (this is SearchableListBlocContract) (this as SearchableListBlocContract).initSearch();
  }

  void pop() => _screenManagerCubit.pop();
  void displayError(Object error, {StackTrace? stackTrace}) =>
      _screenManagerCubit.displayErrorPage(error, stackTrace);

  void displayWarningSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.warning, title: title);

  void displayErrorSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.error, title: title);

  void displayInfoSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(message, BlocXSnackbarType.info, title: title);

  @override
  Future<void> close() async {
    await _screenManagerCubit.close();
    return super.close();
  }
}
