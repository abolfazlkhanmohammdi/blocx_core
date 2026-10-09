import 'package:blocx_core/form_bloc.dart';

class BlocxFormEventNextStep extends BlocxFormEvent {}

class BlocxFormEventPreviousStep extends BlocxFormEvent {}

class BlocxFormEventGoToStep extends BlocxFormEvent {
  final int stepIndex;
  BlocxFormEventGoToStep(this.stepIndex);
}
