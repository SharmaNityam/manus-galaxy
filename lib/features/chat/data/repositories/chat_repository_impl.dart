import '../../domain/entities/chat_message.dart';
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
  Future<List<ChatMessage>> loadMessages(String conversationId) {
    return _localDataSource.loadMessages(conversationId);
  }

  @override
  Future<void> saveMessages(String conversationId, List<ChatMessage> messages) {
    return _localDataSource.saveMessages(conversationId, messages);
  }

  @override
  Stream<String> streamReply(String prompt) {
    return _remoteDataSource.streamReply(prompt);
  }
}
