import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/form/mixins/form_data_mixin.dart';
import 'package:blocx_core/src/blocs/form/mixins/form_errors_mixin.dart';
import 'package:blocx_core/src/blocs/form/mixins/info_fetcher_mixin.dart';
import 'package:blocx_core/src/blocs/form/mixins/stepped_form_mixin.dart';
import 'package:blocx_core/src/blocs/form/mixins/unique_field_validator_mixin.dart';
import 'package:blocx_core/src/core/enum_error_codes.dart';

part 'form_event.dart';
part 'form_state.dart';

abstract class FormBloc<F, P, E extends Enum> extends BaseBloc<FormEvent, FormBlocState<F, E>>
    with FormDataMixin<F, P, E>, FormErrorsMixin<F, P, E> {
  FormBloc(ScreenManagerCubit screenManagerCubit, F formData)
    : super(FormStateInitial(formData: formData), screenManagerCubit) {
    initData(formData);
    if (isStepped) (this as SteppedFormMixin<F, P, E>).initStepped();
    if (isUniqueFieldValidator) (this as UniqueFieldValidatorMixin<F, P, E>).initUniqueFieldChecker();
    if (isInfoFetcher) (this as InfoFetcherMixin<F, P, E>).initInfoFetcher();
  }

  bool get isStepped => this is SteppedFormMixin<F, P, E>;
  @override
  bool get isUniqueFieldValidator => this is UniqueFieldValidatorMixin<F, P, E>;
  @override
  bool get isInfoFetcher => this is InfoFetcherMixin<F, P, E>;
  @override
  void emitState(Emitter<FormBlocState<F, E>> emit) {
    emit(FormStateLoaded(formData: formData, step: stepIndex, errors: errors));
  }
}
