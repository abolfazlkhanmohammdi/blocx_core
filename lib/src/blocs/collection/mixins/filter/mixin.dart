import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:blocx_core/src/blocs/collection/misc/event_transformers.dart';

mixin BlocxCollectionFilterMixin<
  Entity extends BlocxBaseEntity,
  Payload,
  Filter
>
    on BlocxCollectionBloc<Entity, Payload> {
  Filter? _filter;

  /// Debounce duration applied to filter changes.
  Duration get filterDebounceDuration => const Duration(milliseconds: 500);

  @override
  bool initFilters() {
    on<BlocxCollectionEventFilter<Entity, Filter>>(
      setFilter,
      transformer: debounceRestartable(filterDebounceDuration),
    );
    return true;
  }

  FutureOr<void> setFilter(
    BlocxCollectionEventFilter<Entity, Filter> event,
    Emitter<BlocxCollectionState<Entity>> emit,
  ) {
    _filter = event.filter;
    add(BlocxCollectionEventLoadInitialPage(payload: payload));
  }

  Filter? getFilter() => _filter;

  @override
  Object? get activeFilter => _filter;

  @override
  Map<String, dynamic> get activeFilters {
    final current = _filter;
    if (current is Map<String, dynamic>) {
      return Map<String, dynamic>.unmodifiable(current);
    }
    if (current is Map) {
      return Map<String, dynamic>.unmodifiable({
        for (final entry in current.entries) entry.key.toString(): entry.value,
      });
    }
    return const {};
  }
}
