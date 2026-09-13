import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:blocx_core/src/blocs/collection/misc/event_transformers.dart';

mixin BlocxCollectionFilterMixin<Entity extends BlocxBaseEntity, Payload, Filter>
    on BlocxCollectionBloc<Entity, Payload> {
  Filter? _filter;

  @override
  bool initFilters() {
    on<BlocxCollectionEventFilter<Entity, Filter>>(setFilter,
        transformer: debounceRestartable(Duration(milliseconds: 500)));
    return true;
  }

  FutureOr<void> setFilter(
      BlocxCollectionEventFilter<Entity, Filter> event, Emitter<BlocxCollectionState<Entity>> emit) {
    _filter = event.filter;
    add(BlocxCollectionEventLoadInitialPage(payload: payload));
  }

  Filter? getFilter() => _filter;
}
