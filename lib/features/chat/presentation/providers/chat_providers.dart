import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/entities/pending_operation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/manage_conversation_history.dart';
import '../../domain/usecases/load_conversation_messages.dart';
import '../../domain/usecases/save_conversation_messages.dart';
import '../../domain/usecases/stream_chat_reply.dart';
import '../controllers/outbox_sync_coordinator.dart';

final outboxSyncCoordinatorProvider =
    ChangeNotifierProvider<OutboxSyncCoordinator>((ref) {
      throw UnimplementedError('Outbox sync must be configured at startup.');
    });

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  throw UnimplementedError('ChatRepository must be configured at startup.');
});

final streamChatReplyProvider = Provider<StreamChatReply>((ref) {
  return StreamChatReply(ref.watch(chatRepositoryProvider));
});

final loadConversationMessagesProvider = Provider<LoadConversationMessages>((
  ref,
) {
  return LoadConversationMessages(ref.watch(chatRepositoryProvider));
});

final saveConversationMessagesProvider = Provider<SaveConversationMessages>((
  ref,
) {
  return SaveConversationMessages(ref.watch(chatRepositoryProvider));
});

final manageConversationHistoryProvider = Provider<ManageConversationHistory>(
  (ref) => ManageConversationHistory(ref.watch(chatRepositoryProvider)),
);

