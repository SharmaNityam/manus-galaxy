import 'package:go_router/go_router.dart';
import '../../features/composer/presentation/library_screen.dart';
import '../../features/composer/presentation/context_picker_screen.dart';
import '../../features/connectors/presentation/connectors_screen.dart';
import '../../features/connectors/presentation/connector_detail_screen.dart';

import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/home_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/composer/:kind',
      builder: (context, state) =>
          ContextPickerScreen(kind: state.pathParameters['kind']!),
    ),
    GoRoute(
      path: '/connectors',
      builder: (context, state) => const ConnectorsScreen(),
    ),
    GoRoute(
      path: '/connectors/manage',
      builder: (context, state) => const ConnectorsScreen(manage: true),
    ),
    GoRoute(
      path: '/connectors/:id',
      builder: (context, state) =>
          ConnectorDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (context, state) =>
          ChatScreen(conversationId: state.pathParameters['conversationId']!),
    ),
  ],
);
