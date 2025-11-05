import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/form_bloc.dart';

mixin SteppedFormMixin<F, P, E extends Enum> on FormBloc<F, P, E> {
  int _stepIndex = 0;
  int _previousStepIndex = 0;
  int get maxStep;
  void initStepped() {
    on<FormEventNextStep>(nextStep);
    on<FormEventPreviousStep>(previousStep);
    on<FormEventGoToStep>(goToStep);
  }

  FutureOr<void> nextStep(FormEventNextStep event, Emitter<FormBlocState<F, E>> emit) {
    if (_stepIndex == maxStep) throw StateError("Max step is $maxStep you cannot go further");
    _previousStepIndex = _stepIndex;
    _stepIndex++;
    onStepChanged(emit);
    emitState(emit);
  }

  FutureOr<void> previousStep(FormEventPreviousStep event, Emitter<FormBlocState<F, E>> emit) {
    if (_stepIndex == 0) throw ("this is the first step you cannot go back");
    _previousStepIndex = _stepIndex;
    _stepIndex--;
    onStepChanged(emit);
    emitState(emit);
  }

  @override
  int get stepIndex => _stepIndex;

  void setStepIndex(int index) {
    _stepIndex = index;
  }

  FutureOr<void> goToStep(FormEventGoToStep event, Emitter<FormBlocState<F, E>> emit) {
    if (event.stepIndex < 0 || event.stepIndex > maxStep) {
      throw StateError("Invalid step index $event.stepIndex");
    }
    _previousStepIndex = _stepIndex;
    _stepIndex = event.stepIndex;
    onStepChanged(emit);
    emitState(emit);
  }

  @override
  bool get comesFromPreviousStep => _previousStepIndex < _stepIndex;

  void onStepChanged(Emitter<FormBlocState<F, E>> emit) {}
}
