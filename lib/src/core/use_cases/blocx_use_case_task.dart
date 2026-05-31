import 'package:blocx_core/blocx_core.dart' show BlocxBaseUseCase;
import 'package:blocx_core/src/blocs/list/use_cases/blocx_pagination_use_case.dart';

/// Signature for a function that builds a use case input at execution time.
typedef InputBuilder<I> = I Function();

/// Signature for a function that builds a [BlocxPaginationInput] subclass
/// given the current [limit] and [offset].
typedef PaginationInputBuilder<I extends BlocxPaginationInput> = I Function(int offset, int limit);

/// Pairs a [BlocxBaseUseCase] with a lazily evaluated [inputBuilder].
///
/// Input is constructed at execution time rather than registration time,
/// so it always reflects the latest runtime state (form values, bloc state, etc.).
///
/// ```dart
/// BlocxUseCaseTask(
///   useCase: getUserUseCase,
///   inputBuilder: () => GetUserInput(userId: state.selectedUserId),
/// );
/// ```
class BlocxUseCaseTask<UseCase extends BlocxBaseUseCase, Input> {
  /// The use case to execute.
  final UseCase useCase;

  /// Produces a fresh [Input] at execution time.
  final InputBuilder<Input> inputBuilder;

  /// Creates a [BlocxUseCaseTask].
  const BlocxUseCaseTask({required this.useCase, required this.inputBuilder});
}

/// Pairs a paginated [BlocxBaseUseCase] with a [PaginationInputBuilder] that
/// receives the current [limit] and [offset] at execution time.
///
/// This is the standard task type for [BlocxCollectionBloc.paginationTask].
///
/// ## Usage
///
/// ```dart
/// @override
/// BlocxPaginatedUseCaseTask get paginationTask => BlocxPaginatedUseCaseTask(
///   useCase: _getOrdersUseCase,
///   inputBuilder: ({required limit, required offset}) =>
///       BlocxPaginationInput(limit: limit, offset: offset),
/// );
/// ```
///
/// ## With extra input fields from bloc state
///
/// ```dart
/// @override
/// BlocxPaginatedUseCaseTask get paginationTask => BlocxPaginatedUseCaseTask(
///   useCase: _getOrdersUseCase,
///   inputBuilder: ({required limit, required offset}) => GetOrdersInput(
///     limit: limit,
///     offset: offset,
///     userId: payload!.id,
///     status: currentFilter,
///   ),
/// );
/// ```
///
/// ## Separate tasks per operation
///
/// If initial load, next-page, and refresh each hit different endpoints,
/// override [BlocxCollectionBloc.loadInitialPageTask] individually instead.
class BlocxPaginatedUseCaseTask<UseCase extends BlocxBaseUseCase, Input extends BlocxPaginationInput> {
  /// The paginated use case to execute.
  final UseCase useCase;

  /// Produces a fresh [Input] at execution time, receiving the current
  /// [limit] (page size) and [offset] (number of already-loaded items).
  ///
  /// Called once per load operation — initial, next-page, and refresh.
  final PaginationInputBuilder<Input> inputBuilder;

  /// Creates a [BlocxPaginatedUseCaseTask].
  const BlocxPaginatedUseCaseTask({required this.useCase, required this.inputBuilder});
}
