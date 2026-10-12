import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class LoadConversationMessages {
  const LoadConversationMessages(this._repository);

  final ChatRepository _repository;

  Future<List<ChatMessage>> call(String conversationId) {
    return _repository.loadMessages(conversationId);
  }
}
