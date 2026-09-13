import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/base/blocx_base_bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/blocx_form_bloc.dart';
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart';
import 'package:meta/meta.dart';

enum ErrorMutationSource {
  setTimedErrorToField,
  setErrorToField,
  clearFieldErrors,
  clearAllErrors,
  uniqueFieldValidatorMixinCheckUniqueValue,
  formValidationMixinApplyFieldValidationErrors,
}

enum _ErrorMutationType {
  add,
  addBulk,
  remove,
  clearField,
  clearAll,
}

/// Adds field-level error handling to a [BlocxFormBloc].
///
/// Stores errors by form field key and exposes them as immutable snapshots for
/// UI states. Supports normal persistent errors and temporary timed errors.
///
/// Timed errors are cleared by dispatching [BlocxFormEventClearFieldError]
/// after their duration expires. This avoids using an old [Emitter] after an
/// event handler has already completed.
mixin BlocxFormErrorsMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BlocxBaseBloc<BlocxFormEvent, BlocxFormState<F, E>> {
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
    _mutateErrors(
      source: ErrorMutationSource.setTimedErrorToField,
      type: _ErrorMutationType.add,
      key: event.key,
      error: event.message,
    );

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
    _mutateErrors(
      source: ErrorMutationSource.setErrorToField,
      type: _ErrorMutationType.add,
      key: event.key,
      error: event.message,
    );

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
      _mutateErrors(
        source: ErrorMutationSource.clearFieldErrors,
        type: _ErrorMutationType.clearField,
        key: event.key,
      );

      _cancelFieldTimers(event.key);
    } else {
      _mutateErrors(
        source: ErrorMutationSource.clearFieldErrors,
        type: _ErrorMutationType.remove,
        key: event.key,
        error: event.message!,
      );

      _cancelFieldTimers(
        event.key,
        errorMessage: event.message,
      );
    }

    emitState(emit);
  }

  /// Clears all field errors and cancels all pending timed-error timers.
  @protected
  void clearAllErrors({ErrorMutationSource? source}) {
    _mutateErrors(
      source: source ?? ErrorMutationSource.clearAllErrors,
      type: _ErrorMutationType.clearAll,
    );

    clearTimers();
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

  bool setFieldError(
    E key,
    String error, {
    required ErrorMutationSource source,
  }) {
    return _mutateErrors(
      source: source,
      type: _ErrorMutationType.add,
      key: key,
      error: error,
    );
  }

  bool clearFieldError(
    E key, {
    required ErrorMutationSource source,
    String? errorMessage,
  }) {
    return _mutateErrors(
      source: source,
      type: errorMessage == null ? _ErrorMutationType.clearField : _ErrorMutationType.remove,
      key: key,
      error: errorMessage,
    );
  }

  bool _mutateErrors({
    required ErrorMutationSource source,
    required _ErrorMutationType type,
    E? key,
    String? error,
    Iterable<String>? errors,
  }) {
    // assert(() {
    //   logger.d(
    //     'Form error mutation: '
    //     'source=$source, '
    //     'type=$type, '
    //     'key=$key, '
    //     'error=$error, '
    //     'errors=${errors?.toList()}',
    //   );
    //
    //   return true;
    // }());

    switch (type) {
      case _ErrorMutationType.add:
        final set = _errors.putIfAbsent(key!, () => <String>{});
        final changed = set.add(error!);

        _pruneFieldIfEmpty(key);

        return changed;

      case _ErrorMutationType.addBulk:
        final set = _errors.putIfAbsent(key!, () => <String>{});
        final before = set.length;

        set.addAll(errors!);

        _pruneFieldIfEmpty(key);

        return set.length != before;

      case _ErrorMutationType.remove:
        final set = _errors[key!];
        if (set == null) return false;

        final changed = set.remove(error);

        _pruneFieldIfEmpty(key);

        return changed;

      case _ErrorMutationType.clearField:
        return _errors.remove(key!) != null;

      case _ErrorMutationType.clearAll:
        final changed = _errors.isNotEmpty;

        _errors.clear();

        return changed;
    }
  }

  void _pruneFieldIfEmpty(E key) {
    final set = _errors[key];

    if (set != null && set.isEmpty) {
      _errors.remove(key);
    }
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
