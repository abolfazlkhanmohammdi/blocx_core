part of 'blocx_form_bloc.dart';

class BlocxFormState<F, E extends Enum> extends BaseState {
  final F formData;
  final int step;
  final bool comesFromPreviousStep;
  final Map<E, Set<String>> errors;
  final Set<E> fieldsFetchingInfo;
  final Set<E> checkingUniqueFields;
  BlocxFormState({
    required this.step,
    required this.formData,
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

  bool get isValid => errors.isEmpty;
  String? errorByKey(E key) {
    var errors = this.errors[key];
    if (errors == null || errors.isEmpty) return null;
    return errors.first;
  }

  String allErrors(FieldNameProvider<E> nameProvider) {
    List<String> errors = [];
    for (var entry in this.errors.entries) {
      var fieldName = nameProvider(entry.key);
      var fieldErrors = entry.value;
      errors.add("$fieldName:\n${fieldErrors.join(".\n")}.\n");
    }
    return errors.join('\n');
  }
}

class BlocxFormStateInitial<F, E extends Enum> extends BlocxFormState<F, E> {
  BlocxFormStateInitial({required super.formData})
    : super(
        shouldListen: false,
        shouldRebuild: true,
        step: 0,
        errors: {},
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      );
}

class BlocxFormStateLoaded<F, E extends Enum> extends BlocxFormState<F, E> {
  BlocxFormStateLoaded({
    required super.step,
    required super.comesFromPreviousStep,
    required super.errors,
    required super.fieldsFetchingInfo,
    required super.formData,
    required super.checkingUniqueFields,
  }) : super(shouldListen: false, shouldRebuild: true);
}

class BlocxFormStateApplyInitialDataToForm<F, E extends Enum> extends BlocxFormState<F, E> {
  BlocxFormStateApplyInitialDataToForm({required super.formData})
    : super(
        shouldRebuild: false,
        shouldListen: true,
        step: 0,
        errors: {},
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      );
}

class BlocxFormStateSubmittingForm<F, E extends Enum> extends BlocxFormState<F, E> {
  final String? buttonText;
  BlocxFormStateSubmittingForm({required super.step, required super.formData, this.buttonText})
    : super(
        shouldRebuild: true,
        shouldListen: false,
        errors: {},
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      );
}

class BlocxFormStateFormSubmitted<F, E extends Enum> extends BlocxFormState<F, E> {
  final dynamic submittedData;
  BlocxFormStateFormSubmitted({required super.formData, required this.submittedData})
    : super(
        shouldRebuild: false,
        shouldListen: true,
        errors: {},
        step: 0,
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      );
}

class BlocxFormStateFormUpdated<F, E extends Enum> extends BlocxFormState<F, E> {
  BlocxFormStateFormUpdated({
    required super.step,
    required super.formData,
    required super.errors,
    required super.fieldsFetchingInfo,
    required super.checkingUniqueFields,
  }) : super(shouldRebuild: false, shouldListen: true);
}

typedef FieldNameProvider<E> = String Function(E key);
