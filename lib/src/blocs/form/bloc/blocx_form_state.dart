part of 'blocx_form_bloc.dart';

class BlocxFormState<F, E extends Enum> extends BlocxBaseState {
  final F formData;

  /// Baseline form snapshot captured after initialization, hydration,
  /// prefetching, or reset; used to compute [isDirty].
  final F? initialData;

  final int step;
  final bool comesFromPreviousStep;
  final Map<E, Set<String>> errors;
  final Set<E> fieldsFetchingInfo;
  final Set<E> checkingUniqueFields;
  final bool isFormValid;
  BlocxFormState({
    required this.isFormValid,
    required this.step,
    required this.formData,
    this.initialData,
    required this.errors,
    required this.fieldsFetchingInfo,
    required this.checkingUniqueFields,
    this.comesFromPreviousStep = false,
    required super.shouldRebuild,
    required super.shouldListen,
  });

  bool isFetchingFieldInfo(E key) {
    return fieldsFetchingInfo.contains(key);
  }

  /// True when any field is currently undergoing asynchronous uniqueness checks.
  bool get hasPendingUniqueChecks => checkingUniqueFields.isNotEmpty;

  /// True while required reference/initial datasets are being prefetched.
  bool get isPrefetching => fieldsFetchingInfo.isNotEmpty;

  /// True while the form submission request is in progress.
  bool get isSubmittingForm => this is BlocxFormStateSubmittingForm<F, E>;

  /// True when [formData] differs from [initialData] (or when no baseline
  /// [initialData] snapshot has been recorded).
  bool get isDirty => initialData == null ? true : formData != initialData;

  /// True when the form is valid, has no field/uniqueness errors, and is not
  /// submitting, prefetching, or running async unique-field checks.
  bool get canSubmit =>
      isFormValid &&
      errors.isEmpty &&
      !isSubmittingForm &&
      !isPrefetching &&
      !hasPendingUniqueChecks;

  bool get isValid =>
      errors.isEmpty &&
      fieldsFetchingInfo.isEmpty &&
      checkingUniqueFields.isEmpty;

  String? errorByKey(E key) {
    var errors = this.errors[key];
    if (errors == null || errors.isEmpty) return null;
    return errors.last;
  }

  String allErrors(FieldNameProvider<E> nameProvider) {
    if (errors.isEmpty) return '';

    return errors.entries
        .map((entry) {
          final fieldName = nameProvider(entry.key);
          final fieldErrors = entry.value.join(', ');
          return '$fieldName: $fieldErrors';
        })
        .join('\n');
  }
}

class BlocxFormStateInitial<F, E extends Enum> extends BlocxFormState<F, E> {
  BlocxFormStateInitial({required super.formData, super.initialData})
    : super(
        shouldListen: false,
        shouldRebuild: true,
        step: 0,
        errors: {},
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
        isFormValid: true,
      );
}

class BlocxFormStateLoaded<F, E extends Enum> extends BlocxFormState<F, E> {
  BlocxFormStateLoaded({
    required super.step,
    required super.comesFromPreviousStep,
    required super.errors,
    required super.fieldsFetchingInfo,
    required super.formData,
    super.initialData,
    required super.checkingUniqueFields,
    required super.isFormValid,
  }) : super(shouldListen: false, shouldRebuild: true);
}

class BlocxFormStateApplyInitialDataToForm<F, E extends Enum>
    extends BlocxFormState<F, E> {
  BlocxFormStateApplyInitialDataToForm({
    required super.formData,
    super.initialData,
  }) : super(
         shouldRebuild: false,
         shouldListen: true,
         step: 0,
         errors: {},
         fieldsFetchingInfo: {},
         checkingUniqueFields: {},
         isFormValid: true,
       );
}

class BlocxFormStateSubmittingForm<F, E extends Enum>
    extends BlocxFormState<F, E> {
  final String? buttonText;
  BlocxFormStateSubmittingForm({
    required super.step,
    required super.formData,
    super.initialData,
    this.buttonText,
  }) : super(
         shouldRebuild: true,
         shouldListen: false,
         errors: {},
         fieldsFetchingInfo: {},
         checkingUniqueFields: {},
         isFormValid: false,
       );
}

class BlocxFormStateFormSubmitted<F, E extends Enum>
    extends BlocxFormState<F, E> {
  final dynamic submittedData;
  BlocxFormStateFormSubmitted({
    required super.formData,
    super.initialData,
    required this.submittedData,
  }) : super(
         shouldRebuild: false,
         shouldListen: true,
         errors: {},
         step: 0,
         fieldsFetchingInfo: {},
         checkingUniqueFields: {},
         isFormValid: true,
       );
}

class BlocxFormStateFormUpdated<F, E extends Enum>
    extends BlocxFormState<F, E> {
  final dynamic newValue;
  final dynamic oldValue;
  final E updatedKey;

  BlocxFormStateFormUpdated({
    required this.updatedKey,
    required this.oldValue,
    required this.newValue,
    required super.step,
    required super.formData,
    super.initialData,
    required super.errors,
    required super.fieldsFetchingInfo,
    required super.checkingUniqueFields,
    required super.isFormValid,
  }) : super(shouldRebuild: false, shouldListen: true);
}

typedef FieldNameProvider<E> = String Function(E key);
