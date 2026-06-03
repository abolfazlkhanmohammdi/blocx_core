import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart';

/// Input model for search + pagination use cases.
///
/// Extends [BlocxPaginatedInput] by adding a search constraint.
///
/// Used in use cases that combine:
/// - pagination (loadCount, offset)
/// - search filtering (searchText)
class BlocxSearchInput extends BlocxPaginatedInput {
  /// Raw search query string used to filter results.
  final String searchText;

  const BlocxSearchInput({required this.searchText, required super.limit, required super.offset});
}

/// Base class for paginated search use cases.
///
/// Extends [BlocxPaginatedUseCase] to support search-enabled queries.
///
/// Key constraints:
/// - [Input] must extend [BlocxSearchInput]
/// - Requires runtime cast via [asSearchInput] due to Dart override rules
/// - Concrete implementations must handle search filtering logic
///
/// This preserves compatibility with the pagination system while
/// enabling search-specific behavior.
abstract class BlocxSearchUseCase<Input extends BlocxSearchInput, Output extends BlocxBaseEntity>
    extends BlocxPaginatedUseCase<Input, Output> {}
