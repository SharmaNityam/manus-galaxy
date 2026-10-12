import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/responsive_content.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_composer.dart';
import '../widgets/conversation_history_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const ConversationHistoryDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 18),
            SizedBox(width: 6),
            Text('manus'),
          ],
        ),
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 420;
                  final horizontalPadding = constraints.maxWidth < 360
                      ? 12.0
                      : constraints.maxWidth < 600
                      ? 20.0
                      : 28.0;

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ResponsiveContent(
                          maxWidth: 640,
                          horizontalPadding: horizontalPadding,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: compact ? 16 : 32,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Leave all to Manus',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: constraints.maxWidth < 360
                                            ? 27
                                            : constraints.maxWidth >= 600
                                            ? 38
                                            : 32,
                                        fontFamily: 'serif',
                                        fontWeight: FontWeight.w500,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your AI agent',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.secondaryText),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: compact ? 14 : 22),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final item in const [
                                      ('Develop app', Icons.phone_iphone),
                                      ('Website', Icons.language),
                                      ('Slides', Icons.slideshow_outlined),
                                      ('Image', Icons.image_outlined),
                                      ('Audio', Icons.graphic_eq),
                                      ('Video', Icons.videocam_outlined),
                                      ('Wide Research', Icons.travel_explore),
                                      (
                                        'Spreadsheet',
                                        Icons.table_chart_outlined,
                                      ),
                                    ])
                                      _SuggestionChip(
                                        label: item.$1,
                                        icon: item.$2,
                                        onPressed: () => _startChat(
                                          context,
                                          ref,
                                          'Help me with ${item.$1.toLowerCase()}',
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ChatComposer(onSend: (text) => _startChat(context, ref, text)),
          ],
        ),
      ),
    );
  }

  void _startChat(BuildContext context, WidgetRef ref, String prompt) {
    final conversationId = ref
        .read(chatControllerProvider.notifier)
        .newConversation();
    context.push('/chat/$conversationId');
    ref.read(chatControllerProvider.notifier).send(prompt);
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Material(
        color: const Color(0xFFECECE9),
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
