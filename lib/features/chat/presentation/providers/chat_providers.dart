import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/load_conversation_messages.dart';
import '../../domain/usecases/save_conversation_messages.dart';
import '../../domain/usecases/stream_chat_reply.dart';

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

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatState {
  const ChatState({
    this.conversationId,
    this.messages = const [],
    this.isStreaming = false,
  });

  final String? conversationId;
  final List<ChatMessage> messages;
  final bool isStreaming;

  ChatState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    bool? isStreaming,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  StreamSubscription<String>? _subscription;

  @override
  ChatState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const ChatState();
  }

  String newConversation() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    state = ChatState(conversationId: id);
    return id;
  }

  Future<void> openConversation(String conversationId) async {
    final messages = await ref
        .read(loadConversationMessagesProvider)
        .call(conversationId);
    state = ChatState(conversationId: conversationId, messages: messages);
  }

  Future<void> send(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty || state.isStreaming) return;
    final conversationId = state.conversationId ?? newConversation();
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
    await _save(conversationId, messages);

    _subscription = ref
        .read(streamChatReplyProvider)
        .call(text)
        .listen(
          (chunk) {
            final updated = [
              ...state.messages.take(state.messages.length - 1),
              assistantMessage.copyWith(
                content: '${state.messages.last.content}$chunk',
              ),
            ];
            state = state.copyWith(messages: updated);
          },
          onError: (Object error, StackTrace stackTrace) {
            _finishAssistant(MessageStatus.failed);
          },
          onDone: () => _finishAssistant(MessageStatus.complete),
        );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _finishAssistant(MessageStatus.stopped);
  }

  void _finishAssistant(MessageStatus status) {
    if (state.messages.isEmpty) return;
    final messages = [...state.messages];
    messages[messages.length - 1] = messages.last.copyWith(status: status);
    state = state.copyWith(messages: messages, isStreaming: false);
    final conversationId = state.conversationId;
    if (conversationId != null) _save(conversationId, messages);
  }

  Future<void> _save(String conversationId, List<ChatMessage> messages) {
    return ref
        .read(saveConversationMessagesProvider)
        .call(conversationId, messages);
  }
}
