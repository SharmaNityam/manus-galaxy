import '../entities/chat_message.dart';
import '../entities/conversation_summary.dart';
import '../entities/pending_operation.dart';

abstract interface class ChatRepository {
  Future<List<ConversationSummary>> loadConversations();

  Future<List<ChatMessage>> loadMessages(String conversationId);

  Future<void> saveMessages(String conversationId, List<ChatMessage> messages);

  Future<void> renameConversation(String conversationId, String title);

  Future<void> setConversationPinned(String conversationId, bool isPinned);

  Future<void> deleteConversation(String conversationId);

  Future<void> enqueueOperation(PendingOperation operation);

  Future<List<PendingOperation>> replayQueuedOperations();

  Future<int> pendingOperationCount();

  Future<bool> hasPendingOperation(String id);

  Stream<String> streamReply(String prompt);
}
