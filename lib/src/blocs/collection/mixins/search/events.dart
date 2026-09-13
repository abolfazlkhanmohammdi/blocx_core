import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

/// Runs a search query against the list’s backing source.
///
/// [searchText] contains the query string.
class BlocxCollectionEventSearch<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  /// The text to search for.
  final String searchText;

  BlocxCollectionEventSearch({required this.searchText});
}

/// Loads the next page of search results.
class BlocxCollectionEventSearchNextPage<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {}

/// Refreshes the current search results.
class BlocxCollectionEventSearchRefresh<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {}

/// Clears the current search results and restores the base list.
class BlocxCollectionEventClearSearch<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {}
