import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_summary.dart';

class HiveChatLocalDataSource {
  const HiveChatLocalDataSource(this._box);

  final Box<Map> _box;

  Future<List<ConversationSummary>> loadConversations() async {
    final conversations = _box.keys
        .map((key) {
          final id = key.toString();
          final record = _box.get(key);
          if (record == null) return null;
          return ConversationSummary(
            id: id,
            title: record['title'] as String? ?? 'New chat',
            updatedAt:
                DateTime.tryParse(record['updatedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
            isPinned: record['isPinned'] as bool? ?? false,
          );
        })
        .whereType<ConversationSummary>()
        .toList();
    conversations.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return conversations;
  }

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
      'isPinned': previous?['isPinned'] as bool? ?? false,
      'updatedAt': DateTime.now().toIso8601String(),
      'messages': messages.map((message) => message.toMap()).toList(),
    });
  }

  Future<void> renameConversation(String conversationId, String title) async {
    final record = _box.get(conversationId);
    if (record == null) return;
    await _box.put(conversationId, {...record, 'title': title.trim()});
  }

  Future<void> setConversationPinned(
    String conversationId,
    bool isPinned,
  ) async {
    final record = _box.get(conversationId);
    if (record == null) return;
    await _box.put(conversationId, {...record, 'isPinned': isPinned});
  }

  Future<void> deleteConversation(String conversationId) {
    return _box.delete(conversationId);
  }

  String _titleFor(List<ChatMessage> messages) {
    final users = messages.where((message) => message.role == ChatRole.user);
    if (users.isEmpty) return 'New chat';
    final content = users.first.content.trim();
    return content.length > 36 ? '${content.substring(0, 36)}…' : content;
  }
}
