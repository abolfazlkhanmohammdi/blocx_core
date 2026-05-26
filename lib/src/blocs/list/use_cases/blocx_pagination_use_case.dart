import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/list/models/page.dart';
import 'package:meta/meta.dart';

/// Input model representing pagination parameters.
///
/// Used as the base contract for all paginated use cases.
///
/// Encapsulates:
/// - [loadCount]: number of items per page
/// - [offset]: starting index for pagination
class BlocxPaginationInput {
  /// Number of items to load per request.
  final int loadCount;

  /// Starting offset for pagination.
  final int offset;

  const BlocxPaginationInput({required this.loadCount, required this.offset});
}

/// Base use case for paginated operations.
///
/// Transforms a [BlocxPaginationInput] into a [BlocxPage] of [Output] entities.
///
/// Responsibilities:
/// - Enforces a consistent pagination contract
/// - Standardizes paginated result creation
/// - Reduces duplication across list-based use cases
///
/// Type Parameters:
/// - [Input]: Must extend [BlocxPaginationInput]
/// - [Output]: Must extend [BlocxBaseEntity]
abstract class BlocxPaginationUseCase<Input extends BlocxPaginationInput, Output extends BlocxBaseEntity>
    extends BlocxBaseUseCase<BlocxPaginationInput, BlocxPage<Output>> {
  /// Builds a successful paginated result.
  ///
  /// Ensures consistent propagation of pagination metadata:
  /// - offset
  /// - loadCount
  ///
  /// Should be used by all concrete implementations.
  @protected
  BlocxUseCaseResult<BlocxPage<Output>> successResult({
    required List<Output> items,
    required BlocxPaginationInput input,
  });
}
