import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/form/mixins/blocx_form_data_mixin.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';

part 'blocx_form_event.dart';
part 'blocx_form_state.dart';

abstract class BlocxFormBloc<F extends BaseFormEntity<F, E>, P, E extends Enum>
    extends BaseBloc<BlocxFormEvent, BlocxFormState<F, E>>
    with BlocxFormDataMixin<F, P, E>, BlocxFormErrorsMixin<F, P, E> {
  BlocxFormBloc(ScreenManagerCubit screenManagerCubit, F formData)
    : super(BlocxFormStateInitial(formData: formData), screenManagerCubit) {
    initData(formData);
    initErrors();
    if (isStepped) (this as BlocxSteppedFormMixin<F, P, E>).initStepped();
    if (isUniqueFieldValidator) (this as BlocxUniqueFieldValidatorMixin<F, P, E>).initUniqueFieldChecker();
    if (isInfoFetcher) (this as BlocxInfoFetcherFormMixin<F, P, E>).initInfoFetcher();
  }

  bool get isStepped => this is BlocxSteppedFormMixin<F, P, E>;
  @override
  bool get isUniqueFieldValidator => this is BlocxUniqueFieldValidatorMixin<F, P, E>;
  @override
  bool get isInfoFetcher => this is BlocxInfoFetcherFormMixin<F, P, E>;

  Set<E> get fieldsFetchingInfo => {};
  Set<E> get uniqueKeysBeingChecked => {};
  @override
  void emitState(Emitter<BlocxFormState<F, E>> emit) {
    var newState = BlocxFormStateLoaded(
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
