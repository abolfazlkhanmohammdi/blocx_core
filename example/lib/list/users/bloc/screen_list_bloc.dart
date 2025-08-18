import 'dart:async';

import 'package:blocx/blocx.dart';
import 'package:blocx_example/data/fake_repository.dart';
import 'package:blocx_example/list/users/models/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// No payload is required so we pass sth arbitrary like dynamic
/// normal loads(without UseCases) are used in this bloc so we have to override [loadInitialPage], [loadNextPage] and [refreshPage]
class ScreenUsersBloc extends ListBloc<User, dynamic> {
  FakeRepository repository = FakeRepository();

  ScreenUsersBloc() : super(ScreenManagerCubit());
  @override
  FutureOr<void> handleDataError(Object error, Emitter<ListBlocState<User>> emit, {StackTrace? stacktrace}) {
    // TODO: implement handleDataError
  }

  @override
  Future loadInitialPage(
    ListBlocEventLoadData<User, dynamic> event,
    Emitter<ListBlocState<User>> emit,
  ) async {
    var users = await repository.getUsers(20, 0);

    insertToList(users);
  }
}
