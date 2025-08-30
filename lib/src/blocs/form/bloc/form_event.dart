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

class FormEventCheckUniqueValue<E extends Enum> extends FormEvent {
  final E key;
  final Object data;
  FormEventCheckUniqueValue({required this.key, required this.data});
}

class FormEventFetchRequiredInfo extends FormEvent {}

class FormEventSubmit extends FormEvent {}
