import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/form/validators/blocx_form_validator.dart';
import 'package:blocx_core/src/blocs/form/validators/timed_error_message.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';

/// A mixin that adds form validation capabilities to a [FormBloc].
///
/// This mixin integrates a [BlocxFormValidator] to perform field-level
/// and form-level validation based on the current [formValidationMode].
/// It also handles applying validation errors, including timed errors.
mixin FormValidationMixin<F extends BaseFormEntity<F, E>, P, E extends Enum> on FormBloc<F, P, E> {
  /// The form validator to use for validating fields and the entire form.
  BlocxFormValidator<F, E> get validator;

  /// Controls when the form validation should occur.
  ///
  /// Defaults to [FormValidationMode.onUserInteraction].
  FormValidationMode get formValidationMode => FormValidationMode.onUserInteraction;

  /// Validates the form based on the [formData] and optionally a single [key].
  ///
  /// - If [formValidationMode] is [FormValidationMode.onUserInteraction],
  ///   [key] **must** be provided to validate a specific field.
  /// - Otherwise, the entire form is validated.
  @override
  void validateForm(F formData, {E? key}) {
    var validationErrors = <E, List<TimedErrorMessage>>{};

    if (formValidationMode == FormValidationMode.onUserInteraction) {
      assert(key != null, 'Key must be provided for onUserInteraction mode.');
      var errors = validator.validateField(key!, formData);
      validationErrors[key] = errors;
    } else {
      validationErrors = validator.validate(formData);
    }

    // Apply the errors to the form state
    _applyValidationErrors(validationErrors);
  }

  /// Applies the validation errors to the form's state.
  void _applyValidationErrors(Map<E, List<TimedErrorMessage>> errors) {
    for (final entry in errors.entries) {
      setFieldErrors(entry.key, entry.value);
    }
  }

  /// Sets the field errors for a specific field.
  ///
  /// Timed errors are dispatched as events, while persistent errors
  /// are set directly using [setFieldError].
  void setFieldErrors(E key, List<TimedErrorMessage> value) {
    for (final errorMessage in value) {
      if (errorMessage.duration == null) {
        setFieldError(key, errorMessage.error);
      } else {
        add(FormEventSetTimedErrorToField(message: errorMessage.error, key: key));
      }
    }
  }
}

/// Determines when the form should validate.
enum FormValidationMode {
  /// Validate only when the form is submitted.
  onSubmit,

  /// Validate a field whenever it changes.
  onUserInteraction,

  /// Validate the entire form all the time.
  always,
}
