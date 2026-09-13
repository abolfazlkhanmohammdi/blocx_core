import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

/// Refreshes the current list data, reloading from the source.
class BlocxCollectionEventRefreshData<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final bool clearSelection;
  BlocxCollectionEventRefreshData({this.clearSelection = false});
}
