// File: blocx_match_field_validator.dart

import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';

/// Validator that ensures a field matches another field’s value.
class BlocxMatchFieldValidator<T> extends BlocxSingleErrorFieldValidator<dynamic> {
  final String noMatchMessage;
  final dynamic otherValue;

  BlocxMatchFieldValidator({required this.noMatchMessage, required this.otherValue, super.duration});

  @override
  String? validateWithSingleError(value) {
    if (value != otherValue) return noMatchMessage;
    return null;
  }
}
