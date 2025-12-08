import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/form/mixins/form_data_mixin.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';

part 'form_event.dart';
part 'form_state.dart';

abstract class FormBloc<F extends BaseFormEntity<F, E>, P, E extends Enum>
    extends BaseBloc<FormEvent, FormBlocState<F, E>>
    with FormDataMixin<F, P, E>, FormErrorsMixin<F, P, E> {
  FormBloc(ScreenManagerCubit screenManagerCubit, F formData)
    : super(FormStateInitial(formData: formData), screenManagerCubit) {
    initData(formData);
    initErrors();
    if (isStepped) (this as SteppedFormMixin<F, P, E>).initStepped();
    if (isUniqueFieldValidator) (this as UniqueFieldValidatorMixin<F, P, E>).initUniqueFieldChecker();
    if (isInfoFetcher) (this as InfoFetcherFormMixin<F, P, E>).initInfoFetcher();
  }

  bool get isStepped => this is SteppedFormMixin<F, P, E>;
  @override
  bool get isUniqueFieldValidator => this is UniqueFieldValidatorMixin<F, P, E>;
  @override
  bool get isInfoFetcher => this is InfoFetcherFormMixin<F, P, E>;

  Set<E> get fieldsFetchingInfo => {};
  Set<E> get uniqueKeysBeingChecked => {};
  @override
  void emitState(Emitter<FormBlocState<F, E>> emit) {
    var newState = FormStateLoaded(
      formData: formData,
      step: stepIndex,
      errors: errors,
      fieldsFetchingInfo: fieldsFetchingInfo,
      checkingUniqueFields: uniqueKeysBeingChecked,
      comesFromPreviousStep: comesFromPreviousStep,
    );
    emit(newState);
  }

  bool get comesFromPreviousStep => false;
}
