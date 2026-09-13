import 'package:blocx_core/blocx_core.dart';

mixin BlocxEventHubMixin on BlocxBaseBloc {
  BlocxEventHub get eventHub;

  void emitSystemWideEvent(BlocxAppEvent event) {
    eventHub.emit(event);
  }

  Stream<BlocxAppEvent> get systemEvents => eventHub.stream();

  Stream<T> systemEventsOfType<T extends BlocxAppEvent>() => eventHub.ofType<T>();
}
