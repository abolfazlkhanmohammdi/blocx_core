part of 'form_bloc.dart';

class FormBlocState<F, E extends Enum> extends BaseState {
  final F formData;
  final int step;
  final bool comesFromPreviousStep;
  final Map<E, Set<String>> errors;
  final Set<E> fieldsFetchingInfo;
  final Set<E> checkingUniqueFields;
  FormBlocState({
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
}

class FormStateInitial<F, E extends Enum> extends FormBlocState<F, E> {
  FormStateInitial({required super.formData})
    : super(
        shouldListen: false,
        shouldRebuild: true,
        step: 0,
        errors: {},
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      );
}

class FormStateLoaded<F, E extends Enum> extends FormBlocState<F, E> {
  FormStateLoaded({
    required super.step,
    required super.comesFromPreviousStep,
    required super.errors,
    required super.fieldsFetchingInfo,
    required super.formData,
    required super.checkingUniqueFields,
  }) : super(shouldListen: false, shouldRebuild: true);
}

class FormStateApplyInitialDataToForm<F, E extends Enum> extends FormBlocState<F, E> {
  FormStateApplyInitialDataToForm({required super.formData})
    : super(
        shouldRebuild: false,
        shouldListen: true,
        step: 0,
        errors: {},
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      );
}

class FormStateSubmittingForm<F, E extends Enum> extends FormBlocState<F, E> {
  final String? buttonText;
  FormStateSubmittingForm({required super.step, required super.formData, this.buttonText})
    : super(
        shouldRebuild: true,
        shouldListen: false,
        errors: {},
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      );
}

class FormStateFormSubmitted<F, E extends Enum> extends FormBlocState<F, E> {
  final dynamic submittedData;
  FormStateFormSubmitted({required super.formData, required this.submittedData})
    : super(
        shouldRebuild: false,
        shouldListen: true,
        errors: {},
        step: 0,
        fieldsFetchingInfo: {},
        checkingUniqueFields: {},
      );
}

class FormStateFormUpdated<F, E extends Enum> extends FormBlocState<F, E> {
  FormStateFormUpdated({
    required super.step,
    required super.formData,
    required super.errors,
    required super.fieldsFetchingInfo,
    required super.checkingUniqueFields,
  }) : super(shouldRebuild: false, shouldListen: true);
}
