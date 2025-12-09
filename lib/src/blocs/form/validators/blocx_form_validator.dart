import 'package:blocx_core/src/blocs/form/validators/blocx_field_validator.dart';
import 'package:blocx_core/src/blocs/form/validators/timed_error_message.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';
import 'package:meta/meta.dart';

/// Base class for form validators that validates an entire form entity.
///
/// Subclasses should provide a list of fields ([keys]) and the corresponding
/// validators for each field ([validatorsByField]).
abstract class BlocxFormValidator<F extends BaseFormEntity<F, E>, E extends Enum> {
  /// Validates the entire [formData] and returns a map of errors per field.
  ///
  /// Each key in the returned map represents a field, and the value is a list
  /// of timed error messages for that field. Fields with no errors are omitted.
  Map<E, List<TimedErrorMessage>> validate(F formData) {
    final errors = <E, List<TimedErrorMessage>>{};

    for (final key in keys) {
      final fieldErrors = validateField(key, formData);
      if (fieldErrors.isNotEmpty) {
        errors[key] = fieldErrors;
      }
    }

    return errors;
  }

  /// Validates a single field [key] in the given [formData].
  ///
  /// Returns a list of [TimedErrorMessage]. An empty list indicates no errors.
  @internal
  List<TimedErrorMessage> validateField(E key, F formData) {
    final fieldValidators = validatorsByField(key, formData);
    final value = formData.getValueByKey(key);

    final List<TimedErrorMessage> errors = [];
    for (final validator in fieldValidators) {
      final validationResult = validator.validate(value);
      if (validationResult.isNotEmpty) {
        errors.addAll(validationResult.map((e) => TimedErrorMessage(error: e, duration: validator.duration)));
      }
    }

    return errors;
  }

  /// Returns the list of validators for a specific field.
  List<BlocxFieldValidator<dynamic>> validatorsByField(E key, F formData);

  /// Returns the list of all fields to validate.
  List<E> get keys;
}
