import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_attachment.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_composer.dart';
import '../widgets/conversation_history_drawer.dart';

enum _ChatMode { ask, agent }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _mode = _ChatMode.ask;
  var _composerFocused = false;

  String get _modeInstruction => switch (_mode) {
    _ChatMode.ask =>
      'Answer directly and conversationally. For questions about offline behavior, explain that outbound actions are saved in a local durable queue and replayed in order after reconnection with stable operation IDs; do not claim the server stores messages for an offline client. Be accurate and avoid unrelated examples.',
    _ChatMode.agent =>
      'Act as a capable task-oriented assistant. For questions about offline behavior, explain that outbound actions are saved in a local durable queue and replayed in order after reconnection with stable operation IDs; do not claim the server stores messages for an offline client. Give a practical result and state assumptions clearly.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ConversationHistoryDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showModePicker,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_mode == _ChatMode.ask ? 'Ask' : 'Agent'),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 23),
              ],
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Chats',
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 430;
                  final horizontal = constraints.maxWidth < 380 ? 16.0 : 24.0;
                  return Stack(
                    children: [
                      if (_composerFocused)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'What can I do for you?',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontFamily: 'serif',
                                    fontSize: constraints.maxWidth < 360
                                        ? 24
                                        : 26,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            16,
                            horizontal,
                            compact ? 8 : 0,
                          ),
                          child: _IdeasToTry(
                            compact: compact,
                            onSelect: (prompt) =>
                                _startChat(context, ChatDraft(text: prompt)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ChatComposer(
              homeStyle: true,
              onFocusChanged: (focused) {
                if (mounted && _composerFocused != focused) {
                  setState(() => _composerFocused = focused);
                }
              },
              onSend: (draft) => _startChat(context, draft),
            ),
          ],
        ),
      ),
    );
  }

  void _showModePicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a mode',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final mode in _ChatMode.values)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(mode == _ChatMode.ask ? 'Ask' : 'Agent'),
                  subtitle: Text(
                    mode == _ChatMode.ask
                        ? 'Get a direct answer to your question.'
                        : 'Work through a task with a practical result.',
                  ),
                  trailing: _mode == mode
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    setState(() => _mode = mode);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChat(BuildContext context, ChatDraft draft) {
    final conversationId = ref
        .read(chatControllerProvider.notifier)
        .newConversation();
    context.push('/chat/$conversationId');
    ref
        .read(chatControllerProvider.notifier)
        .send(
          draft.text,
          contextInstruction: _modeInstruction,
          attachments: draft.attachments,
        );
  }
}

class _IdeasToTry extends StatelessWidget {
  const _IdeasToTry({required this.compact, required this.onSelect});

  final bool compact;
  final ValueChanged<String> onSelect;

  static const _ideas = [
    (
      'Create an anime short',
      'Video',
      Icons.movie_creation_outlined,
      'assets/images/idea_video.png',
    ),
    (
      'Build a personal budget app',
      'App',
      Icons.phone_iphone_rounded,
      'assets/images/idea_app.png',
    ),
    ('Turn a photo into art', 'Image', Icons.image_outlined, null),
    ('Research a topic', 'Research', Icons.travel_explore_rounded, null),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ideas to try',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showAllIdeas(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondaryText,
                minimumSize: const Size(48, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(fontWeight: FontWeight.w400),
              ),
              child: const Text('View all  ›'),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 8),
        SizedBox(
          height: compact ? 112 : 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _ideas.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final idea = _ideas[index];
              return SizedBox(
                width: compact ? 122 : 132,
                child: GestureDetector(
                  onTap: () => onSelect(idea.$1),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
                          height: compact ? 68 : 74,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (idea.$4 case final asset?)
                                Image.asset(asset, fit: BoxFit.cover)
                              else
                                Container(
                                  color: const Color(0xFFE7E7E4),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    idea.$3,
                                    size: 44,
                                    color: const Color(
                                      0xFF171717,
                                    ).withValues(alpha: 0.08),
                                  ),
                                ),
                              if (idea.$4 == null)
                                Positioned(
                                  left: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: const ShapeDecoration(
                                      color: Color(0xFF5C5C59),
                                      shape: StadiumBorder(),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          idea.$3,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          idea.$2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        idea.$1,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryText,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAllIdeas(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Text(
                'Ideas to try',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            for (final idea in _ideas)
              ListTile(
                leading: Icon(idea.$3),
                title: Text(idea.$1),
                subtitle: Text(idea.$2),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelect(idea.$1);
                },
              ),
          ],
        ),
      ),
    );
  }
}
