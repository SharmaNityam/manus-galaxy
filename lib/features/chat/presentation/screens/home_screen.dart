import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_composer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manus'),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'History',
            icon: const Icon(Icons.menu_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                'What can I help with?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _SuggestionChip(
                  label: 'Explain a topic',
                  onPressed: () => _startChat(context, ref, 'Explain a topic'),
                ),
                _SuggestionChip(
                  label: 'Help me write',
                  onPressed: () => _startChat(context, ref, 'Help me write'),
                ),
                _SuggestionChip(
                  label: 'Plan something',
                  onPressed: () => _startChat(context, ref, 'Plan something'),
                ),
              ],
            ),
            const Spacer(),
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
  const _SuggestionChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onPressed,
      label: Text(label),
      backgroundColor: AppTheme.surface,
      side: BorderSide.none,
      shape: const StadiumBorder(),
    );
  }
}
