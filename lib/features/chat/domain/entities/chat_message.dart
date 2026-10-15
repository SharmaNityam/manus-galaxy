import 'chat_attachment.dart';

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
    this.contextInstruction,
    this.attachments = const [],
    this.failureMessage,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final String? operationId;
  final String? contextInstruction;
  final List<ChatAttachment> attachments;
  final String? failureMessage;

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    String? operationId,
    String? contextInstruction,
    String? failureMessage,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      operationId: operationId ?? this.operationId,
      contextInstruction: contextInstruction ?? this.contextInstruction,
      attachments: attachments,
      failureMessage: status == MessageStatus.streaming
          ? null
          : failureMessage ?? this.failureMessage,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'role': role.name,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'failureMessage': failureMessage,
    'attachments': attachments.map((file) => file.toMap()).toList(),
    if (operationId != null) 'operationId': operationId,
    if (contextInstruction != null) 'contextInstruction': contextInstruction,
  };

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      role: ChatRole.values.byName(map['role'] as String),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: MessageStatus.values.byName(map['status'] as String),
      failureMessage: map['failureMessage'] as String?,
      operationId: map['operationId'] as String?,
      contextInstruction: map['contextInstruction'] as String?,
      attachments: (map['attachments'] as List? ?? [])
          .map((file) => ChatAttachment.fromMap(file as Map))
          .toList(),
    );
  }
}
