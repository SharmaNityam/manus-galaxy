import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  Future<List<ChatMessage>> loadMessages(String conversationId);

  Future<void> saveMessages(String conversationId, List<ChatMessage> messages);

  Stream<String> streamReply(String prompt);
}
