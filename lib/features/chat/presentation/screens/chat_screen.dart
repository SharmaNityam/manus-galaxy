import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_composer.dart';
import '../widgets/conversation_history_drawer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _isAtBottom = true;

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

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.messages.lastOrNull?.content !=
              next.messages.lastOrNull?.content) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isAtBottom) _scrollToLatest();
        });
      }
    });

    return Scaffold(
      drawer: ConversationHistoryDrawer(
        activeConversationId: widget.conversationId,
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Chat'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'History',
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis == Axis.vertical) {
                      final atBottom = notification.metrics.extentAfter < 64;
                      if (atBottom != _isAtBottom && mounted) {
                        setState(() => _isAtBottom = atBottom);
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) => ResponsiveContent(
                      maxWidth: 800,
                      horizontalPadding: 16,
                      child: _MessageBubble(message: state.messages[index]),
                    ),
                  ),
                ),
                if (!_isAtBottom && state.messages.isNotEmpty)
                  Positioned(
                    right: 16,
                    bottom: 12,
                    child: SafeArea(
                      top: false,
                      child: Material(
                        color: AppTheme.chrome,
                        shape: const StadiumBorder(),
                        elevation: 4,
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: () {
                            setState(() => _isAtBottom = true);
                            _scrollToLatest();
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.south_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Jump to latest'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final bubbleMaxWidth = screenWidth < 600
            ? constraints.maxWidth * 0.9
            : 680.0;
        final content = Column(
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
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Response failed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFFF9B9B),
                  ),
                ),
              ),
          ],
        );
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
            margin: const EdgeInsets.only(bottom: 18),
            padding: isUser
                ? const EdgeInsets.symmetric(horizontal: 17, vertical: 13)
                : const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.userMessage : Colors.transparent,
              borderRadius: BorderRadius.circular(isUser ? 22 : 10),
            ),
            child: content,
          ),
        );
      },
    );
  }
}
