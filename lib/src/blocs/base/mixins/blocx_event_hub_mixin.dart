import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/base/mixins/blocx_app_event.dart' show BlocxAppEvent;

mixin BlocxEventHubMixin on BaseBloc {
  BlocxEventHub get eventHub;

  void emitSystemWideEvent(BlocxAppEvent event) {
    eventHub.emit(event);
  }

  Stream<BlocxAppEvent> get systemEvents => eventHub.stream();

  Stream<T> systemEventsOfType<T extends BlocxAppEvent>() => eventHub.ofType<T>();
}
