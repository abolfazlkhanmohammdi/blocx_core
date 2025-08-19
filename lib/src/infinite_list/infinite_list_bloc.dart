import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:blocx/src/core/base_bloc/base_bloc.dart';
import 'package:blocx/src/core/logger.dart';

part './infinite_list_bloc_event.dart';
part './infinite_list_bloc_state.dart';

class InfiniteListBloc extends Bloc<InfiniteListBlocEvent, InfiniteListBlocState> {
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

  InfiniteListBloc({this.refreshThreshold = 64.0}) : super(InfiniteListBlocStateInitial()) {
    on<InfiniteListBlocEventChangeLoadTopDataStatus>(_changeLoadTopDataStatus);
    on<InfiniteListBlocEventChangeLoadBottomDataStatus>(_changeLoadBottomDataStatus);
    on<InfiniteListBlocEventVerticalDragStarted>(_onDragStarted);
    on<InfiniteListBlocEventVerticalDragUpdated>(_onDragUpdated, transformer: restartable());
    on<InfiniteListBlocEventVerticalDragEnded>(_onDragEnded, transformer: restartable());
    on<InfiniteListBlocEventOnScroll>(_onScroll);
    on<InfiniteListBlocEventCloseRefresh>(_closeRefresh);
  }

  void _emitLoaded(Emitter<InfiniteListBlocState> emit) {
    emit(
      InfiniteListBlocStateLoaded(
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
    InfiniteListBlocEventChangeLoadTopDataStatus event,
    Emitter<InfiniteListBlocState> emit,
  ) {
    _isLoadingTopData = event.isLoading;
    _emitLoaded(emit);
  }

  void _changeLoadBottomDataStatus(
    InfiniteListBlocEventChangeLoadBottomDataStatus event,
    Emitter<InfiniteListBlocState> emit,
  ) {
    _isLoadingBottomData = event.isLoading;
    _hasReachedEnd = event.hasReachedEnd;
    _emitLoaded(emit);
  }

  void _onScroll(InfiniteListBlocEventOnScroll event, Emitter<InfiniteListBlocState> emit) {
    _isIdle = event.isIdle;
    if (!_isIdle) {
      _isAtTop = event.isAtTop;
      _isAtBottom = event.isAtBottom;
      _isScrollingUp = event.isScrollingUp;
    }
    logger.i(
      'onScroll → isAtTop: $_isAtTop, isAtBottom: $_isAtBottom, '
      'isScrollingUp: $_isScrollingUp, isIdle: $_isIdle',
    );
    _emitLoaded(emit);
  }

  void _onDragStarted(InfiniteListBlocEventVerticalDragStarted event, Emitter<InfiniteListBlocState> emit) {
    _dragStartY = event.globalY;
    _lastDragUpdateAt = null;
  }

  void _onDragUpdated(InfiniteListBlocEventVerticalDragUpdated event, Emitter<InfiniteListBlocState> emit) {
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

  void _onDragEnded(InfiniteListBlocEventVerticalDragEnded event, Emitter<InfiniteListBlocState> emit) {
    if (_isRefreshing) return;

    if (_swipeRefreshHeight >= refreshThreshold) {
      _isRefreshing = true;

      emit(
        InfiniteListBlocStateRefresh(
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
    add(InfiniteListBlocEventCloseRefresh());
  }

  void _closeRefresh(InfiniteListBlocEventCloseRefresh event, Emitter<InfiniteListBlocState> emit) {
    _isRefreshing = false;
    _swipeRefreshHeight = 0;
    _emitLoaded(emit);
  }

  // --------------------------------------------------------------------------
  // Public API helpers
  // --------------------------------------------------------------------------

  void setLoadingBottomStatus(bool status, [bool? hasReachedEnd]) {
    add(InfiniteListBlocEventChangeLoadBottomDataStatus(status, hasReachedEnd ?? _hasReachedEnd));
  }

  void setLoadingTopStatus(bool status) {
    add(InfiniteListBlocEventChangeLoadTopDataStatus(status));
  }
}
