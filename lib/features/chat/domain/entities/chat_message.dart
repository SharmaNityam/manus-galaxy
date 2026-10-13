enum ChatRole { user, assistant }

enum MessageStatus { streaming, queued, complete, stopped, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
    this.operationId,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final String? operationId;

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    String? operationId,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      operationId: operationId ?? this.operationId,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'role': role.name,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    if (operationId != null) 'operationId': operationId,
  };

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      role: ChatRole.values.byName(map['role'] as String),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: MessageStatus.values.byName(map['status'] as String),
      operationId: map['operationId'] as String?,
    );
  }
}
