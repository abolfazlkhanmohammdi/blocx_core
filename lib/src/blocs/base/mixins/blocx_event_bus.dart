import 'dart:async';

import 'package:blocx_core/src/core/models/base_entity.dart';

import 'blocx_app_event.dart'
    show BlocxAppEvent, BlocxCommandType, BlocxEntityEvent, BlocxEventOrigin;

abstract class BlocxEventHub {
  void emit(BlocxAppEvent event);

  /// Emits a single-entity command event.
  void emitEntity<T extends BlocxBaseEntity>(
    T entity,
    BlocxCommandType command, {
    BlocxEventOrigin? origin,
  });

  /// Emits a multi-entity command event.
  void emitEntities<T extends BlocxBaseEntity>(
    List<T> entities,
    BlocxCommandType command, {
    BlocxEventOrigin? origin,
  });

  Stream<BlocxAppEvent> stream();
  Stream<T> ofType<T extends BlocxAppEvent>();

  /// Returns a stream of [BlocxEntityEvent] matching entity type [T] and
  /// optional [commands] filter.
  Stream<BlocxEntityEvent<T>> onEntity<T extends BlocxBaseEntity>({
    Iterable<BlocxCommandType>? commands,
  });

  void dispose();
}

class BlocxSimpleEventHub implements BlocxEventHub {
  final StreamController<BlocxAppEvent> _controller =
      StreamController<BlocxAppEvent>.broadcast();

  @override
  Stream<BlocxAppEvent> stream() => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Stream<T> ofType<T extends BlocxAppEvent>() =>
      _controller.stream.where((e) => e is T).cast<T>();

  @override
  void emit(BlocxAppEvent event) {
    if (!_controller.isClosed) {
      event.debugTrace = StackTrace.current;
      _controller.add(event);
    }
  }

  @override
  void emitEntity<T extends BlocxBaseEntity>(
    T entity,
    BlocxCommandType command, {
    BlocxEventOrigin? origin,
  }) {
    emit(
      BlocxEntityEvent<T>.single(
        entity: entity,
        command: command,
        origin: origin,
      ),
    );
  }

  @override
  void emitEntities<T extends BlocxBaseEntity>(
    List<T> entities,
    BlocxCommandType command, {
    BlocxEventOrigin? origin,
  }) {
    if (entities.isEmpty) return;
    emit(
      BlocxEntityEvent<T>(
        entities: entities,
        command: command,
        origin: origin,
      ),
    );
  }

  @override
  Stream<BlocxEntityEvent<T>> onEntity<T extends BlocxBaseEntity>({
    Iterable<BlocxCommandType>? commands,
  }) {
    final commandSet = commands?.toSet();

    return _controller.stream
        .where((e) => e is BlocxEntityEvent)
        .cast<BlocxEntityEvent>()
        .where((e) {
          if (commandSet != null && !commandSet.contains(e.command)) {
            return false;
          }
          if (e is BlocxEntityEvent<T>) return true;
          return e.entities.isNotEmpty &&
              e.entities.every((item) => item is T);
        })
        .map((e) {
          if (e is BlocxEntityEvent<T>) return e;
          return BlocxEntityEvent<T>(
            entities: List<T>.from(e.entities),
            command: e.command,
            origin: e.origin,
            debugTrace: e.debugTrace,
          );
        });
  }
}

