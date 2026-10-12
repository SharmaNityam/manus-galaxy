import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SaveConversationMessages {
  const SaveConversationMessages(this._repository);

  final ChatRepository _repository;

  Future<void> call(String conversationId, List<ChatMessage> messages) {
    return _repository.saveMessages(conversationId, messages);
  }
}
