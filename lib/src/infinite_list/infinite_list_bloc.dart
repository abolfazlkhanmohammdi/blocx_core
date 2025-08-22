import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx/src/core/base_bloc/base_bloc.dart';
import 'package:blocx/src/core/logger.dart';

part './infinite_list_bloc_event.dart';
part './infinite_list_bloc_state.dart';

class InfiniteListBloc extends Bloc<InfiniteListEvent, InfiniteListState> {
  /// --- Tunables -------------------------------------------------------------

  /// Pixel distance required to trigger a refresh.
  final double refreshThreshold;

  /// Throttle interval for drag update processing.
  static const Duration _dragUpdateMinInterval = Duration(milliseconds: 24);

  /// --- Internal state (private) --------------------------------------------

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

  DateTime? _lastDragUpdateAt;

  /// --- Public read-only accessors ------------------------------------------

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

  InfiniteListBloc({this.refreshThreshold = 64.0}) : super(InfiniteListStateInitial()) {
    on<InfiniteListEventChangeLoadTopDataStatus>(_changeLoadTopDataStatus);
    on<InfiniteListEventChangeLoadBottomDataStatus>(_changeLoadBottomDataStatus);
    on<InfiniteListEventVerticalDragStarted>(_onDragStarted);
    on<InfiniteListEventVerticalDragUpdated>(_onDragUpdated, transformer: restartable());
    on<InfiniteListEventVerticalDragEnded>(_onDragEnded, transformer: restartable());
    on<InfiniteListEventOnScroll>(_onScroll);
    on<InfiniteListEventCloseRefresh>(_closeRefresh);
    on<InfiniteListEventReachedEnd>(_reachedEnd);
  }

  void _emitLoaded(Emitter<InfiniteListState> emit) {
    emit(
      InfiniteListStateLoaded(
        isAtTop: _isAtTop,
        isScrollingUp: _isScrollingUp,
        isLoadingTop: _isLoadingTopData,
        isLoadingBottom: _isLoadingBottomData,
        isIdle: _isIdle,
        isRefreshing: _isRefreshing,
        isAtBottom: _isAtBottom,
        swipeRefreshHeight: _swipeRefreshHeight,
        hasReachedEnd: _hasReachedEnd,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Event handlers
  // --------------------------------------------------------------------------

  void _changeLoadTopDataStatus(
    InfiniteListEventChangeLoadTopDataStatus event,
    Emitter<InfiniteListState> emit,
  ) {
    _isLoadingTopData = event.isLoading;
    _emitLoaded(emit);
  }

  void _changeLoadBottomDataStatus(
    InfiniteListEventChangeLoadBottomDataStatus event,
    Emitter<InfiniteListState> emit,
  ) {
    _isLoadingBottomData = event.isLoading;
    _hasReachedEnd = event.hasReachedEnd;
    _emitLoaded(emit);
  }

  void _onScroll(InfiniteListEventOnScroll event, Emitter<InfiniteListState> emit) {
    _isIdle = event.isIdle;
    if (!_isIdle) {
      _isAtTop = event.isAtTop;
      _isAtBottom = event.isAtBottom;
      _isScrollingUp = event.isScrollingUp;
    }
    // logger.i(
    //   'onScroll → isAtTop: $_isAtTop, isAtBottom: $_isAtBottom, '
    //   'isScrollingUp: $_isScrollingUp, isIdle: $_isIdle',
    // );
    _emitLoaded(emit);
  }

  void _onDragStarted(InfiniteListEventVerticalDragStarted event, Emitter<InfiniteListState> emit) {
    _dragStartY = event.globalY;
    _lastDragUpdateAt = null;
  }

  void _onDragUpdated(InfiniteListEventVerticalDragUpdated event, Emitter<InfiniteListState> emit) {
    // Lightweight throttle to avoid excessive rebuilds
    final now = DateTime.now();
    if (_lastDragUpdateAt != null && now.difference(_lastDragUpdateAt!) < _dragUpdateMinInterval) {
      return;
    }
    _lastDragUpdateAt = now;

    // Only when pulling down from the top while scrolling up
    if (!_isAtTop || !_isScrollingUp) return;

    _dragUpdateY = event.globalY;

    if (_dragStartY == null || _dragUpdateY == null) {
      _swipeRefreshHeight = 0;
    } else {
      final delta = (_dragUpdateY! - _dragStartY!).abs();
      _swipeRefreshHeight = min(refreshThreshold, delta);
    }

    logger.d('dragUpdated → height=$_swipeRefreshHeight');
    _emitLoaded(emit);
  }

  void _onDragEnded(InfiniteListEventVerticalDragEnded event, Emitter<InfiniteListState> emit) {
    if (_isRefreshing) return;

    if (_swipeRefreshHeight >= refreshThreshold) {
      _isRefreshing = true;

      emit(
        InfiniteListStateRefresh(
          isAtTop: _isAtTop,
          isScrollingUp: _isScrollingUp,
          isLoadingTop: _isLoadingTopData,
          isLoadingBottom: _isLoadingBottomData,
          isIdle: _isIdle,
          isRefreshing: _isRefreshing,
          isAtBottom: _isAtBottom,
          swipeRefreshHeight: _swipeRefreshHeight,
          hasReachedEnd: _hasReachedEnd,
        ),
      );

      // Reset drag pointers; keep height as-is until UI hides it.
      _dragStartY = null;
      _dragUpdateY = null;
      _lastDragUpdateAt = null;
      return;
    }

    // No refresh → reset everything
    _dragStartY = null;
    _dragUpdateY = null;
    _lastDragUpdateAt = null;
    _swipeRefreshHeight = 0;
    _isRefreshing = false;

    _emitLoaded(emit);
  }

  void hideRefreshWidget() {
    add(InfiniteListEventCloseRefresh());
  }

  void _closeRefresh(InfiniteListEventCloseRefresh event, Emitter<InfiniteListState> emit) {
    _isRefreshing = false;
    _swipeRefreshHeight = 0;
    _isScrollingUp = false;
    _emitLoaded(emit);
  }

  // --------------------------------------------------------------------------
  // Public API helpers
  // --------------------------------------------------------------------------

  void setLoadingBottomStatus(bool status, [bool? hasReachedEnd]) {
    add(InfiniteListEventChangeLoadBottomDataStatus(status, hasReachedEnd ?? _hasReachedEnd));
  }

  void setLoadingTopStatus(bool status) {
    add(InfiniteListEventChangeLoadTopDataStatus(status));
  }

  FutureOr<void> _reachedEnd(InfiniteListEventReachedEnd event, Emitter<InfiniteListState> emit) {
    _hasReachedEnd = true;
    emit(
      InfiniteListStateLoaded(
        isAtTop: isAtTop,
        isIdle: isIdle,
        isLoadingBottom: false,
        isLoadingTop: _isLoadingTopData,
        isRefreshing: isRefreshing,
        isScrollingUp: isScrollingUp,
        isAtBottom: isAtBottom,
        swipeRefreshHeight: swipeRefreshHeight,
        hasReachedEnd: hasReachedEnd,
      ),
    );
  }
}
