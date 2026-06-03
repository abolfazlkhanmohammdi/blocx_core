import 'package:blocx_core/blocx_core.dart' show BlocxBaseEntity, BlocxBaseUseCase, BlocxUseCaseResult;
import 'package:blocx_core/src/blocs/list/models/page.dart';
import 'package:blocx_core/src/blocs/list/use_cases/blocx_paginated_use_case.dart';

/// Signature for a function that builds a use case input at execution time.
typedef InputBuilder<Input> = Input Function();

/// Signature for a function that builds a paginated use case input.
typedef PaginatedInputBuilder<Input extends BlocxPaginatedInput> = Input Function(
  int offset,
  int limit,
);

/// Pairs a [BlocxBaseUseCase] with a lazily evaluated input builder.
///
/// [Input] is the input type accepted by the use case.
/// [Output] is the output type returned by the use case.
///
/// Input is constructed at execution time rather than registration time, so it
/// always reflects the latest runtime state, such as current form values.
class BlocxUseCaseTask<Input, Output> {
  /// The use case to execute.
  final BlocxBaseUseCase<Input, Output> useCase;

  /// Produces a fresh [Input] at execution time.
  final InputBuilder<Input> inputBuilder;

  /// Creates a use case task.
  const BlocxUseCaseTask({
    required this.useCase,
    required this.inputBuilder,
  });

  /// Executes [useCase] using the latest value from [inputBuilder].
  Future<BlocxUseCaseResult<Output>> execute() {
    return useCase.execute(inputBuilder());
  }
}

/// Pairs a [BlocxPaginatedUseCase] with a lazily evaluated paginated input.
///
/// [Input] is the paginated input type accepted by the use case.
/// [Output] is the list item entity type returned inside [BlocxPage].
///
/// This task is used by collection mixins for initial load, next-page loading,
/// refresh, and search.
class BlocxPaginatedUseCaseTask<Input extends BlocxPaginatedInput, Output extends BlocxBaseEntity> {
  /// The paginated use case to execute.
  final BlocxPaginatedUseCase<Input, Output> useCase;

  /// Produces a fresh [Input] from the requested [offset] and [limit].
  final PaginatedInputBuilder<Input> inputBuilder;

  /// Creates a paginated use case task.
  const BlocxPaginatedUseCaseTask({
    required this.useCase,
    required this.inputBuilder,
  });

  /// Executes [useCase] using an input built from [offset] and [limit].
  Future<BlocxUseCaseResult<BlocxPage<Output>>> execute({
    required int offset,
    required int limit,
  }) {
    return useCase.execute(inputBuilder(offset, limit));
  }
}
