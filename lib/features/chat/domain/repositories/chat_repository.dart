import '../entities/chat_message.dart';
import '../entities/conversation_summary.dart';

abstract interface class ChatRepository {
  Future<List<ConversationSummary>> loadConversations();

  Future<List<ChatMessage>> loadMessages(String conversationId);

  Future<void> saveMessages(String conversationId, List<ChatMessage> messages);

  Future<void> renameConversation(String conversationId, String title);

  Future<void> setConversationPinned(String conversationId, bool isPinned);

  Future<void> deleteConversation(String conversationId);

  Stream<String> streamReply(String prompt);
}
