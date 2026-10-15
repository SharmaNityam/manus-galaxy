import 'package:manus_trial_app/features/chat/domain/entities/chat_attachment.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manus_trial_app/features/chat/data/datasources/network_status_source.dart';
import 'package:manus_trial_app/features/chat/presentation/controllers/outbox_sync_coordinator.dart';
import 'package:manus_trial_app/features/chat/domain/entities/chat_message.dart';
import 'package:manus_trial_app/features/chat/domain/entities/conversation_summary.dart';
import 'package:manus_trial_app/features/chat/domain/entities/pending_operation.dart';
import 'package:manus_trial_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:manus_trial_app/features/chat/presentation/providers/chat_providers.dart';

void main() {
  late _FakeChatRepository repository;
  late _FakeNetworkStatus network;
  late OutboxSyncCoordinator syncCoordinator;
  late ProviderContainer container;
  late ChatController controller;

  setUp(() async {
    repository = _FakeChatRepository();
    network = _FakeNetworkStatus();
    syncCoordinator = OutboxSyncCoordinator(
      repository: repository,
      networkStatus: network,
    );
    await syncCoordinator.start();
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        outboxSyncCoordinatorProvider.overrideWith((ref) => syncCoordinator),
      ],
    );
    controller = container.read(chatControllerProvider.notifier);
  });

  tearDown(() {
    container.dispose();
    network.dispose();
    repository.dispose();
  });

  test('streams chunks, saves partial text, and stops idempotently', () async {
    final conversationId = controller.newConversation();
    await controller.send('hello');
    repository.streams.single.add('partial');
    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(controller.state.messages.last.content, 'partial');
    await controller.stop();
    await controller.stop();

    expect(controller.state.isStreaming, isFalse);
    expect(controller.state.messages.last.status, MessageStatus.stopped);
    expect(repository.cancelled.single, isTrue);
    expect(repository.saved.last.$1, conversationId);
    expect(repository.saved.last.$2.last.content, 'partial');
  });

  test(
    'connectivity loss stops the stream and preserves partial text',
    () async {
      controller.newConversation();
      await controller.send('keep my partial answer');
      repository.streams.single.add('partial answer');
      await Future<void>.delayed(const Duration(milliseconds: 90));

      network.setOnline(false);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isStreaming, isFalse);
      expect(controller.state.messages.last.content, 'partial answer');
      expect(controller.state.messages.last.status, MessageStatus.stopped);
      expect(repository.cancelled.single, isTrue);
    },
  );

  test(
    'mode instructions reach the model but stay out of the user bubble',
    () async {
      controller.newConversation();
      await controller.send(
        'Explain offline recovery',
        contextInstruction: 'Answer concisely and use practical steps.',
      );

      expect(
        repository.prompts.single,
        'Answer concisely and use practical steps.\n\nUser request: Explain offline recovery',
      );
      expect(
        controller.state.messages.first.content,
        'Explain offline recovery',
      );
    },
  );

  test(
    'retry resends the preceding user prompt after a stream failure',
    () async {
      final conversationId = controller.newConversation();
      await controller.send('try again');
      repository.streams.single.addError(StateError('network'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.messages.last.status, MessageStatus.failed);
      await controller.retryLast();

      expect(repository.prompts, ['try again', 'try again']);
      expect(controller.state.conversationId, conversationId);
      expect(controller.state.isStreaming, isTrue);
      expect(controller.state.messages.last.id, isNotEmpty);
      expect(controller.state.messages.last.content, isEmpty);
    },
  );

  test('retry action targets its own earlier failed response', () async {
    controller.newConversation();
    await controller.send('first prompt');
    repository.streams[0].addError(StateError('network'));
    await Future<void>.delayed(Duration.zero);
    final firstAssistantId = controller.state.messages.last.id;

    await controller.send('second prompt');
    repository.streams[1].add('done');
    await repository.streams[1].close();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await controller.retryMessage(firstAssistantId);

    expect(repository.prompts, [
      'first prompt',
      'second prompt',
      'first prompt',
    ]);
    expect(controller.state.messages[1].id, firstAssistantId);
    expect(controller.state.messages[1].status, MessageStatus.streaming);
  });

  test(
    'opening another conversation cancels and isolates the old stream',
    () async {
      final oldConversation = controller.newConversation();
      await controller.send('old prompt');
      await controller.openConversation('saved-conversation');
      repository.streams.first.add('stale event');
      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(repository.cancelled.first, isTrue);
      expect(controller.state.conversationId, 'saved-conversation');
      expect(controller.state.messages, isEmpty);
      expect(repository.saved.first.$1, oldConversation);
      expect(repository.saved.last.$2.last.status, MessageStatus.stopped);
    },
  );

  test(
    'queues an offline send and streams it once the queue replays',
    () async {
      network.setOnline(false);
      await Future<void>.delayed(Duration.zero);
      controller.newConversation();
      await controller.send('offline prompt');

      expect(controller.state.messages.last.status, MessageStatus.queued);
      expect(repository.operations.single.type, ChatOperationType.send);
      expect(repository.streams, isEmpty);

      network.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.prompts, ['offline prompt']);
      expect(controller.state.messages.last.status, MessageStatus.streaming);
      expect(repository.operations, isEmpty);
    },
  );
  test(
    'follow-up receives preceding turns, while a new chat starts without them',
    () async {
      controller.newConversation();
      await controller.send('My budget is 5000.');
      repository.streams.first.add('I will use that budget.');
      await repository.streams.first.close();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await controller.send('What was my budget?');
      expect(repository.histories.last.map((message) => message.content), [
        'My budget is 5000.',
        'I will use that budget.',
      ]);
      controller.newConversation();
      await controller.send('A separate task');
      expect(repository.histories.last, isEmpty);
    },
  );

  test('queued attachments survive replay and an explicit retry', () async {
    const attachment = ChatAttachment(
      id: 'file',
      name: 'photo.png',
      mimeType: 'image/png',
      base64Data: 'AQID',
      size: 3,
    );
    network.setOnline(false);
    await Future<void>.delayed(Duration.zero);
    controller.newConversation();
    await controller.send('Review this', attachments: [attachment]);
    expect(controller.state.messages.first.attachments.single.id, 'file');
    network.setOnline(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(repository.attachments.last.single.base64Data, 'AQID');
    await controller.stop();
    await controller.retryLast();
    expect(repository.attachments.last.single.base64Data, 'AQID');
  });
}

