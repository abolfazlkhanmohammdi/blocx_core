import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/form_bloc.dart';

mixin SteppedFormMixin<F, P, E extends Enum> on FormBloc<F, P, E> {
  int _stepIndex = 0;
  int get maxStep;
  void initStepped() {
    on<FormEventNextStep>(nextStep);
    on<FormEventPreviousStep>(previousStep);
  }

  FutureOr<void> nextStep(FormEventNextStep event, Emitter<FormBlocState<F, E>> emit) {
    if (_stepIndex == maxStep) throw StateError("Max step is $maxStep you cannot go further");
    _stepIndex++;
    emitState(emit);
  }

  FutureOr<void> previousStep(FormEventPreviousStep event, Emitter<FormBlocState<F, E>> emit) {
    if (_stepIndex == 0) throw ("this is the first step you cannot go back");
    _stepIndex--;
    emitState(emit);
  }

  @override
  int get stepIndex => _stepIndex;
}
