import 'package:blocx_core/src/core/models/base_entity.dart';
import 'package:uuid/uuid.dart';

/// Defines the CRUD command type associated with a use case or entity event.
enum BlocxCommandType { create, read, update, delete }

abstract class BlocxAppEvent {
  final String id;
  final DateTime createdAt;
  final BlocxEventOrigin? origin;
  StackTrace? debugTrace;

  BlocxAppEvent({this.origin, this.debugTrace, String? id, DateTime? createdAt})
    : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now().toUtc();
}

/// System-wide event representing a [BlocxCommandType] executed on one or more
/// [BlocxBaseEntity] instances.
class BlocxEntityEvent<T extends BlocxBaseEntity> extends BlocxAppEvent {
  /// The affected entities for this command.
  final List<T> entities;

  /// The command executed on [entities].
  final BlocxCommandType command;

  BlocxEntityEvent({
    required List<T> entities,
    required this.command,
    super.origin,
    super.debugTrace,
    super.id,
    super.createdAt,
  }) : entities = List<T>.unmodifiable(entities);

  /// Convenience constructor for a single-entity command event.
  BlocxEntityEvent.single({
    required T entity,
    required this.command,
    super.origin,
    super.debugTrace,
    super.id,
    super.createdAt,
  }) : entities = List<T>.unmodifiable(<T>[entity]);

  /// Returns the first entity in [entities].
  T get entity => entities.first;
}

class BlocxEventOrigin {
  final String feature;
  final String source;

  const BlocxEventOrigin({required this.feature, required this.source});
}
