part of 'form_bloc.dart';

class FormEvent extends BaseEvent {}

class FormEventInit<P> extends FormEvent {
  final P? payload;
  FormEventInit({required this.payload});
}

class FormEventUpdateData<E> extends FormEvent {
  final dynamic data;
  final E key;
  FormEventUpdateData({required this.data, required this.key});
}

class FormEventNextStep extends FormEvent {}

class FormEventPreviousStep extends FormEvent {}

class FormEventGoToStep extends FormEvent {
  final int stepIndex;
  FormEventGoToStep(this.stepIndex);
}

class FormEventCheckUniqueValue<E extends Enum> extends FormEvent {
  final E key;
  final Object data;
  FormEventCheckUniqueValue({required this.key, required this.data});
}

class FormEventFetchRequiredInfo extends FormEvent {}

class FormEventSubmit extends FormEvent {}

class FormEventSetTimedErrorToField<E extends Enum> extends FormEvent {
  final String message;
  final E key;
  final Duration? duration;
  FormEventSetTimedErrorToField({required this.message, required this.key, this.duration});
}

class FormEventSetErrorToField<E extends Enum> extends FormEvent {
  final String message;
  final E key;
  FormEventSetErrorToField({required this.message, required this.key});
}

class FormEventClearFieldError<E extends Enum> extends FormEvent {
  final E key;
  final String? message;
  bool get clearAll => message == null;
  FormEventClearFieldError({required this.key, this.message});
}

class FormEventUpdateFormData<P> extends FormEvent {
  final P payload;
  final bool isUpdate;
  FormEventUpdateFormData({required this.payload, this.isUpdate = true});
}
