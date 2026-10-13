import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_summary.dart';

class HiveChatLocalDataSource {
  HiveChatLocalDataSource(this._box);

  final Box<Map> _box;
  final Map<String, List<ChatMessage>> _messageCache = {};
  static const _messageCacheCapacity = 20;

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
    final cached = _messageCache.remove(conversationId);
    if (cached != null) {
      _messageCache[conversationId] = cached;
      if (cached.any((message) => message.status == MessageStatus.streaming)) {
        final recovered = _recoverInterrupted(cached);
        await saveMessages(conversationId, recovered);
        return recovered;
      }
      return List.unmodifiable(cached);
    }
    final record = _box.get(conversationId);
    final values = record?['messages'] as List<dynamic>? ?? [];
    final messages = values
        .cast<Map<dynamic, dynamic>>()
        .map(ChatMessage.fromMap)
        .toList(growable: false);
    if (messages.any((message) => message.status == MessageStatus.streaming)) {
      final recovered = _recoverInterrupted(messages);
      await saveMessages(conversationId, recovered);
      return recovered;
    }
    _cacheMessages(conversationId, messages);
    return messages;
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
    _cacheMessages(conversationId, messages);
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
    _messageCache.remove(conversationId);
    return _box.delete(conversationId);
  }

  void _cacheMessages(String conversationId, List<ChatMessage> messages) {
    _messageCache.remove(conversationId);
    _messageCache[conversationId] = List.unmodifiable(messages);
    if (_messageCache.length > _messageCacheCapacity) {
      _messageCache.remove(_messageCache.keys.first);
    }
  }

  List<ChatMessage> _recoverInterrupted(List<ChatMessage> messages) => messages
      .map(
        (message) => message.status == MessageStatus.streaming
            ? message.copyWith(status: MessageStatus.stopped)
            : message,
      )
      .toList(growable: false);

  String _titleFor(List<ChatMessage> messages) {
    final users = messages.where((message) => message.role == ChatRole.user);
    if (users.isEmpty) return 'New chat';
    final content = users.first.content.trim();
    return content.length > 36 ? '${content.substring(0, 36)}…' : content;
  }
}
