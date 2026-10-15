import '../entities/conversation_summary.dart';
import '../repositories/chat_repository.dart';

class ManageConversationHistory {
  const ManageConversationHistory(this._repository);

  final ChatRepository _repository;

  Future<List<ConversationSummary>> load() {
    return _repository.loadConversations();
  }

  Future<void> rename(String id, String title) {
    return _repository.renameConversation(id, title);
  }

  Future<void> setPinned(String id, bool isPinned) {
    return _repository.setConversationPinned(id, isPinned);
  }

  Future<void> setArchived(String id, bool isArchived) {
    return _repository.setConversationArchived(id, isArchived);
  }

  Future<void> delete(String id) {
    return _repository.deleteConversation(id);
  }
}
