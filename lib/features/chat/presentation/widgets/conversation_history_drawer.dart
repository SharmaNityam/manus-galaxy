import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/conversation_summary.dart';
import '../controllers/outbox_sync_coordinator.dart';
import '../providers/chat_providers.dart';

class ConversationHistoryDrawer extends ConsumerWidget {
  const ConversationHistoryDrawer({this.activeConversationId, super.key});

  final String? activeConversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final history = ref.watch(conversationHistoryProvider);
    final sync = ref.watch(outboxSyncCoordinatorProvider);

    return Drawer(
      width: width < 420 ? width * 0.88 : 360,
      backgroundColor: const Color(0xFFF7F7F5),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chats',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close history',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
                icon: const Icon(Icons.add_rounded),
                label: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('New chat'),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppTheme.primaryText,
                  backgroundColor: const Color(0xFFECECE9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  Icon(
                    _syncIcon(sync.status),
                    size: 17,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _syncLabel(sync),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (sync.status == SyncStatus.failed)
                    TextButton(
                      onPressed: sync.retry,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: history.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, stackTrace) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chat history could not be loaded.'),
                  ),
                ),
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'Your conversations will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.secondaryText),
                        ),
                      ),
                    );
                  }
                  return _ConversationList(
                    conversations: conversations,
                    activeConversationId: activeConversationId,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _syncIcon(SyncStatus status) => switch (status) {
    SyncStatus.checking => Icons.sync_rounded,
    SyncStatus.offline => Icons.cloud_off_outlined,
    SyncStatus.online => Icons.cloud_done_outlined,
    SyncStatus.syncing => Icons.sync_rounded,
    SyncStatus.failed => Icons.cloud_off_outlined,
  };

  String _syncLabel(OutboxSyncCoordinator sync) => switch (sync.status) {
    SyncStatus.checking => 'Checking connection',
    SyncStatus.offline =>
      sync.pendingCount == 0
          ? 'Offline'
          : '${sync.pendingCount} changes waiting to sync',
    SyncStatus.online =>
      sync.pendingCount == 0
          ? 'Up to date'
          : '${sync.pendingCount} changes waiting to sync',
    SyncStatus.syncing => 'Syncing changes',
    SyncStatus.failed => sync.errorMessage ?? 'Sync failed',
  };
}

class _ConversationList extends ConsumerWidget {
  const _ConversationList({
    required this.conversations,
    required this.activeConversationId,
  });

  final List<ConversationSummary> conversations;
  final String? activeConversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = <String, List<ConversationSummary>>{};
    for (final conversation in conversations) {
      final section = _sectionFor(conversation);
      sections.putIfAbsent(section, () => []).add(conversation);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        for (final entry in sections.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 16, 6),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final conversation in entry.value)
            _ConversationTile(
              conversation: conversation,
              selected: conversation.id == activeConversationId,
            ),
        ],
      ],
    );
  }

  String _sectionFor(ConversationSummary conversation) {
    if (conversation.isPinned) return 'Pinned';
    final now = DateTime.now();
    final date = conversation.updatedAt;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return 'Earlier';
  }
}

enum _HistoryAction { rename, pin, delete }

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation, required this.selected});

  final ConversationSummary conversation;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? const Color(0xFFECECE9) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          minTileHeight: 52,
          contentPadding: const EdgeInsets.only(left: 14, right: 4),
          leading: Icon(
            conversation.isPinned
                ? Icons.push_pin_outlined
                : Icons.chat_bubble_outline_rounded,
            size: 20,
            color: AppTheme.secondaryText,
          ),
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          onTap: () {
            Navigator.of(context).pop();
            context.go('/chat/${conversation.id}');
          },
          trailing: PopupMenuButton<_HistoryAction>(
            tooltip: 'Chat options',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (action) => _handleAction(context, ref, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _HistoryAction.rename,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Rename'),
                ),
              ),
              PopupMenuItem(
                value: _HistoryAction.pin,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    conversation.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin,
                  ),
                  title: Text(conversation.isPinned ? 'Unpin' : 'Pin'),
                ),
              ),
              const PopupMenuItem(
                value: _HistoryAction.delete,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _HistoryAction action,
  ) async {
    final history = ref.read(manageConversationHistoryProvider);
    switch (action) {
      case _HistoryAction.rename:
        final controller = TextEditingController(text: conversation.title);
        final title = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rename chat'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Chat name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        controller.dispose();
        if (title != null && title.isNotEmpty) {
          await history.rename(conversation.id, title);
        }
      case _HistoryAction.pin:
        await history.setPinned(conversation.id, !conversation.isPinned);
      case _HistoryAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete chat?'),
            content: const Text(
              'This conversation will be removed from this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await history.delete(conversation.id);
          if (selected && context.mounted) {
            Navigator.of(context).pop();
            context.go('/');
          }
        }
    }
    await ref.read(outboxSyncCoordinatorProvider).refresh();
    ref.invalidate(conversationHistoryProvider);
  }
}
