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

  /// Creates a paginated page result.
  const BlocxPage({
    required this.items,
    required this.offset,
    required this.limit,
  });

  /// Whether another page may exist.
  ///
  /// Returns `true` when the number of returned [items] matches the requested
  /// [limit]. Returns `false` when fewer items were returned.
  bool get hasNext => limit == items.length;
}
