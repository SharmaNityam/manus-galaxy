import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/hive_chat_local_data_source.dart';
import '../datasources/mock_chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl({
    required HiveChatLocalDataSource localDataSource,
    required MockChatRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final HiveChatLocalDataSource _localDataSource;
  final MockChatRemoteDataSource _remoteDataSource;

  @override
  Future<List<ConversationSummary>> loadConversations() {
    return _localDataSource.loadConversations();
  }

  @override
  Future<List<ChatMessage>> loadMessages(String conversationId) {
    return _localDataSource.loadMessages(conversationId);
  }

  @override
  Future<void> saveMessages(String conversationId, List<ChatMessage> messages) {
    return _localDataSource.saveMessages(conversationId, messages);
  }

  @override
  Future<void> renameConversation(String conversationId, String title) {
    return _localDataSource.renameConversation(conversationId, title);
  }

  @override
  Future<void> setConversationPinned(String conversationId, bool isPinned) {
    return _localDataSource.setConversationPinned(conversationId, isPinned);
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    return _localDataSource.deleteConversation(conversationId);
  }

  @override
  Stream<String> streamReply(String prompt) {
    return _remoteDataSource.streamReply(prompt);
  }
}
