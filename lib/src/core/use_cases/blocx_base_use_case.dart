import 'dart:async';

import 'package:blocx_core/src/blocs/base/mixins/blocx_app_event.dart';
import 'package:blocx_core/src/blocs/base/mixins/blocx_event_bus.dart';
import 'package:blocx_core/src/blocs/collection/models/blocx_page.dart';
import 'package:blocx_core/src/core/models/base_entity.dart';
import 'package:blocx_core/src/core/use_cases/blocx_use_case_result.dart';
import 'package:meta/meta.dart';

/// Base abstraction for all use cases.
///
/// A use case encapsulates a single unit of business logic that transforms
/// an [Input] into an [Output]. All execution goes through [execute], which
/// catches exceptions and converts them into [BlocxUseCaseFailure] automatically.
///
/// ## Implementing a use case
///
/// Only [perform] is required. Use the [success] helper to wrap your output:
///
/// ```dart
/// class GetUserUseCase extends BlocxBaseUseCase<String, User> {
///   final UserRepository _repo;
///   GetUserUseCase(this._repo);
///
///   @override
///   Future<BlocxUseCaseResult<User>> perform(String userId) async {
///     final user = await _repo.getUser(userId);
///     return success(user);
///   }
/// }
/// ```
///
/// ## Broadcasting Entity Commands
///
/// Inject a [BlocxEventHub] and specify [commandType] (or [commandTypes]) to
/// automatically broadcast [BlocxEntityEvent]s when [execute] succeeds:
///
/// ```dart
/// class UpdateUserUseCase extends BlocxBaseUseCase<UpdateUserInput, User> {
///   final UserRepository _repo;
///
///   UpdateUserUseCase(this._repo, BlocxEventHub eventHub)
///       : super(eventHub: eventHub, commandType: BlocxCommandType.update);
///
///   @override
///   Future<BlocxUseCaseResult<User>> perform(UpdateUserInput input) async {
///     final user = await _repo.updateUser(input);
///     return success(user);
///   }
/// }
/// ```
///
/// ## Custom failure mapping
///
/// Override [failureResult] to map low-level errors to domain types before
/// they reach the bloc:
///
/// ```dart
/// @override
/// BlocxUseCaseResult<User> failureResult(Object error, StackTrace st) {
///   if (error is NetworkException) return BlocxUseCaseFailure(AppError.network, st);
///   return BlocxUseCaseFailure(AppError.unknown, st);
/// }
/// ```
///
/// ## Logging / analytics
///
/// Override [handleError] for side-effects (crash reporting, analytics).
/// It must not affect control flow — [failureResult] is still called after it.
abstract class BlocxBaseUseCase<Input, Output> {
  final BlocxEventHub? _eventHub;
  final BlocxCommandType? _commandType;
  final List<BlocxCommandType>? _commandTypes;

  /// Creates a [BlocxBaseUseCase].
  ///
  /// Optionally provide [eventHub] and [commandType] (or [commandTypes]) to
  /// broadcast entity changes automatically upon successful execution.
  const BlocxBaseUseCase({
    BlocxEventHub? eventHub,
    BlocxCommandType? commandType,
    List<BlocxCommandType>? commandTypes,
  })  : _eventHub = eventHub,
        _commandType = commandType,
        _commandTypes = commandTypes;

  /// The [BlocxEventHub] used to broadcast entity command events when
  /// [commandType] or [commandTypes] is configured.
  BlocxEventHub? get eventHub => _eventHub;

  /// Optional single CRUD command type executed by this use case.
  BlocxCommandType? get commandType => _commandType;

  /// List of CRUD command types executed by this use case.
  ///
  /// Defaults to `[commandType!]` when [commandType] is non-null, or empty.
  List<BlocxCommandType> get commandTypes {
    if (_commandTypes != null) return _commandTypes;
    final single = commandType;
    return single != null
        ? <BlocxCommandType>[single]
        : const <BlocxCommandType>[];
  }

  /// Optional origin metadata attached to emitted [BlocxEntityEvent]s.
  @protected
  BlocxEventOrigin? get eventOrigin => null;

