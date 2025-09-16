part of 'form_bloc.dart';

class FormBlocState<F, E extends Enum> extends BaseState {
  final F formData;
  final int step;
  final Map<E, Set<BlocXErrorCode>> errors;
  final Set<E> fieldsFetchingInfo;
  FormBlocState({
    required this.step,
    required this.formData,
    required this.errors,
    required this.fieldsFetchingInfo,
    required super.shouldRebuild,
    required super.shouldListen,
  });

  bool isFetchingFieldInfo(E key) {
    return fieldsFetchingInfo.contains(key);
  }
}

class FormStateInitial<F, E extends Enum> extends FormBlocState<F, E> {
  FormStateInitial({required super.formData})
    : super(shouldListen: false, shouldRebuild: true, step: 0, errors: {}, fieldsFetchingInfo: {});
}

class FormStateLoaded<F, E extends Enum> extends FormBlocState<F, E> {
  FormStateLoaded({
    required super.step,
    required super.errors,
    required super.fieldsFetchingInfo,
    required super.formData,
  }) : super(shouldListen: false, shouldRebuild: true);
}

class FormStateApplyInitialDataToForm<F, E extends Enum> extends FormBlocState<F, E> {
  FormStateApplyInitialDataToForm({required super.formData})
    : super(shouldRebuild: false, shouldListen: true, step: 0, errors: {}, fieldsFetchingInfo: {});
}

class FormStateSubmittingForm<F, E extends Enum> extends FormBlocState<F, E> {
  FormStateSubmittingForm({required super.formData})
    : super(shouldRebuild: true, shouldListen: false, step: 0, errors: {}, fieldsFetchingInfo: {});
}

class FormStateFormSubmitted<F, E extends Enum> extends FormBlocState<F, E> {
  final dynamic submittedData;
  FormStateFormSubmitted({required super.formData, required this.submittedData})
    : super(shouldRebuild: false, shouldListen: true, errors: {}, step: 0, fieldsFetchingInfo: {});
}

class FormStateCheckingUniqueFormField<F, E extends Enum> extends FormBlocState<F, E> {
  final E key;
  FormStateCheckingUniqueFormField({required this.key, required super.formData})
    : super(shouldRebuild: true, shouldListen: false, step: 0, errors: {}, fieldsFetchingInfo: {});
}
