import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_composer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeId = ref.read(chatControllerProvider).conversationId;
      if (activeId != widget.conversationId) {
        ref
            .read(chatControllerProvider.notifier)
            .openConversation(widget.conversationId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.messages.lastOrNull?.content !=
              next.messages.lastOrNull?.content) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: state.messages[index]);
              },
            ),
          ),
          ChatComposer(
            isStreaming: state.isStreaming,
            onStop: ref.read(chatControllerProvider.notifier).stop,
            onSend: ref.read(chatControllerProvider.notifier).send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF303030) : Colors.transparent,
          borderRadius: BorderRadius.circular(isUser ? 22 : 10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content.isEmpty &&
                      message.status == MessageStatus.streaming
                  ? '…'
                  : message.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (message.status == MessageStatus.stopped)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Stopped',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (message.status == MessageStatus.failed)
              TextButton(onPressed: null, child: const Text('Response failed')),
          ],
        ),
      ),
    );
  }
}
