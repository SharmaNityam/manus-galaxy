import 'dart:math';

enum ChatOperationType { rename, pin, delete, send }

class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final ChatOperationType type;
  final Map<String, Object?> payload;
  final DateTime createdAt;

  static String createId() {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'conversationId': conversationId,
    'type': type.name,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingOperation.fromMap(Map<dynamic, dynamic> map) {
    return PendingOperation(
      id: map['id'] as String,
      conversationId: map['conversationId'] as String,
      type: ChatOperationType.values.byName(map['type'] as String),
      payload: Map<String, Object?>.from(map['payload'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
