import 'dart:ui';

class DebugDraggableTile {
  DebugDraggableTile({
    required this.id,
    required this.position,
    required this.originalPosition,
    required this.label,
    this.snappedRow,
    this.snappedCol,
  });

  final String id;
  Offset position;
  final Offset originalPosition;
  final String label;
  int? snappedRow;
  int? snappedCol;

  factory DebugDraggableTile.spawn({
    required String id,
    required Offset position,
    required String label,
  }) {
    return DebugDraggableTile(
      id: id,
      position: position,
      originalPosition: position,
      label: label,
    );
  }

  DebugDraggableTile copyWith({
    Offset? position,
    int? snappedRow,
    int? snappedCol,
    bool clearSnap = false,
  }) {
    return DebugDraggableTile(
      id: id,
      position: position ?? this.position,
      originalPosition: originalPosition,
      label: label,
      snappedRow: clearSnap ? null : snappedRow ?? this.snappedRow,
      snappedCol: clearSnap ? null : snappedCol ?? this.snappedCol,
    );
  }
}