  /// Entry point for callers. Do not override.
  ///
  /// Calls [perform] inside a try/catch. On exception:
  /// 1. [handleError] is called for logging side-effects.
  /// 2. [failureResult] wraps the error and is returned.
  @nonVirtual
  Future<BlocxUseCaseResult<Output>> execute(Input input) async {
    try {
      final result = await perform(input);
      if (result.isSuccess) {
        _broadcastCommandEventsIfNeeded(input, result.data as Output);
      }
      return result;
    } catch (error, stackTrace) {
      handleError(error, stackTrace);
      return failureResult(error, stackTrace);
    }
  }

  void _broadcastCommandEventsIfNeeded(Input input, Output output) {
    final hub = eventHub;
    final commands = commandTypes;
    if (hub == null || commands.isEmpty) return;
    if (!shouldBroadcastCommandResult(input, output)) return;

    final entities = resolveCommandEntities(input, output);
    if (entities.isEmpty) return;

    for (final command in commands) {
      hub.emitEntities(
        entities,
        command,
        origin: eventOrigin,
      );
    }
  }

  /// Whether a successful [output] should trigger command event broadcasting.
  ///
  /// By default, returns `false` when [output] is `bool` and `false` (e.g. a
  /// delete or update operation that returned `false`), and `true` otherwise.
  @protected
  bool shouldBroadcastCommandResult(Input input, Output output) {
    if (output is bool) return output;
    return true;
  }

  /// Resolves the affected [BlocxBaseEntity] instances from [input] and [output]
  /// to broadcast to [eventHub].
  ///
  /// Default resolution order:
  /// 1. If [output] is a [BlocxBaseEntity], returns `[output]`.
  /// 2. If [output] is a [BlocxPage], returns its items.
  /// 3. If [output] is an [Iterable], returns any [BlocxBaseEntity] elements.
  /// 4. If [input] is a [BlocxBaseEntity] (common for delete use cases where
  ///    [Output] is `bool`), returns `[input]`.
  /// 5. If [input] is an [Iterable] (common for bulk delete use cases), returns
  ///    any [BlocxBaseEntity] elements.
  ///
  /// Override this when your use case uses a custom input/output wrapper.
  @protected
  List<BlocxBaseEntity> resolveCommandEntities(Input input, Output output) {
    if (output is BlocxBaseEntity) {
      return <BlocxBaseEntity>[output];
    }
    if (output is BlocxPage) {
      return output.items.whereType<BlocxBaseEntity>().toList();
    }
    if (output is Iterable) {
      final list = output.whereType<BlocxBaseEntity>().toList();
      if (list.isNotEmpty) return list;
    }
    if (input is BlocxBaseEntity) {
      return <BlocxBaseEntity>[input];
    }
    if (input is Iterable) {
      return input.whereType<BlocxBaseEntity>().toList();
    }
    return const <BlocxBaseEntity>[];
  }

  /// The business logic implementation.
  ///
  /// Called by [execute]. Throw freely — exceptions are caught and
  /// converted to [BlocxUseCaseFailure] automatically.
  ///
  /// Return values via [success]:
  /// ```dart
  /// return success(myOutput);
  /// ```
  @protected
  Future<BlocxUseCaseResult<Output>> perform(Input input);

  /// Optional side-effect hook for logging, analytics, or crash reporting.
  ///
  /// Called before [failureResult] on every unhandled exception.
  /// Must not throw or affect control flow.
  void handleError(Object error, StackTrace stackTrace) {}

  /// Shorthand for `BlocxUseCaseSuccess(data)`.
  ///
  /// Use inside [perform] to keep return statements readable:
  /// ```dart
  /// return success(user);
  /// ```
  @protected
  BlocxUseCaseResult<Output> success(Output data) => BlocxUseCaseSuccess(data);

  /// Wraps an unhandled exception into a [BlocxUseCaseResult].
  ///
  /// The default returns `BlocxUseCaseFailure(error, stackTrace)`.
  /// Override to map exceptions to domain-specific error types before the
  /// result reaches the bloc layer.
  @protected
  FutureOr<BlocxUseCaseResult<Output>> failureResult(
    Object error,
    StackTrace stackTrace,
  ) =>
      BlocxUseCaseFailure<Output>(error, stackTrace);
}
