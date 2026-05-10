import 'package:uuid/uuid.dart';

abstract class BlocxAppEvent {
  final String id;
  final DateTime createdAt;
  final BlocxEventOrigin? origin;
  StackTrace? debugTrace;

  BlocxAppEvent({this.origin, this.debugTrace}) : id = const Uuid().v4(), createdAt = DateTime.now().toUtc();
}

class BlocxEventOrigin {
  final String feature;
  final String source;

  const BlocxEventOrigin({required this.feature, required this.source});
}
