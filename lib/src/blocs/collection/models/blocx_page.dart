/// Represents a single paginated response page.
///
/// Contains the loaded [items], the requested [offset], and the requested
/// [limit] used to determine whether another page may exist.
class BlocxPage<T> {
  /// The items returned for this page.
  final List<T> items;

  /// The zero-based offset used when requesting this page.
  final int offset;

  /// The requested maximum number of items for this page.
  ///
  /// If [items] contains fewer elements than [limit], pagination is assumed
  /// to have reached the final page.
  final int limit;

  /// Optional opaque pagination cursor returned by the datasource for the
  /// next page of results.
  final String? nextCursor;

  final bool? _hasNext;

  /// Creates a paginated page result.
  const BlocxPage({
    required this.items,
    this.offset = 0,
    required this.limit,
    this.nextCursor,
    bool? hasNext,
  }) : _hasNext = hasNext;

  /// Whether another page may exist.
  ///
  /// Returns `true` if an explicit [hasNext] was passed, or if [nextCursor] is
  /// non-null and non-empty, or if the number of returned [items] equals [limit].
  bool get hasNext {
    if (_hasNext != null) return _hasNext;
    final cursor = nextCursor;
    if (cursor != null) return cursor.isNotEmpty;
    return limit == items.length;
  }
}
