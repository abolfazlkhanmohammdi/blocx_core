import 'package:bloc/bloc.dart';

part 'base_bloc_event.dart';
part 'base_bloc_state.dart';

class BaseBloc<E extends BaseBlocEvent, S extends BaseBlocState> extends Bloc<E, S> {
  BaseBloc(super.initialState);
}
