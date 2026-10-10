import 'package:blocx_core/blocx_core.dart';

class TestItem extends BlocxBaseEntity {
  final String id;
  final String title;
  final int order;

  const TestItem({required this.id, required this.title, this.order = 0});

  @override
  String get identifier => id;

  TestItem copyWith({String? id, String? title, int? order}) {
    return TestItem(
      id: id ?? this.id,
      title: title ?? this.title,
      order: order ?? this.order,
    );
  }

  @override
  String toString() => 'TestItem(id: $id, title: $title, order: $order)';
}
