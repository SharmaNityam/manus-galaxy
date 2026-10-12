enum ChatRole { user, assistant }

enum MessageStatus { streaming, complete, stopped, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  ChatMessage copyWith({String? content, MessageStatus? status}) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'role': role.name,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      role: ChatRole.values.byName(map['role'] as String),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: MessageStatus.values.byName(map['status'] as String),
    );
  }
}
