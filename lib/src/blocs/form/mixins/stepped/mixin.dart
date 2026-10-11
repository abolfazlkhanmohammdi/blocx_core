import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/blocx_form_bloc.dart';
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart';

import 'events.dart';

/// Provides stepped form navigation for [BlocxFormBloc].
///
/// Navigation past the first/last step is ignored.
mixin BlocxFormSteppedMixin<
  F extends BlocxBaseFormEntity<F, E>,
  P,
  E extends Enum
>
    on BlocxFormBloc<F, P, E> {
  int _stepIndex = 0;
  int _previousStepIndex = 0;
  int get maxStep;

  @override
  bool initStepped() {
    on<BlocxFormEventNextStep>(nextStep);
    on<BlocxFormEventPreviousStep>(previousStep);
    on<BlocxFormEventGoToStep>(goToStep);
    return true;
  }

  void nextStep(
    BlocxFormEventNextStep event,
    Emitter<BlocxFormState<F, E>> emit,
  ) {
    if (_stepIndex >= maxStep) return;
    _previousStepIndex = _stepIndex;
    _stepIndex++;
    onStepChanged(emit);
    emitState(emit);
  }

  void previousStep(
    BlocxFormEventPreviousStep event,
    Emitter<BlocxFormState<F, E>> emit,
  ) {
    if (_stepIndex <= 0) return;
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

  void goToStep(
    BlocxFormEventGoToStep event,
    Emitter<BlocxFormState<F, E>> emit,
  ) {
    assert(
      event.stepIndex >= 0 && event.stepIndex <= maxStep,
      'Invalid step index ${event.stepIndex} (maxStep: $maxStep)',
    );
    if (event.stepIndex < 0 || event.stepIndex > maxStep) return;
    _previousStepIndex = _stepIndex;
    _stepIndex = event.stepIndex;
    onStepChanged(emit);
    emitState(emit);
  }

  @override
  bool get comesFromPreviousStep => _previousStepIndex < _stepIndex;

  void onStepChanged(Emitter<BlocxFormState<F, E>> emit) {}
}
