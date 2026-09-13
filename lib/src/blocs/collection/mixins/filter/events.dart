import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

class BlocxCollectionEventFilter<T extends BlocxBaseEntity, Filter> extends BlocxCollectionEvent<T> {
  final Filter filter;
  BlocxCollectionEventFilter({required this.filter});
}
