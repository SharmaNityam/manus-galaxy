import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../chat/domain/entities/chat_message.dart';
import '../../chat/presentation/providers/chat_providers.dart';

class ContextPickerScreen extends ConsumerStatefulWidget {
  const ContextPickerScreen({required this.kind, super.key});
  final String kind;
  @override
  ConsumerState<ContextPickerScreen> createState() =>
      _ContextPickerScreenState();
}

class _ContextPickerScreenState extends ConsumerState<ContextPickerScreen> {
  String _query = '';
  static const _skills = [
    (
      'Write clearly',
      'Rewrite the following text to make it clear, concise, and natural.',
    ),
    (
      'Research a topic',
      'Research the following topic. Explain the key points and state any uncertainty.',
    ),
    (
      'Review code',
      'Review the following code for correctness, edge cases, and readability.',
    ),
    (
      'Create a plan',
      'Create a practical step-by-step plan for the following task.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final skills = widget.kind == 'skills';
    final creations = widget.kind == 'creations';
    final title = skills
        ? 'Skills'
        : creations
        ? 'Creations'
        : 'Recent tasks';
    return FeatureScaffold(
      title: title,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FeatureSearchField(
              hint: 'Search ${title.toLowerCase()}',
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: skills
                ? ListView(
                    children: _skills
                        .where(
                          (skill) => skill.$1.toLowerCase().contains(_query),
                        )
                        .map(
                          (skill) => ListTile(
                            leading: const Icon(Icons.extension_outlined),
                            title: Text(skill.$1),
                            subtitle: Text(skill.$2),
                            onTap: () => context.pop(skill.$2),
                          ),
                        )
                        .toList(),
                  )
                : ref
                      .watch(conversationHistoryProvider)
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: TextButton(
                            onPressed: () =>
                                ref.invalidate(conversationHistoryProvider),
                            child: const Text('Could not load tasks. Retry'),
                          ),
                        ),
                        data: (history) {
                          final filtered = history
                              .where(
                                (task) =>
                                    !task.isArchived &&
                                    task.title.toLowerCase().contains(_query),
                              )
                              .toList();
                          if (filtered.isEmpty) {
                            return Center(
                              child: Text(
                                creations ? 'No creations yet' : 'No tasks yet',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final task = filtered[index];
                              return ListTile(
                                leading: Icon(
                                  creations
                                      ? Icons.description_outlined
                                      : Icons.chat_bubble_outline_rounded,
                                ),
                                title: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.add_rounded),
                                onTap: () async {
                                  final messages = await ref
                                      .read(chatRepositoryProvider)
                                      .loadMessages(task.id);
                                  final content = messages
                                      .where(
                                        (message) => creations
                                            ? message.role ==
                                                      ChatRole.assistant &&
                                                  message.status ==
                                                      MessageStatus.complete
                                            : true,
                                      )
                                      .map(
                                        (message) =>
                                            '${message.role.name}: ${message.content}',
                                      )
                                      .join('\n\n');
                                  if (!context.mounted) return;
                                  if (content.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'This task has no completed creation yet.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  context.pop(
                                    'Context from "${task.title}":\n$content',
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
