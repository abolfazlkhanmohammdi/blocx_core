import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';

/// A transformer that debounces incoming events, and restarts the async task
/// if a new event comes in before the previous one finishes.
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) {
    return restartable<E>().call(events.debounce(duration, leading: false, trailing: true), mapper);
  };
}
