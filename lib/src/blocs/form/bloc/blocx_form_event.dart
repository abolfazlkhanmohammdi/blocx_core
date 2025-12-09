part of 'blocx_form_bloc.dart';

class BlocxFormEvent extends BaseEvent {}

class BlocxFormEventInit<P> extends BlocxFormEvent {
  final P? payload;
  BlocxFormEventInit({required this.payload});
}

class BlocxFormEventUpdateData<E> extends BlocxFormEvent {
  final dynamic data;
  final E key;
  BlocxFormEventUpdateData({required this.data, required this.key});
}

class BlocxFormEventNextStep extends BlocxFormEvent {}

class BlocxFormEventPreviousStep extends BlocxFormEvent {}

class BlocxFormEventGoToStep extends BlocxFormEvent {
  final int stepIndex;
  BlocxFormEventGoToStep(this.stepIndex);
}

class BlocxFormEventCheckUniqueValue<E extends Enum> extends BlocxFormEvent {
  final E key;
  final Object data;
  BlocxFormEventCheckUniqueValue({required this.key, required this.data});
}

class BlocxFormEventFetchRequiredInfo extends BlocxFormEvent {}

class BlocxFormEventSubmit extends BlocxFormEvent {}

class BlocxFormEventSetTimedErrorToField<E extends Enum> extends BlocxFormEvent {
  final String message;
  final E key;
  final Duration? duration;
  BlocxFormEventSetTimedErrorToField({required this.message, required this.key, this.duration});
}

class BlocxFormEventSetErrorToField<E extends Enum> extends BlocxFormEvent {
  final String message;
  final E key;
  BlocxFormEventSetErrorToField({required this.message, required this.key});
}

class BlocxFormEventClearFieldError<E extends Enum> extends BlocxFormEvent {
  final E key;
  final String? message;
  bool get clearAll => message == null;
  BlocxFormEventClearFieldError({required this.key, this.message});
}

class BlocxFormEventUpdateFormData<P> extends BlocxFormEvent {
  final P payload;
  final bool isUpdate;
  BlocxFormEventUpdateFormData({required this.payload, this.isUpdate = true});
}
