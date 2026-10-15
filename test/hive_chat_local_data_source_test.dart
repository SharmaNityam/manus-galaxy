import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:manus_trial_app/features/chat/data/datasources/hive_chat_local_data_source.dart';
import 'package:manus_trial_app/features/chat/domain/entities/chat_message.dart';

void main() {
  late Directory tempDirectory;
  late Box<Map> box;
  late HiveChatLocalDataSource source;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('manus-chat-');
    Hive.init(tempDirectory.path);
    box = await Hive.openBox<Map>('conversations');
  });

  setUp(() async {
    await box.clear();
    source = HiveChatLocalDataSource(box);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'recovers an interrupted partial response and keeps it locally',
    () async {
      final messages = [
        ChatMessage(
          id: 'assistant-1',
          role: ChatRole.assistant,
          content: 'partial answer',
          createdAt: DateTime.utc(2026, 10, 13),
          status: MessageStatus.streaming,
        ),
      ];
      await source.saveMessages('conversation-1', messages);

      final reopened = await source.loadMessages('conversation-1');

      expect(reopened.single.content, 'partial answer');
      expect(reopened.single.status, MessageStatus.stopped);
      expect(
        (await source.loadMessages('conversation-1')).single.status,
        MessageStatus.stopped,
      );
    },
  );

  test('delete invalidates the bounded in-memory message cache', () async {
    await source.saveMessages('conversation-1', [
      ChatMessage(
        id: 'message-1',
        role: ChatRole.user,
        content: 'before delete',
        createdAt: DateTime.utc(2026, 10, 13),
        status: MessageStatus.complete,
      ),
    ]);
    expect(
      (await source.loadMessages('conversation-1')).single.content,
      'before delete',
    );

    await source.deleteConversation('conversation-1');

    expect(await source.loadMessages('conversation-1'), isEmpty);
  });

  test('archive state persists with the conversation summary', () async {
    await source.saveMessages('conversation-archive', [
      ChatMessage(
        id: 'message-archive',
        role: ChatRole.user,
        content: 'keep this chat',
        createdAt: DateTime.utc(2026, 10, 13),
        status: MessageStatus.complete,
      ),
    ]);

    await source.setConversationArchived('conversation-archive', true);

    final summary = (await source.loadConversations()).single;
    expect(summary.isArchived, isTrue);

    await source.saveMessages(
      'conversation-archive',
      await source.loadMessages('conversation-archive'),
    );
    expect((await source.loadConversations()).single.isArchived, isTrue);
  });
}
