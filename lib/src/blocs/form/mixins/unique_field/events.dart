import 'package:blocx_core/form_bloc.dart';

class BlocxFormEventCheckUniqueValue<E extends Enum> extends BlocxFormEvent {
  final E key;
  final Object data;
  BlocxFormEventCheckUniqueValue({required this.key, required this.data});
}
