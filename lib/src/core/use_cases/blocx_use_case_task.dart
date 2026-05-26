import 'package:blocx_core/blocx_core.dart' show BlocxBaseUseCase;

/// Describes a deferred execution unit for a [BlocxBaseUseCase].
///
/// A [BlocxUseCaseTask] pairs a use case with a lazily evaluated input
/// builder, allowing the input to be constructed at execution time
/// rather than at registration time.
///
/// This is useful in scenarios where:
/// - Input depends on runtime state (e.g. Bloc state, form values)
/// - Multiple executions require fresh input instances
/// - Input must reflect the latest UI or application state
///
/// Type Parameters:
/// - [UseCase]: The use case type to execute
/// - [Input]: The input type required by the use case
///
/// Example usage:
/// ```dart
/// BlocxUseCaseTask(
///   useCase: getUserUseCase,
///   inputBuilder: () => GetUserInput(userId: state.selectedUserId),
/// );
/// ```
class BlocxUseCaseTask<UseCase extends BlocxBaseUseCase, Input> {
  /// The use case to be executed.
  final UseCase useCase;

  /// A function that produces the input at execution time.
  ///
  /// This ensures the input is always constructed with the latest
  /// available state rather than being cached or reused.
  final Input Function() inputBuilder;

  /// Creates a new [BlocxUseCaseTask].
  const BlocxUseCaseTask({required this.useCase, required this.inputBuilder});
}
