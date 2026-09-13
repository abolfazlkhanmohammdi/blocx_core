import 'package:blocx_core/form_bloc.dart';

/// Adds validation support to a [BlocxFormBloc].
///
/// This mixin delegates validation rules to [validator] and decides when to run
/// field-level or full-form validation based on [formValidationMode].
///
/// Validation timing:
///
/// - [FormValidationMode.none]: no validation runs.
/// - [FormValidationMode.onSubmit]: full validation only runs on submit.
/// - [FormValidationMode.onUserInteraction]: changed fields validate while
///   typing, and the full form validates on submit.
/// - [FormValidationMode.always]: the full form validates on every field update
///   and on submit.
mixin BlocxFormValidationMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BlocxFormBloc<F, P, E> {
  /// The validator responsible for field-level and full-form validation.
  BlocxFormValidator<F, E> get validator;

  @override
  bool initValidation() {
    return true;
  }

  /// Validates [formData] according to [formValidationMode].
  ///
  /// [key] is provided when a single field changed.
  ///
  /// [forceFullValidation] is used by submit/init flows to request a full-form
  /// validation pass. The request still respects [formValidationMode].
  @override
  void validateForm(
    F formData, {
    E? key,
    bool forceFullValidation = false,
  }) async {
    switch (formValidationMode) {
      case FormValidationMode.none:
        return;

      case FormValidationMode.onSubmit:
        if (!forceFullValidation) return;
        _validateAndApplyFullForm(formData);
        return;

      case FormValidationMode.onUserInteraction:
        if (forceFullValidation) {
          _validateAndApplyFullForm(formData);
          return;
        }

        if (key != null) {
          _validateAndApplyField(formData, key);
        }

        return;

      case FormValidationMode.always:
        await _validateAndApplyFullForm(formData);
        return;
    }
  }

  @override
  Future<bool> checkIsFieldValid(F formData, E key) async {
    var errors = validator.validateField(formData, key);
    return errors.isEmpty;
  }

  /// Validates the entire [formData] object and replaces all validation errors.
  Future<void> _validateAndApplyFullForm(F formData) async {
    final validationErrors = validator.validateForm(formData);
    _applyFullFormValidationErrors(validationErrors);
  }

  /// Validates a single field identified by [key].
  ///
  /// Only errors for [key] are replaced. Errors from other fields are preserved.
  void _validateAndApplyField(F formData, E key) async {
    final validationErrors = validator.validateField(formData, key);
    _applyFieldValidationErrors(key, validationErrors);
  }

  /// Replaces all current validation errors with [errors].
  void _applyFullFormValidationErrors(
    Map<E, List<TimedErrorMessage>> errors,
  ) {
    clearAllErrors(source: ErrorMutationSource.formValidationMixinApplyFieldValidationErrors);

    for (final entry in errors.entries) {
      setFieldErrors(
          entry.key, ErrorMutationSource.formValidationMixinApplyFieldValidationErrors, entry.value);
    }
  }

  /// Replaces validation errors for only one [key].
  void _applyFieldValidationErrors(
    E key,
    List<TimedErrorMessage> errors,
  ) {
    clearFieldError(key, source: ErrorMutationSource.formValidationMixinApplyFieldValidationErrors);
    setFieldErrors(key, ErrorMutationSource.formValidationMixinApplyFieldValidationErrors, errors);
  }

  /// Sets validation [errors] for the field identified by [key].
  ///
  /// Timed errors are dispatched as timed-error events. Persistent errors are
  /// applied directly to the form error map.
  void setFieldErrors(E key, ErrorMutationSource source, List<TimedErrorMessage> errors) {
    for (final errorMessage in errors) {
      if (errorMessage.duration == null) {
        setFieldError(key, errorMessage.error, source: source);
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

  @override
  bool checkIsFormValid() {
    var errors = validator.validateForm(formData);
    var hasErrors = errors.values.any((x) => x.isNotEmpty);
    var isValid = !hasErrors;
    return isValid;
  }

  /// Default duration for field validation errors.
  ///
  /// Returns `null`, meaning validation errors remain until cleared or replaced.
  Duration? get fieldErrorDuration => null;

  /// The form keys controlled by this validator mixin.
  List<E> get formKeysList;
}

/// Defines when a form should validate.
enum FormValidationMode {
  /// Validate only when the form is submitted.
  onSubmit,

  /// Validate changed fields during user interaction and validate the full form
  /// on submit.
  onUserInteraction,

  /// Validate the full form on every field update and on submit.
  always,

  /// Disable validation completely.
  none,
}
