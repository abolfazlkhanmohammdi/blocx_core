import 'dart:async';
import 'package:uuid/uuid.dart';

import 'blocx_app_event.dart' show BlocxAppEvent;

abstract class BlocxEventHub {
  void emit(BlocxAppEvent event);
  Stream<BlocxAppEvent> stream();
  Stream<T> ofType<T extends BlocxAppEvent>();
  void dispose();
}

class BlocxSimpleEventHub implements BlocxEventHub {
  final StreamController<BlocxAppEvent> _controller = StreamController<BlocxAppEvent>.broadcast();

  @override
  Stream<BlocxAppEvent> stream() => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Stream<T> ofType<T extends BlocxAppEvent>() => _controller.stream.where((e) => e is T).cast<T>();

  @override
  void emit(BlocxAppEvent event) {
    if (!_controller.isClosed) {
      event.debugTrace = StackTrace.current;
      _controller.add(event);
    }
  }
}
