import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/chat/data/datasources/hive_chat_local_data_source.dart';
import 'features/chat/data/datasources/mock_chat_remote_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/presentation/providers/chat_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final conversations = await Hive.openBox<Map>('conversations');
  final repository = ChatRepositoryImpl(
    localDataSource: HiveChatLocalDataSource(conversations),
    remoteDataSource: MockChatRemoteDataSource(),
  );

  runApp(
    ProviderScope(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
      child: const ManusTrialApp(),
    ),
  );
}
