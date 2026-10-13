import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:manus_trial_app/features/chat/data/datasources/hive_outbox_data_source.dart';
import 'package:manus_trial_app/features/chat/data/datasources/mock_history_remote_data_source.dart';
import 'package:manus_trial_app/features/chat/domain/entities/pending_operation.dart';

void main() {
  late Directory tempDirectory;
  late Box<Map> outboxBox;
  late Box<Map> appliedBox;
  late Box<Map> historyBox;
  late HiveOutboxDataSource outbox;
  late MockHistoryRemoteDataSource remote;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('manus-outbox-');
    Hive.init(tempDirectory.path);
    outboxBox = await Hive.openBox<Map>('outbox');
    appliedBox = await Hive.openBox<Map>('applied');
    historyBox = await Hive.openBox<Map>('history');
  });

  setUp(() async {
    await outboxBox.clear();
    await appliedBox.clear();
    await historyBox.clear();
    outbox = HiveOutboxDataSource(outboxBox);
    remote = MockHistoryRemoteDataSource(
      appliedOperations: appliedBox,
      remoteHistory: historyBox,
    );
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'replays six offline actions in order and de-duplicates operation IDs',
    () async {
      final time = DateTime.utc(2026, 10, 13, 12);
      final operations = [
        _operation('01', 'chat-a', ChatOperationType.rename, time, {
          'title': 'A',
        }),
        _operation('02', 'chat-a', ChatOperationType.rename, time, {
          'title': 'A2',
        }),
        _operation('03', 'chat-b', ChatOperationType.rename, time, {
          'title': 'B',
        }),
        _operation('04', 'chat-c', ChatOperationType.delete, time, const {}),
        _operation('05', 'chat-d', ChatOperationType.pin, time, {
          'isPinned': true,
        }),
        _operation('06', 'chat-e', ChatOperationType.send, time, {
          'prompt': 'hello',
        }),
      ];
      for (final operation in operations.reversed) {
        await outbox.enqueue(operation);
      }

      final ordered = await outbox.pending();
      expect(
        ordered.map((operation) => operation.id),
        operations.map((op) => op.id),
      );

      expect(await remote.apply(ordered.first), isTrue);
      expect(await remote.apply(ordered.first), isFalse);
      for (final operation in ordered.skip(1)) {
        await remote.apply(operation);
      }

      expect(appliedBox.length, 6);
      expect(historyBox.get('chat-a')?['title'], 'A2');
      expect(historyBox.get('chat-c')?['deleted'], isTrue);
      expect(historyBox.get('chat-d')?['isPinned'], isTrue);
      expect(historyBox.get('chat-e')?['messages'], ['hello']);
    },
  );

  test('keeps a newer remote value when an older local edit replays', () async {
    final operation = _operation(
      'old-edit',
      'chat-conflict',
      ChatOperationType.rename,
      DateTime.utc(2026, 10, 13, 10),
      {'title': 'Offline title'},
    );
    await historyBox.put('chat-conflict', {
      'title': 'Remote title',
      'updatedAt': DateTime.utc(2026, 10, 13, 11).toIso8601String(),
    });

    await remote.apply(operation);

    expect(historyBox.get('chat-conflict')?['title'], 'Remote title');
    expect(await remote.apply(operation), isFalse);
  });
}

PendingOperation _operation(
  String id,
  String conversationId,
  ChatOperationType type,
  DateTime createdAt,
  Map<String, Object?> payload,
) => PendingOperation(
  id: id,
  conversationId: conversationId,
  type: type,
  payload: payload,
  createdAt: createdAt,
);
