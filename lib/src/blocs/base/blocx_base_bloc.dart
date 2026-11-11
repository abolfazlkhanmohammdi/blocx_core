import 'dart:async';
import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/base/error_translator.dart';
import 'package:blocx_core/src/blocs/base/readable_error.dart';
import 'package:blocx_core/src/blocs/screen_manager/screen_manager_cubit.dart';
import 'package:blocx_core/src/core/enum_error_codes.dart';
import 'package:blocx_core/src/core/localizations/blocx_localizations.dart';
import 'package:meta/meta.dart';

part 'blocx_base_event.dart';
part 'blocx_base_state.dart';

/// Base class for all blocs in the blocx ecosystem.
///
/// Owns and manages a [ScreenManagerCubit] internally — consumers no longer
/// need to construct or pass one. Simply call `super(initialState)`:
///
/// ```dart
/// class CounterBloc extends BaseBloc<CounterEvent, CounterState> {
///   CounterBloc() : super(CounterStateInitial());
/// }
/// ```
///
/// ## Error handling
///
/// Call [handleError] from event handlers to log and surface errors via the
/// configured [errorDisplayPolicy] (snackbar by default):
///
/// ```dart
/// } catch (e, st) {
///   handleError(e, emit, stacktrace: st);
/// }
/// ```
///
/// Override [reportError] to forward unhandled errors to crash reporting services
/// such as Sentry or Firebase Crashlytics.
///
/// To display a full-page error instead, override [errorDisplayPolicy]:
/// ```dart
/// @override
/// ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.page;
/// ```
///
/// ## Navigation
///
/// Call [pop] to trigger a back-navigation signal through [ScreenManagerCubit].
///
/// ## Customising error presentation
///
/// Register a [BlocxErrorTranslator] once at app startup to map raw exceptions
/// to human-readable [ReadableError] instances. Blocs pick it up automatically.
/// Alternatively, pass an [errorTranslator] and [localizations] directly to the
/// bloc constructor for dependency injection.
abstract class BlocxBaseBloc<E extends BlocxBaseEvent, S extends BlocxBaseState>
    extends Bloc<E, S> {
  /// Internal screen-manager instance. Created once per bloc, closed on [close].
  final ScreenManagerCubit _screenManagerCubit = ScreenManagerCubit();
  final BlocxErrorTranslator? _injectedErrorTranslator;
  final BlocXLocalizations? _injectedLocalizations;

  /// Creates a [BlocxBaseBloc] with the given [initialState].
  ///
  /// Optionally accepts an [errorTranslator] and [localizations] for per-bloc
  /// configuration or testing. When omitted, falls back to the static defaults.
  BlocxBaseBloc(
    super.initialState, {
    BlocxErrorTranslator? errorTranslator,
    BlocXLocalizations? localizations,
  }) : _injectedErrorTranslator = errorTranslator,
       _injectedLocalizations = localizations;

  /// The error translator used by this bloc to translate errors to [ReadableError]s.
  ///
  /// Defaults to the injected [errorTranslator] if provided in constructor,
  /// or falls back to the static [BlocxErrorTranslator.instance].
  BlocxErrorTranslator? get errorTranslator =>
      _injectedErrorTranslator ?? BlocxErrorTranslator.instance;

  /// The localizations used by this bloc.
  ///
  /// Defaults to the injected [localizations] if provided in constructor,
  /// or falls back to [BlocXLocalizations.localizations].
  BlocXLocalizations get localizations =>
      _injectedLocalizations ?? BlocXLocalizations.localizations;

  /// Shorthand alias for [localizations].
  BlocXLocalizations get loc => localizations;

  /// Triggers a pop/back-navigation signal.
  void pop() => _screenManagerCubit.pop();

  /// Clears any currently displayed full-page error, resetting the screen manager to its initial state.
  void clearError() => _screenManagerCubit.clearError();

  /// Displays a full-page error widget for [error].
  void displayErrorWidget(ReadableError error) =>
      _screenManagerCubit.displayErrorWidget(error);

  /// Displays a full-page error widget derived from a [BlocXErrorCode].
  void displayErrorWidgetByErrorCode(
    BlocXErrorCode errorCode, {
    Object? error,
    StackTrace? stackTrace,
  }) => _screenManagerCubit.displayErrorWidgetByErrorCode(
    errorCode,
    error: error,
    st: stackTrace,
  );

  /// Displays a warning snackbar with [message] and optional [title].
  void displayWarningSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(
        message,
        BlocXSnackbarType.warning,
        title: title,
      );

  /// Displays an error snackbar with [message] and optional [title].
  void displayErrorSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(
        message,
        BlocXSnackbarType.error,
        title: title,
      );

  /// Displays an info snackbar with [message] and optional [title].
  void displayInfoSnackbar(String message, {String? title}) =>
      _screenManagerCubit.displaySnackbar(
        message,
        BlocXSnackbarType.info,
        title: title,
      );

  /// Translates [error] to a [ReadableError] using [errorTranslator] or [defaultError].
  ReadableError readableErrorOf(Object error, {StackTrace? stacktrace}) {
    return errorTranslator?.makeErrorReadable(error, stackTrace: stacktrace) ??
        defaultError;
  }

  /// Hook for logging or reporting errors to external monitoring services (e.g., Sentry, Firebase Crashlytics).
  ///
  /// Override this in subclasses or app-level base blocs to forward unhandled errors
  /// and stack traces to your crash reporting service. By default, logs the error
  /// and stack trace to `dart:developer`.
  void reportError(Object error, StackTrace? stackTrace) {
    dev.log(error.toString());
    if (stackTrace != null) dev.log(stackTrace.toString());
  }

  ErrorDisplayPolicy? _overrideErrorDisplayPolicy;

  /// Logs [error], translates it to a [ReadableError], then surfaces it
  /// according to [errorDisplayPolicy].
  ///
  /// Call this inside event handlers whenever an exception needs to be shown
  /// to the user. [stacktrace] is optional but improves log quality.
  FutureOr<void> handleError(
    Object error,
    Emitter<BlocxBaseState> emit, {
    StackTrace? stacktrace,
  }) {
    reportError(error, stacktrace);
    final readableError = readableErrorOf(error, stacktrace: stacktrace);
    final effectivePolicy = _overrideErrorDisplayPolicy ?? errorDisplayPolicy;
    switch (effectivePolicy) {
      case ErrorDisplayPolicy.snackBar:
        displayErrorSnackbar(readableError.message, title: readableError.title);
      case ErrorDisplayPolicy.page:
        displayErrorWidget(readableError);
      case ErrorDisplayPolicy.none:
        break;
    }
  }

  /// Calls [handleError] with a temporary [displayPolicy] override so
  /// error reporting and translation still run while routing UI feedback
  /// per operation (for example [ErrorDisplayPolicy.none] for inline errors).
  @protected
  Future<void> handleErrorWithPolicy(
    Object error,
    Emitter<BlocxBaseState> emit, {
    StackTrace? stacktrace,
    required ErrorDisplayPolicy displayPolicy,
  }) async {
    final previousPolicy = _overrideErrorDisplayPolicy;
    _overrideErrorDisplayPolicy = displayPolicy;
    try {
      await handleError(error, emit, stacktrace: stacktrace);
    } finally {
      _overrideErrorDisplayPolicy = previousPolicy;
    }
  }

  /// Controls how errors are surfaced to the user.
  ///
  /// Defaults to [ErrorDisplayPolicy.snackBar]. Override to use
  /// [ErrorDisplayPolicy.page] for full-screen error states or
  /// [ErrorDisplayPolicy.none] when errors are rendered inline by state.
  ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.snackBar;

  /// Closes the internal [ScreenManagerCubit] before closing the bloc itself.
  @override
  @mustCallSuper
  Future<void> close() async {
    await _screenManagerCubit.close();
    return super.close();
  }

  /// Direct access to the internal [ScreenManagerCubit].
  ///
  /// Prefer the named helpers ([pop], [displayErrorSnackbar], etc.) over
  /// accessing this directly.
  ScreenManagerCubit get screenManagerCubit => _screenManagerCubit;

  /// The fallback [ReadableError] used when no [BlocxErrorTranslator] is
  /// registered or when the translator does not recognise the error.
  ReadableError get defaultError =>
      ReadableError(message: loc.somethingWentWrong);
}

/// Controls where errors are displayed after [BlocxBaseBloc.handleError] is called.
enum ErrorDisplayPolicy {
  /// Show a non-blocking snackbar at the bottom of the screen.
  snackBar,

  /// Replace the current screen with a full-page error widget.
  page,

  /// Report and translate the error without emitting a [ScreenManagerCubit]
  /// snackbar or error page (used for inline state-driven error recovery).
  none,
}
