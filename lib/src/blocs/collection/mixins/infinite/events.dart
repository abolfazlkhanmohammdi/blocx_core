import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

/// Loads the next page of items and appends them to the list.
class BlocxCollectionEventLoadNextPage<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {}
