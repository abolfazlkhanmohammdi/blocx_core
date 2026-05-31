import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/list/models/page.dart';
import 'package:meta/meta.dart';

/// Pagination parameters passed to every paginated use case.
///
/// [limit] and [offset] follow standard cursor-style pagination:
/// - [limit] controls page size (how many items to fetch).
/// - [offset] is the index of the first item to fetch (i.e. how many
///   items have already been loaded).
///
/// Extend this class to attach additional filter or sort parameters:
/// ```dart
/// class SearchUsersInput extends BlocxPaginationInput {
///   final String query;
///   const SearchUsersInput({required this.query, required super.limit, required super.offset});
/// }
/// ```
class BlocxPaginationInput {
  /// Number of items to load per request.
  final int limit;

  /// Zero-based index of the first item to fetch.
  final int offset;

  const BlocxPaginationInput({required this.limit, required this.offset});
}

/// Base use case for paginated list operations.
///
/// Extend this instead of [BlocxBaseUseCase] whenever the output is a page
/// of [BlocxBaseEntity] items. It inherits full error handling from
/// [BlocxBaseUseCase] and adds [successResult] to eliminate the
/// [BlocxPage] construction boilerplate.
///
/// ## Minimal implementation
///
/// ```dart
/// class GetOrdersUseCase extends BlocxPaginationUseCase<BlocxPaginationInput, Order> {
///   final OrderRepository _repo;
///   GetOrdersUseCase(this._repo);
///
///   @override
///   Future<BlocxUseCaseResult<BlocxPage<Order>>> perform(BlocxPaginationInput input) async {
///     final orders = await _repo.getOrders(limit: input.limit, offset: input.offset);
///     return successResult(items: orders, input: input);
///   }
/// }
/// ```
///
/// ## Custom input
///
/// Pass a subclass of [BlocxPaginationInput] to attach filters or sorting:
/// ```dart
/// class GetFilteredOrdersUseCase
///     extends BlocxPaginationUseCase<OrderFilterInput, Order> { ... }
/// ```
abstract class BlocxPaginatedUseCase<Input extends BlocxPaginationInput, Output extends BlocxBaseEntity>
    extends BlocxBaseUseCase<Input, BlocxPage<Output>> {
  /// Builds a successful paginated result from [items] and the originating [input].
  ///
  /// Constructs [BlocxPage] with the correct [offset] and [loadCount], then
  /// wraps it in [BlocxUseCaseSuccess]. [BlocxPage.hasNext] is derived
  /// automatically from `loadCount == limit`.
  ///
  /// Call this at the end of [perform] instead of constructing
  /// [BlocxUseCaseSuccess] and [BlocxPage] manually:
  /// ```dart
  /// return successResult(items: orders, input: input);
  /// ```
  @protected
  BlocxUseCaseResult<BlocxPage<Output>> successResult({
    required List<Output> items,
    required BlocxPaginationInput input,
  }) =>
      success(
        BlocxPage(
          items: items,
          offset: input.offset,
          loadCount: items.length,
        ),
      );
}