final conversationHistoryProvider = FutureProvider<List<ConversationSummary>>((
  ref,
) {
  return ref.watch(manageConversationHistoryProvider).load();
});

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatState {
  const ChatState({
    this.conversationId,
    this.messages = const [],
    this.isStreaming = false,
    this.persistenceError,
  });

  final String? conversationId;
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? persistenceError;

  ChatState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? persistenceError,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      persistenceError: persistenceError,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  StreamSubscription<String>? _subscription;
  StreamSubscription<PendingOperation>? _syncSubscription;
  Timer? _flushTimer;
  String _pendingDelta = '';
  int _requestGeneration = 0;
  Future<void> _saveQueue = Future<void>.value();

  @override
  ChatState build() {
    ref.onDispose(() {
      _requestGeneration++;
      _flushTimer?.cancel();
      _subscription?.cancel();
      _syncSubscription?.cancel();
    });
    _syncSubscription = ref
        .read(outboxSyncCoordinatorProvider)
        .appliedOperations
        .listen(_handleAppliedOperation);
    return const ChatState();
  }

  String newConversation() {
    _interruptCurrentRequest();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    state = ChatState(conversationId: id);
    return id;
  }

  Future<void> openConversation(String conversationId) async {
    _interruptCurrentRequest();
    final generation = ++_requestGeneration;
    _flushTimer?.cancel();
    _pendingDelta = '';
    final messages = await ref
        .read(loadConversationMessagesProvider)
        .call(conversationId);
    if (generation != _requestGeneration) return;
    final recovered = await _recoverQueuedMessages(conversationId, messages);
    state = ChatState(conversationId: conversationId, messages: recovered);
  }

  Future<void> send(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty || state.isStreaming) return;
    final conversationId = state.conversationId ?? newConversation();
    final syncCoordinator = ref.read(outboxSyncCoordinatorProvider);
    if (!syncCoordinator.isOnline) {
      await _queueOfflinePrompt(conversationId, text);
      return;
    }
    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
      status: MessageStatus.complete,
    );
    final assistantMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: MessageStatus.streaming,
    );
    final messages = [...state.messages, userMessage, assistantMessage];
    state = state.copyWith(messages: messages, isStreaming: true);
    _persist(conversationId, messages);
    _startStream(text, conversationId, assistantMessage.id);
  }

  Future<void> stop() async {
    final assistant = _lastAssistant;
    if (assistant == null || !state.isStreaming) return;
    _flushTimer?.cancel();
    _flushPending();
    _requestGeneration++;
    await _subscription?.cancel();
    _subscription = null;
    _finishAssistant(assistant.id, MessageStatus.stopped);
  }

  Future<void> retryLast() async {
    final assistantIndex = state.messages.lastIndexWhere(
      (message) =>
          message.role == ChatRole.assistant &&
          (message.status == MessageStatus.failed ||
              message.status == MessageStatus.stopped),
    );
    if (assistantIndex <= 0) return;
    await retryMessage(state.messages[assistantIndex].id);
  }

  Future<void> retryMessage(String assistantId) async {
    if (state.isStreaming ||
        !ref.read(outboxSyncCoordinatorProvider).isOnline) {
      return;
    }
    final assistantIndex = state.messages.indexWhere(
      (message) =>
          message.id == assistantId &&
          message.role == ChatRole.assistant &&
          (message.status == MessageStatus.failed ||
              message.status == MessageStatus.stopped),
    );
    if (assistantIndex <= 0) return;
    final previousUserIndex = state.messages
        .take(assistantIndex)
        .toList()
        .lastIndexWhere((message) => message.role == ChatRole.user);
    if (previousUserIndex < 0) return;
    final assistant = state.messages[assistantIndex];
    final user = state.messages[previousUserIndex];
    final messages = [...state.messages];
    messages[assistantIndex] = assistant.copyWith(
      content: '',
      status: MessageStatus.streaming,
    );
    state = state.copyWith(messages: messages, isStreaming: true);
    final conversationId = state.conversationId;
    if (conversationId == null) return;
    _persist(conversationId, messages);
    _startStream(user.content, conversationId, assistant.id);
  }

  ChatMessage? get _lastAssistant {
    for (final message in state.messages.reversed) {
      if (message.role == ChatRole.assistant) return message;
    }
    return null;
  }

  Future<void> _queueOfflinePrompt(String conversationId, String prompt) async {
    final operationId = PendingOperation.createId();
    final now = DateTime.now();
    final userMessage = ChatMessage(
      id: PendingOperation.createId(),
      role: ChatRole.user,
      content: prompt,
      createdAt: now,
      status: MessageStatus.queued,
      operationId: operationId,
    );
    final assistantMessage = ChatMessage(
      id: PendingOperation.createId(),
      role: ChatRole.assistant,
      content: '',
      createdAt: now,
      status: MessageStatus.queued,
      operationId: operationId,
    );
    final messages = [...state.messages, userMessage, assistantMessage];
    state = state.copyWith(messages: messages, isStreaming: false);
    await ref
        .read(chatRepositoryProvider)
        .enqueueOperation(
          PendingOperation(
            id: operationId,
            conversationId: conversationId,
            type: ChatOperationType.send,
            payload: {'prompt': prompt},
            createdAt: now,
          ),
        );
    await _persist(conversationId, messages);
    await ref.read(outboxSyncCoordinatorProvider).refresh();
  }

  Future<List<ChatMessage>> _recoverQueuedMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    final recovered = [...messages];
    var changed = false;
    for (var index = 0; index < recovered.length; index++) {
      final message = recovered[index];
      final operationId = message.operationId;
      if (message.status != MessageStatus.queued || operationId == null) {
        continue;
      }
      if (await ref
          .read(chatRepositoryProvider)
          .hasPendingOperation(operationId)) {
        continue;
      }
      recovered[index] = message.copyWith(
        status: message.role == ChatRole.assistant
            ? MessageStatus.failed
            : MessageStatus.complete,
      );
      changed = true;
    }
    if (changed) {
      await ref
          .read(saveConversationMessagesProvider)
          .call(conversationId, recovered);
      ref.invalidate(conversationHistoryProvider);
    }
    return recovered;
  }

  Future<void> _handleAppliedOperation(PendingOperation operation) async {
    if (operation.type != ChatOperationType.send) return;
    final messages = await ref
        .read(loadConversationMessagesProvider)
        .call(operation.conversationId);
    final assistantIndex = messages.indexWhere(
      (message) =>
          message.role == ChatRole.assistant &&
          message.operationId == operation.id,
    );
    if (assistantIndex < 0) return;
    final updated = [...messages];
    for (var index = 0; index < updated.length; index++) {
      if (updated[index].operationId == operation.id &&
          updated[index].role == ChatRole.user) {
        updated[index] = updated[index].copyWith(
          status: MessageStatus.complete,
        );
      }
    }
    final assistant = updated[assistantIndex].copyWith(
      content: '',
      status: MessageStatus.streaming,
    );
    updated[assistantIndex] = assistant;
    await ref
        .read(saveConversationMessagesProvider)
        .call(operation.conversationId, updated);
    if (state.conversationId != operation.conversationId) {
      updated[assistantIndex] = assistant.copyWith(
        status: MessageStatus.stopped,
      );
      await ref
          .read(saveConversationMessagesProvider)
          .call(operation.conversationId, updated);
      return;
    }
    state = state.copyWith(messages: updated, isStreaming: true);
    _startStream(
      operation.payload['prompt'] as String,
      operation.conversationId,
      assistant.id,
    );
  }

  void _startStream(String prompt, String conversationId, String messageId) {
    final generation = ++_requestGeneration;
    _pendingDelta = '';
    _flushTimer?.cancel();
    try {
      _subscription = ref
          .read(streamChatReplyProvider)
          .call(prompt)
          .listen(
            (chunk) {
              if (generation != _requestGeneration) return;
              _pendingDelta += chunk;
              _flushTimer ??= Timer(
                const Duration(milliseconds: 70),
                () => _flushPending(generation, conversationId, messageId),
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              if (generation != _requestGeneration) return;
              _flushPending(generation, conversationId, messageId);
              _finishAssistant(messageId, MessageStatus.failed);
            },
            onDone: () {
              if (generation != _requestGeneration) return;
              _flushPending(generation, conversationId, messageId);
              _finishAssistant(messageId, MessageStatus.complete);
            },
            cancelOnError: true,
          );
    } catch (_) {
      if (generation == _requestGeneration) {
        _finishAssistant(messageId, MessageStatus.failed);
      }
    }
  }

  void _flushPending([
    int? generation,
    String? conversationId,
    String? messageId,
  ]) {
    _flushTimer?.cancel();
    _flushTimer = null;
    final delta = _pendingDelta;
    _pendingDelta = '';
    if (delta.isEmpty ||
        (generation != null && generation != _requestGeneration)) {
      return;
    }
    final id = messageId ?? _lastAssistant?.id;
    if (id == null) return;
    final index = state.messages.indexWhere((message) => message.id == id);
    if (index < 0) return;
    final messages = [...state.messages];
    messages[index] = messages[index].copyWith(
      content: '${messages[index].content}$delta',
    );
    state = state.copyWith(messages: messages);
    final activeConversation = conversationId ?? state.conversationId;
    if (activeConversation != null) _persist(activeConversation, messages);
  }

  void _finishAssistant(String messageId, MessageStatus status) {
    final index = state.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return;
    final messages = [...state.messages];
    messages[index] = messages[index].copyWith(status: status);
    state = state.copyWith(messages: messages, isStreaming: false);
    final conversationId = state.conversationId;
    if (conversationId != null) _persist(conversationId, messages);
  }

  Future<void> _persist(String conversationId, List<ChatMessage> messages) {
    final snapshot = List<ChatMessage>.unmodifiable(messages);
    _saveQueue = _saveQueue
        .then((_) async {
          await ref
              .read(saveConversationMessagesProvider)
              .call(conversationId, snapshot);
          ref.invalidate(conversationHistoryProvider);
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (state.conversationId == conversationId) {
            state = state.copyWith(
              persistenceError: 'Could not save this chat.',
            );
          }
        });
    return _saveQueue;
  }

  void _interruptCurrentRequest() {
    final subscription = _subscription;
    _subscription = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _flushPending();
    _requestGeneration++;
    final assistant = _lastAssistant;
    if (state.isStreaming && assistant != null) {
      _finishAssistant(assistant.id, MessageStatus.stopped);
    }
    if (subscription != null) unawaited(subscription.cancel());
  }
}
