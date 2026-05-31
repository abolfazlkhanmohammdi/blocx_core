import 'dart:async';
import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/base/error_translator.dart';
import 'package:blocx_core/src/blocs/base/readable_error.dart';
import 'package:blocx_core/src/blocs/screen_manager/screen_manager_cubit.dart';
import 'package:blocx_core/src/core/enum_error_codes.dart';
import 'package:blocx_core/src/core/localizations/loc_provider.dart';
import 'package:meta/meta.dart';

part 'base_bloc_event.dart';
part 'base_bloc_state.dart';

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
abstract class BaseBloc<E extends BaseEvent, S extends BaseState> extends Bloc<E, S> {
  /// Internal screen-manager instance. Created once per bloc, closed on [close].
  final ScreenManagerCubit _screenManagerCubit = ScreenManagerCubit();

  /// Creates a [BaseBloc] with the given [initialState].
  ///
  /// No external dependencies required — [ScreenManagerCubit] is managed
  /// internally.
  BaseBloc(super.initialState);

  /// Triggers a pop/back-navigation signal.
  void pop() => _screenManagerCubit.pop();

  /// Displays a full-page error widget for [error].
  void displayErrorWidget(ReadableError error) => _screenManagerCubit.displayErrorWidget(error);

  /// Displays a full-page error widget derived from a [BlocXErrorCode].
  void displayErrorWidgetByErrorCode(
    BlocXErrorCode errorCode, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _screenManagerCubit.displayErrorWidgetByErrorCode(
        errorCode,
        error: error,
        st: stackTrace,
      );

  /// Displays a warning snackbar with [message] and optional [title].
  void displayWarningSnackbar(String message, {String? title}) => _screenManagerCubit.displaySnackbar(
        message,
        BlocXSnackbarType.warning,
        title: title,
      );

  /// Displays an error snackbar with [message] and optional [title].
  void displayErrorSnackbar(String message, {String? title}) => _screenManagerCubit.displaySnackbar(
        message,
        BlocXSnackbarType.error,
        title: title,
      );

  /// Displays an info snackbar with [message] and optional [title].
  void displayInfoSnackbar(String message, {String? title}) => _screenManagerCubit.displaySnackbar(
        message,
        BlocXSnackbarType.info,
        title: title,
      );

  /// Logs [error], translates it to a [ReadableError], then surfaces it
  /// according to [errorDisplayPolicy].
  ///
  /// Call this inside event handlers whenever an exception needs to be shown
  /// to the user. [stacktrace] is optional but improves log quality.
  FutureOr<void> handleError(
    Object error,
    Emitter<BaseState> emit, {
    StackTrace? stacktrace,
  }) {
    dev.log(error.toString());
    if (stacktrace != null) dev.log(stacktrace.toString());
    final readableError = errorTranslator?.makeErrorReadable(error, stackTrace: stacktrace) ?? defaultError;
    if (errorDisplayPolicy == ErrorDisplayPolicy.snackBar) {
      displayErrorSnackbar(readableError.message, title: readableError.title);
    } else {
      displayErrorWidget(readableError);
    }
  }

  /// Controls how errors are surfaced to the user.
  ///
  /// Defaults to [ErrorDisplayPolicy.snackBar]. Override to use
  /// [ErrorDisplayPolicy.page] for full-screen error states.
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
  ReadableError get defaultError => ReadableError(message: loc.somethingWentWrong);
}

/// Controls where errors are displayed after [BaseBloc.handleError] is called.
enum ErrorDisplayPolicy {
  /// Show a non-blocking snackbar at the bottom of the screen.
  snackBar,

  /// Replace the current screen with a full-page error widget.
  page,
}