class _FakeChatRepository implements ChatRepository {
  final streams = <StreamController<String>>[];
  final prompts = <String>[];
  final histories = <List<ChatMessage>>[];
  final attachments = <List<ChatAttachment>>[];
  final saved = <(String, List<ChatMessage>)>[];
  final cancelled = <bool>[];
  final operations = <PendingOperation>[];
  final messagesByConversation = <String, List<ChatMessage>>{};

  @override
  Stream<String> streamReply(
    String prompt, {
    List<ChatAttachment> attachments = const [],
    List<ChatMessage> history = const [],
  }) {
    prompts.add(prompt);
    histories.add(history);
    this.attachments.add(attachments);
    late final StreamController<String> stream;
    stream = StreamController<String>(
      onCancel: () {
        cancelled.add(true);
      },
    );
    streams.add(stream);
    return stream.stream;
  }

  @override
  Future<List<ConversationSummary>> loadConversations() async => const [];

  @override
  Future<List<ChatMessage>> loadMessages(String conversationId) async =>
      List.of(messagesByConversation[conversationId] ?? const []);

  @override
  Future<void> saveMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    saved.add((conversationId, List.of(messages)));
    messagesByConversation[conversationId] = List.of(messages);
  }

  @override
  Future<void> renameConversation(String conversationId, String title) async {}

  @override
  Future<void> setConversationPinned(
    String conversationId,
    bool isPinned,
  ) async {}

  @override
  Future<void> setConversationArchived(
    String conversationId,
    bool isArchived,
  ) async {}

  @override
  Future<void> deleteConversation(String conversationId) async {}

  @override
  Future<void> enqueueOperation(PendingOperation operation) async {
    operations.add(operation);
  }

  @override
  Future<List<PendingOperation>> replayQueuedOperations() async {
    final queued = List<PendingOperation>.of(operations);
    operations.clear();
    return queued;
  }

  @override
  Future<int> pendingOperationCount() async => operations.length;

  @override
  Future<bool> hasPendingOperation(String id) async =>
      operations.any((operation) => operation.id == id);

  Future<void> dispose() async {
    for (final stream in streams) {
      await stream.close();
    }
  }
}

class _FakeNetworkStatus implements NetworkStatusSource {
  final _controller = StreamController<bool>.broadcast();
  bool online = true;

  @override
  Stream<bool> get changes => _controller.stream;

  @override
  Future<bool> isOnline() async => online;

  void setOnline(bool value) {
    online = value;
    _controller.add(value);
  }

  void dispose() => _controller.close();
}
