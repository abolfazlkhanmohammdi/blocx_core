import 'package:blocx_core/src/blocs/form/validators/blocx_simple_field_validator.dart';

/// Validator that ensures a field matches a given regular expression pattern.
class BlocxRegexValidator extends BlocxSingleErrorFieldValidator<String> {
  final RegExp pattern;
  final String errorMessage;

  /// Creates a validator with the provided [pattern] and [errorMessage].
  BlocxRegexValidator({required this.pattern, required this.errorMessage, super.duration});

  @override
  String? validateWithSingleError(String value) {
    if (!pattern.hasMatch(value.trim())) {
      return errorMessage;
    }
    return null;
  }
}
