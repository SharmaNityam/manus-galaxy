import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/entities/chat_message.dart';

class HiveChatLocalDataSource {
  const HiveChatLocalDataSource(this._box);

  final Box<Map> _box;

  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final record = _box.get(conversationId);
    final values = record?['messages'] as List<dynamic>? ?? [];
    return values
        .cast<Map<dynamic, dynamic>>()
        .map(ChatMessage.fromMap)
        .toList(growable: false);
  }

  Future<void> saveMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    final previous = _box.get(conversationId);
    await _box.put(conversationId, {
      'id': conversationId,
      'title': previous?['title'] ?? _titleFor(messages),
      'updatedAt': DateTime.now().toIso8601String(),
      'messages': messages.map((message) => message.toMap()).toList(),
    });
  }

  String _titleFor(List<ChatMessage> messages) {
    final users = messages.where((message) => message.role == ChatRole.user);
    if (users.isEmpty) return 'New chat';
    final content = users.first.content.trim();
    return content.length > 36 ? '${content.substring(0, 36)}…' : content;
  }
}
