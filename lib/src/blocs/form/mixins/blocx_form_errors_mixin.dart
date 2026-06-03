import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/base/base_bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/blocx_form_bloc.dart';
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart';
import 'package:meta/meta.dart';

/// Adds field-level error handling to a [BlocxFormBloc].
///
/// Stores errors by form field key and exposes them as immutable snapshots for
/// UI states. Supports normal persistent errors and temporary timed errors.
///
/// Timed errors are cleared by dispatching [BlocxFormEventClearFieldError]
/// after their duration expires. This avoids using an old [Emitter] after an
/// event handler has already completed.
mixin BlocxFormErrorsMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BaseBloc<BlocxFormEvent, BlocxFormState<F, E>> {
  final Map<E, Set<String>> _errors = <E, Set<String>>{};
  final Map<E, List<_TimedFieldErrorTimer>> _timers = <E, List<_TimedFieldErrorTimer>>{};

  /// Initialises form error event handlers.
  ///
  /// Called automatically by [BlocxFormBloc]. Do not call this manually from
  /// feature blocs.
  @mustCallSuper
  void initErrors() {
    on<BlocxFormEventSetTimedErrorToField<E>>(setTimedErrorToField);
    on<BlocxFormEventSetErrorToField<E>>(setErrorToField);
    on<BlocxFormEventClearFieldError<E>>(clearFieldErrors);
  }

  /// Adds [error] to the field identified by [key].
  ///
  /// Returns `true` when the error map changed.
  bool setFieldError(E key, String error) {
    final set = _errors.putIfAbsent(key, () => <String>{});
    final changed = set.add(error);

    if (set.isEmpty) {
      _errors.remove(key);
    }

    return changed;
  }

  /// Adds multiple [errors] to the field identified by [key].
  void setFieldErrorsBulk(E key, List<String> errors) {
    final set = _errors.putIfAbsent(key, () => <String>{});
    set.addAll(errors);

    if (set.isEmpty) {
      _errors.remove(key);
    }
  }

  /// Clears either one error message or all errors for the field [key].
  ///
  /// When [errorMessage] is `null`, all errors for [key] are removed.
  /// Returns `true` when something was removed.
  bool clearFieldError(E key, {String? errorMessage}) {
    final set = _errors[key];
    if (set == null) return false;

    final changed = errorMessage == null ? _errors.remove(key) != null : set.remove(errorMessage);

    if (set.isEmpty) {
      _errors.remove(key);
    }

    return changed;
  }

  /// Clears all field errors and cancels all pending timed-error timers.
  void clearAllErrors() {
    _errors.clear();
    clearTimers();
  }

  /// Whether the field identified by [key] currently has an error.
  ///
  /// When [code] is provided, checks for that exact error message.
  bool hasError(E key, [String? code]) {
    final set = _errors[key];
    if (set == null) return false;

    return code == null ? set.isNotEmpty : set.contains(code);
  }

  /// An immutable snapshot of the current field errors.
  Map<E, Set<String>> get errors {
    return UnmodifiableMapView(
      _errors.map(
        (key, value) => MapEntry(key, UnmodifiableSetView(value)),
      ),
    );
  }

  /// Handles [BlocxFormEventSetTimedErrorToField].
  ///
  /// Adds the error immediately, emits the current state, then schedules a
  /// clear event after the requested duration.
  Future<void> setTimedErrorToField(
    BlocxFormEventSetTimedErrorToField<E> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    setFieldError(event.key, event.message);
    emitState(emit);

    final duration = event.duration ?? const Duration(seconds: 3);

    late final _TimedFieldErrorTimer timedErrorTimer;
    final timer = Timer(duration, () {
      _removeTimer(event.key, timedErrorTimer);

      if (isClosed) return;

      add(
        BlocxFormEventClearFieldError<E>(
          key: event.key,
          message: event.message,
        ),
      );
    });

    timedErrorTimer = _TimedFieldErrorTimer(
      message: event.message,
      timer: timer,
    );

    _timers.putIfAbsent(event.key, () => <_TimedFieldErrorTimer>[]).add(
          timedErrorTimer,
        );
  }

  /// Emits the current form state.
  ///
  /// Implemented by [BlocxFormBloc].
  void emitState(Emitter<BlocxFormState<F, E>> emit);

  /// Handles [BlocxFormEventSetErrorToField].
  ///
  /// Adds a persistent error to the field and emits the current state.
  FutureOr<void> setErrorToField(
    BlocxFormEventSetErrorToField<E> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) {
    setFieldError(event.key, event.message);
    emitState(emit);
  }

  /// Handles [BlocxFormEventClearFieldError].
  ///
  /// Clears either one error message or all errors for a field. Matching timed
  /// timers are also cancelled to avoid later redundant clear events.
  FutureOr<void> clearFieldErrors(
    BlocxFormEventClearFieldError<E> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) {
    if (event.clearAll) {
      clearFieldError(event.key);
      _cancelFieldTimers(event.key);
    } else {
      clearFieldError(event.key, errorMessage: event.message!);
      _cancelFieldTimers(event.key, errorMessage: event.message);
    }

    emitState(emit);
  }

  /// Cancels all pending timed-error timers.
  void clearTimers() {
    for (final timers in _timers.values) {
      for (final timedErrorTimer in timers) {
        timedErrorTimer.timer.cancel();
      }
    }

    _timers.clear();
  }

  void _cancelFieldTimers(E key, {String? errorMessage}) {
    final timers = _timers[key];
    if (timers == null) return;

    final timersToCancel = errorMessage == null
        ? timers.toList()
        : timers.where((timer) => timer.message == errorMessage).toList();

    for (final timedErrorTimer in timersToCancel) {
      timedErrorTimer.timer.cancel();
      timers.remove(timedErrorTimer);
    }

    if (timers.isEmpty) {
      _timers.remove(key);
    }
  }

  void _removeTimer(E key, _TimedFieldErrorTimer timedErrorTimer) {
    final timers = _timers[key];
    if (timers == null) return;

    timers.remove(timedErrorTimer);

    if (timers.isEmpty) {
      _timers.remove(key);
    }
  }
}

class _TimedFieldErrorTimer {
  final String message;
  final Timer timer;

  const _TimedFieldErrorTimer({
    required this.message,
    required this.timer,
  });
}
