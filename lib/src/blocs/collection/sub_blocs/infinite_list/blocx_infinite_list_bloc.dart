import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';

part './blocx_infinite_list_bloc_event.dart';
part './blocx_infinite_list_bloc_state.dart';

class BlocxInfiniteListBloc extends Bloc<BlocxInfiniteListEvent, BlocxInfiniteListState> {
  final double refreshThreshold;

  bool _isLoadingTopData = false;
  bool _isLoadingBottomData = false;
  bool _isRefreshing = false;
  bool _isScrollingUp = false;
  bool _isAtBottom = false;
  bool _isAtTop = true;
  bool _isIdle = true;

  double? _dragStartY;
  double? _dragUpdateY;
  double _swipeRefreshHeight = 0;
  bool _hasReachedEnd = false;

  bool get isLoadingTopData => _isLoadingTopData;
  bool get isLoadingBottomData => _isLoadingBottomData;
  bool get isRefreshing => _isRefreshing;
  bool get isScrollingUp => _isScrollingUp;
  bool get isAtBottom => _isAtBottom;
  bool get isAtTop => _isAtTop;
  bool get isIdle => _isIdle;
  double? get dragStartY => _dragStartY;
  double? get dragUpdateY => _dragUpdateY;
  double get swipeRefreshHeight => _swipeRefreshHeight;
  bool get hasReachedEnd => _hasReachedEnd;

  BlocxInfiniteListBloc({
    this.refreshThreshold = 64.0,
  })  : assert(
          refreshThreshold >= 0,
          'refreshThreshold must be greater than zero.',
        ),
        super(BlocxInfiniteListStateInitial()) {
    on<BlocxInfiniteListEventChangeLoadTopDataStatus>(
      _changeLoadTopDataStatus,
    );
    on<BlocxInfiniteListEventChangeLoadBottomDataStatus>(
      _changeLoadBottomDataStatus,
    );
    on<BlocxInfiniteListEventVerticalDragStarted>(
      _onDragStarted,
    );
    on<BlocxInfiniteListEventVerticalDragUpdated>(
      _onDragUpdated,
    );
    on<BlocxInfiniteListEventVerticalDragEnded>(
      _onDragEnded,
    );
    on<BlocxInfiniteListEventOnScroll>(
      _onScroll,
    );
    on<BlocxInfiniteListEventCloseRefresh>(
      _closeRefresh,
    );
    on<BlocxInfiniteListEventSetReachedEnd>(
      _setReachedEnd,
    );
  }

  void _emitLoaded(Emitter<BlocxInfiniteListState> emit) {
    emit(
      BlocxInfiniteListStateLoaded(
        isAtTop: _isAtTop,
        isScrollingUp: _isScrollingUp,
        isLoadingMore: _isLoadingBottomData,
        isIdle: _isIdle,
        isRefreshing: _isRefreshing,
        isAtBottom: _isAtBottom,
        swipeRefreshHeight: _swipeRefreshHeight,
        hasReachedEnd: _hasReachedEnd,
      ),
    );
  }

  void _changeLoadTopDataStatus(
    BlocxInfiniteListEventChangeLoadTopDataStatus event,
    Emitter<BlocxInfiniteListState> emit,
  ) {
    _isLoadingTopData = event.isLoading;
    _emitLoaded(emit);
  }

  void _changeLoadBottomDataStatus(
    BlocxInfiniteListEventChangeLoadBottomDataStatus event,
    Emitter<BlocxInfiniteListState> emit,
  ) {
    _isLoadingBottomData = event.isLoading;
    _hasReachedEnd = event.hasReachedEnd;

    _emitLoaded(emit);
  }

  void _onScroll(
    BlocxInfiniteListEventOnScroll event,
    Emitter<BlocxInfiniteListState> emit,
  ) {
    // Always synchronize edge information, including idle notifications.
    // Keeping previous values while idle can leave edge state stale.
    _isIdle = event.isIdle;
    _isAtTop = event.isAtTop;
    _isAtBottom = event.isAtBottom;
    _isScrollingUp = event.isScrollingUp;

    _emitLoaded(emit);
  }

  void _onDragStarted(
    BlocxInfiniteListEventVerticalDragStarted event,
    Emitter<BlocxInfiniteListState> emit,
  ) {
    if (_isRefreshing) {
      return;
    }

    _dragStartY = event.globalY;
    _dragUpdateY = event.globalY;
    _swipeRefreshHeight = 0;
  }

  void _onDragUpdated(
    BlocxInfiniteListEventVerticalDragUpdated event,
    Emitter<BlocxInfiniteListState> emit,
  ) {
    if (_isRefreshing) {
      return;
    }

    final currentY = event.globalY;

    if (currentY == null) {
      return;
    }

    final startY = _dragStartY;

    if (startY == null) {
      return;
    }

    _dragUpdateY = currentY;

    // The widget dispatches drag start only at the configured refresh edge
    // and normalizes movement in the wrong direction back to the start.
    final delta = (currentY - startY).abs();

    _swipeRefreshHeight = min(
      refreshThreshold,
      delta,
    );

    _emitLoaded(emit);
  }

  void _onDragEnded(
    BlocxInfiniteListEventVerticalDragEnded event,
    Emitter<BlocxInfiniteListState> emit,
  ) {
    if (_isRefreshing) {
      return;
    }

    final shouldRefresh = _dragStartY != null && _swipeRefreshHeight >= refreshThreshold;

    _dragStartY = null;
    _dragUpdateY = null;

    if (shouldRefresh) {
      _isRefreshing = true;

      emit(
        BlocxInfiniteListStateRefresh(
          isAtTop: _isAtTop,
          isScrollingUp: _isScrollingUp,
          isLoadingMore: _isLoadingBottomData,
          isIdle: _isIdle,
          isRefreshing: _isRefreshing,
          isAtBottom: _isAtBottom,
          swipeRefreshHeight: _swipeRefreshHeight,
          hasReachedEnd: _hasReachedEnd,
        ),
      );

      return;
    }

    _swipeRefreshHeight = 0;
    _isRefreshing = false;

    _emitLoaded(emit);
  }

  void hideRefreshWidget() {
    add(BlocxInfiniteListEventCloseRefresh());
  }

  void _closeRefresh(
    BlocxInfiniteListEventCloseRefresh event,
    Emitter<BlocxInfiniteListState> emit,
  ) {
    _isRefreshing = false;
    _swipeRefreshHeight = 0;
    _dragStartY = null;
    _dragUpdateY = null;

    // Scrolling direction is derived from scroll notifications and should not
    // be reset here, as doing so can block the next refresh gesture.
    _emitLoaded(emit);
  }

  void setLoadingBottomStatus(
    bool status, [
    bool? hasReachedEnd,
  ]) {
    add(
      BlocxInfiniteListEventChangeLoadBottomDataStatus(
        status,
        hasReachedEnd ?? _hasReachedEnd,
      ),
    );
  }

  void setLoadingTopStatus(bool status) {
    add(
      BlocxInfiniteListEventChangeLoadTopDataStatus(status),
    );
  }

  FutureOr<void> _setReachedEnd(
    BlocxInfiniteListEventSetReachedEnd event,
    Emitter<BlocxInfiniteListState> emit,
  ) {
    _hasReachedEnd = event.hasReachedEnd;
    _emitLoaded(emit);
  }
}
