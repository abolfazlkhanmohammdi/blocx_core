import 'package:blocx_core/form_bloc.dart';

class BlocxConditionalRequiredValidator extends BlocxSingleErrorFieldValidator {
  final bool condition;

  BlocxConditionalRequiredValidator(this.condition);
  @override
  String? validateWithSingleError(value) {
    if (!condition) return null;
    return BlocxRequiredValidator().validateWithSingleError(value);
  }
}
