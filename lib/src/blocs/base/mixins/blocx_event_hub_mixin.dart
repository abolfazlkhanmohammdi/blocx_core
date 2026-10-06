import 'package:blocx_core/blocx_core.dart';

mixin BlocxEventHubMixin on BlocxBaseBloc {
  BlocxEventHub get eventHub;

  Stream<BlocxAppEvent> get systemEvents => eventHub.stream();

  Stream<T> systemEventsOfType<T extends BlocxAppEvent>() =>
      eventHub.ofType<T>();

  Stream<BlocxEntityEvent<T>> entityEventsOfType<T extends BlocxBaseEntity>({
    Iterable<BlocxCommandType>? commands,
  }) =>
      eventHub.onEntity<T>(commands: commands);
}


