import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/entities/pending_operation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/hive_chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import '../datasources/hive_outbox_data_source.dart';
import '../datasources/mock_history_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl({
    required HiveChatLocalDataSource localDataSource,
    required HiveOutboxDataSource outboxDataSource,
    required MockHistoryRemoteDataSource historyRemoteDataSource,
    required ChatRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _outboxDataSource = outboxDataSource,
       _historyRemoteDataSource = historyRemoteDataSource,
       _remoteDataSource = remoteDataSource;

  final HiveChatLocalDataSource _localDataSource;
  final HiveOutboxDataSource _outboxDataSource;
  final MockHistoryRemoteDataSource _historyRemoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

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
    return _mutateAndQueue(
      ChatOperationType.rename,
      conversationId,
      {'title': title.trim()},
      () => _localDataSource.renameConversation(conversationId, title),
    );
  }

  @override
  Future<void> setConversationPinned(String conversationId, bool isPinned) {
    return _mutateAndQueue(
      ChatOperationType.pin,
      conversationId,
      {'isPinned': isPinned},
      () => _localDataSource.setConversationPinned(conversationId, isPinned),
    );
  }

  @override
  Future<void> setConversationArchived(String conversationId, bool isArchived) {
    return _mutateAndQueue(
      ChatOperationType.archive,
      conversationId,
      {'isArchived': isArchived},
      () =>
          _localDataSource.setConversationArchived(conversationId, isArchived),
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    return _mutateAndQueue(
      ChatOperationType.delete,
      conversationId,
      const {},
      () => _localDataSource.deleteConversation(conversationId),
    );
  }

  @override
  Future<void> enqueueOperation(PendingOperation operation) {
    return _outboxDataSource.enqueue(operation);
  }

  @override
  Future<List<PendingOperation>> replayQueuedOperations() async {
    final applied = <PendingOperation>[];
    for (final operation in await _outboxDataSource.pending()) {
      final wasApplied = await _historyRemoteDataSource.apply(operation);
      await _outboxDataSource.remove(operation.id);
      if (wasApplied) applied.add(operation);
    }
    return applied;
  }

  @override
  Future<int> pendingOperationCount() => _outboxDataSource.count();

  @override
  Future<bool> hasPendingOperation(String id) => _outboxDataSource.contains(id);

  Future<void> _mutateAndQueue(
    ChatOperationType type,
    String conversationId,
    Map<String, Object?> payload,
    Future<void> Function() mutate,
  ) async {
    final operation = PendingOperation(
      id: PendingOperation.createId(),
      conversationId: conversationId,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _outboxDataSource.enqueue(operation);
    await mutate();
  }

  @override
  Stream<String> streamReply(
    String prompt, {
    List<ChatAttachment> attachments = const [],
    List<ChatMessage> history = const [],
  }) {
    return _remoteDataSource.streamReply(
      prompt,
      attachments: attachments,
      history: history,
    );
  }
}
