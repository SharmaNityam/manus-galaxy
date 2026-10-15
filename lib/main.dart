import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/composer/data/hive_attachment_library.dart';
import 'features/composer/presentation/composer_providers.dart';
import 'features/chat/data/datasources/hive_chat_local_data_source.dart';
import 'features/chat/data/datasources/hive_outbox_data_source.dart';
import 'features/chat/data/datasources/gemini_chat_remote_data_source.dart';
import 'features/chat/data/datasources/open_router_chat_remote_data_source.dart';
import 'features/chat/data/datasources/mock_chat_remote_data_source.dart';
import 'features/chat/data/datasources/mock_history_remote_data_source.dart';
import 'features/chat/data/datasources/unconfigured_chat_remote_data_source.dart';
import 'features/chat/data/datasources/connectivity_network_status_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/presentation/controllers/outbox_sync_coordinator.dart';
import 'features/chat/presentation/providers/chat_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final conversations = await Hive.openBox<Map>('conversations');
  final outbox = await Hive.openBox<Map>('outbox');
  final attachments = await Hive.openBox<Map>('attachments');
  final appliedOperations = await Hive.openBox<Map>('mock_remote_operations');
  final remoteHistory = await Hive.openBox<Map>('mock_remote_history');
  const provider = String.fromEnvironment(
    'CHAT_PROVIDER',
    defaultValue: 'gemini',
  );
  const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  const openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  final repository = ChatRepositoryImpl(
    localDataSource: HiveChatLocalDataSource(conversations),
    outboxDataSource: HiveOutboxDataSource(outbox),
    historyRemoteDataSource: MockHistoryRemoteDataSource(
      appliedOperations: appliedOperations,
      remoteHistory: remoteHistory,
    ),
    remoteDataSource: switch (provider) {
      'openrouter' when openRouterApiKey.isNotEmpty =>
        OpenRouterChatRemoteDataSource(apiKey: openRouterApiKey),
      'gemini' when geminiApiKey.isNotEmpty => GeminiChatRemoteDataSource(
        apiKey: geminiApiKey,
      ),
      'mock' => MockChatRemoteDataSource(),
      _ => UnconfiguredChatRemoteDataSource(provider),
    },
  );
  final syncCoordinator = OutboxSyncCoordinator(
    repository: repository,
    networkStatus: ConnectivityNetworkStatusSource(Connectivity()),
  );
  runApp(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        attachmentLibraryProvider.overrideWithValue(
          HiveAttachmentLibrary(attachments),
        ),
        outboxSyncCoordinatorProvider.overrideWith((ref) => syncCoordinator),
      ],
      child: const ManusTrialApp(),
    ),
  );
  unawaited(syncCoordinator.start());
}
