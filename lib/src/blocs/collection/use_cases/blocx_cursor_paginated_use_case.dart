import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/collection/models/blocx_page.dart';
import 'package:meta/meta.dart';

/// Cursor-based pagination parameters passed to cursor-paginated use cases.
class BlocxCursorPaginatedInput<Filter> {
  /// Number of items to load per request.
  final int limit;

  /// Optional opaque cursor indicating the start of the page to fetch.
  final String? cursor;

  /// Optional filter criteria for the request.
  final Filter? filter;

  const BlocxCursorPaginatedInput({
    required this.limit,
    this.cursor,
    this.filter,
  });
}

/// Base use case for cursor-paginated list operations.
abstract class BlocxCursorPaginatedUseCase<
  Input extends BlocxCursorPaginatedInput,
  Output extends BlocxBaseEntity
>
    extends BlocxBaseUseCase<Input, BlocxPage<Output>> {
  const BlocxCursorPaginatedUseCase({
    super.eventHub,
    super.commandType,
    super.commandTypes,
  });

  /// Builds a successful cursor-paginated result from [items] and the originating [input].
  @protected
  BlocxUseCaseResult<BlocxPage<Output>> successResult({
    required List<Output> items,
    required BlocxCursorPaginatedInput input,
    String? nextCursor,
    bool? hasNext,
  }) => success(
    BlocxPage(
      items: items,
      limit: input.limit,
      nextCursor: nextCursor,
      hasNext: hasNext,
    ),
  );
}
