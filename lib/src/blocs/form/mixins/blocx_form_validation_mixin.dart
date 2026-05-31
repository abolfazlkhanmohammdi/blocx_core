import 'package:blocx_core/form_bloc.dart';
import 'package:blocx_core/src/blocs/form/validation/blocx_form_validator.dart';

/// A mixin that adds form validation capabilities to a [BlocxFormBloc].
///
/// This mixin integrates a [BlocxFormValidator] to perform field-level
/// and form-level validation based on the current [formValidationMode].
/// It also handles applying validation errors, including timed errors.
mixin BlocxFormValidationMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BlocxFormBloc<F, P, E> {
  /// The form validator to use for validating fields and the entire form.
  BlocxFormValidator<F, E> get validator;

  /// Validates the form based on the [formData] and optionally a single [key].
  ///
  /// - If [formValidationMode] is [FormValidationMode.onUserInteraction],
  ///   [key] **must** be provided to validate a specific field.
  /// - Otherwise, the entire form is validated.
  @override
  Future<void> validateForm(F formData, {E? key}) async {
    var validationErrors = <E, List<TimedErrorMessage>>{};

    switch (formValidationMode) {
      case FormValidationMode.onUserInteraction:
        if (key != null) {
          validationErrors[key] = await _validateField(key, formData);
        }
        // If key is null, do nothing (expected)
        break;

      case FormValidationMode.onSubmit:
      case FormValidationMode.always:
        validationErrors = await _validateForm(formData);
        break;

      case FormValidationMode.none:
        return;
    }

    _applyValidationErrors(validationErrors);
  }

  Future<Map<E, List<TimedErrorMessage>>> _validateForm(F formData) async {
    var errors = await validator.validateForm(formData);
    return errors;
  }

  Future<List<TimedErrorMessage>> _validateField(E key, F formData) async {
    var errors = validator.validateField(formData, key);
    return errors;
  }

  /// Applies the validation errors to the form's state.
  void _applyValidationErrors(Map<E, List<TimedErrorMessage>> errors) {
    clearAllErrors();
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
        add(
          BlocxFormEventSetTimedErrorToField(
            message: errorMessage.error,
            duration: errorMessage.duration,
            key: key,
          ),
        );
      }
    }
  }

  Duration? get fieldErrorDuration => null;

  List<E> get formKeysList;
}

/// Determines when the form should validate.
enum FormValidationMode {
  /// Validate only when the form is submitted.
  onSubmit,

  /// Validate a field whenever it changes.
  onUserInteraction,

  /// Validate the entire form all the time.
  always,
  none,
}
