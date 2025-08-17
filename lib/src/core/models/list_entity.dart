import 'package:blocx/src/core/models/base_entity.dart';

abstract class ListEntity<T> extends BaseEntity {
  final bool _isSelected;
  final bool _isHighlighted;
  final bool _isBeingRemoved;
  final bool _isBeingSelected;

  ListEntity.empty()
    : _isSelected = false,
      _isBeingRemoved = false,
      _isBeingSelected = false,
      _isHighlighted = false;
  ListEntity({
    bool isSelected = false,
    bool isHighlighted = false,
    bool isBeingRemoved = false,
    bool isBeingSelected = false,
  }) : _isSelected = isSelected,
       _isHighlighted = isHighlighted,
       _isBeingRemoved = isBeingRemoved,
       _isBeingSelected = isBeingSelected;

  bool get isSelected => _isSelected;
  bool get isHighlighted => _isHighlighted;
  bool get isBeingRemoved => _isBeingRemoved;
  bool get isBeingSelected => _isBeingSelected;

  T copyWith({bool? isSelected, bool? isBeingSelected, bool? isBeingRemoved, bool? isHighlighted});
}
