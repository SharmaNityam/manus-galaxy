import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manus_trial_app/core/theme/app_theme.dart';
import 'package:manus_trial_app/features/chat/domain/entities/chat_attachment.dart';
import 'package:manus_trial_app/features/chat/presentation/widgets/chat_composer.dart';
import 'package:manus_trial_app/features/composer/data/native_attachment_picker.dart';
import 'package:manus_trial_app/features/composer/domain/attachment_library.dart';
import 'package:manus_trial_app/features/composer/domain/speech_input.dart';
import 'package:manus_trial_app/features/composer/presentation/composer_providers.dart';
import 'package:manus_trial_app/features/connectors/presentation/connectors_screen.dart';
import 'package:manus_trial_app/features/connectors/presentation/connector_detail_screen.dart';

final _file = ChatAttachment(
  id: 'notes',
  name: 'notes.txt',
  mimeType: 'text/plain',
  base64Data: base64Encode(utf8.encode('A real attachment')),
  size: 17,
);

void main() {
  Future<void> mount(
    WidgetTester tester,
    List<ChatDraft> sent, {
    SpeechInput? speech,
    Size size = const Size(360, 800),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatComposer(homeStyle: true, onSend: sent.add),
            ),
          ),
        ),
        GoRoute(
          path: '/connectors',
          builder: (_, _) => const ConnectorsScreen(),
        ),
        GoRoute(
          path: '/connectors/manage',
          builder: (_, _) => const ConnectorsScreen(manage: true),
        ),
        GoRoute(
          path: '/connectors/:id',
          builder: (_, state) =>
              ConnectorDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attachmentPickerProvider.overrideWithValue(_Picker()),
          attachmentLibraryProvider.overrideWithValue(_Library()),
          if (speech != null) speechInputProvider.overrideWithValue(speech),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'send stays disabled until there is a draft, and sends only once',
    (tester) async {
      final sent = <ChatDraft>[];
      await mount(tester, sent);
      await tester.tap(find.byTooltip('Send message'));
      expect(sent, isEmpty);
      await tester.enterText(find.byType(TextField), 'Plan a weekend trip.');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(sent.single.text, 'Plan a weekend trip.');
      await tester.tap(find.byTooltip('Send message'));
      expect(sent.length, 1);
    },
  );

  testWidgets(
    'add sheet selects a real attachment, persists it, and sends its bytes',
    (tester) async {
      final sent = <ChatDraft>[];
      await mount(tester, sent);
      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();
      expect(find.text('Add to chat'), findsOneWidget);
      for (final label in [
        'Camera',
        'Picture',
        'File',
        'Library',
        'Creations',
        'Recent tasks',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('notes.txt'), findsOneWidget);
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(
        sent.single.attachments.single.bytes,
        utf8.encode('A real attachment'),
      );
      expect(find.text('notes.txt'), findsNothing);
    },
  );

  testWidgets(
    'connector button opens menu, searchable catalogue, and matching detail',
    (tester) async {
      await mount(tester, []);
      await tester.tap(find.byTooltip('Connectors'));
      await tester.pumpAndSettle();
      expect(find.text('Manage connectors'), findsOneWidget);
      expect(find.text('Shopify'), findsOneWidget);
      await tester.tap(find.text('Add connectors'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'GitHub');
      await tester.pumpAndSettle();
      expect(find.text('Shopify'), findsNothing);
      await tester.tap(find.text('GitHub').last);
      await tester.pumpAndSettle();
      expect(find.text('Additional configuration required.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Account connection is not configured'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'dictation confirms into the draft before any send, and supports cancel',
    (tester) async {
      final speech = _Speech();
      final sent = <ChatDraft>[];
      await mount(tester, sent, speech: speech);
      await tester.tap(find.byTooltip('Voice input'));
      await tester.pumpAndSettle();
      expect(speech.started, isTrue);
      expect(find.byTooltip('Cancel recording'), findsOneWidget);
      speech.onText!('Explain offline recovery.');
      await tester.pump();
      await tester.tap(find.byTooltip('Use transcription'));
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
      expect(find.text('Explain offline recovery.'), findsOneWidget);
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(sent.single.text, 'Explain offline recovery.');
      await tester.tap(find.byTooltip('Voice input'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel recording'));
      await tester.pumpAndSettle();
      expect(speech.cancelled, greaterThan(0));
      expect(sent.length, 1);
    },
  );

  testWidgets('composer and add sheet stay usable at 320 dp with larger text', (
    tester,
  ) async {
    await mount(tester, [], size: const Size(320, 640), textScale: 1.3);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Add attachment'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Picture'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _Library implements AttachmentLibrary {
  final files = <ChatAttachment>[];
  @override
  List<ChatAttachment> load() => files;
  @override
  Future<void> save(ChatAttachment attachment) async {
    files.add(attachment);
  }
}

class _Picker extends NativeAttachmentPicker {
  @override
  Future<List<ChatAttachment>> recoverImages() async => [];
  @override
  Future<List<ChatAttachment>> files() async => [_file];
  @override
  Future<List<ChatAttachment>> pictures() async => [_file];
}

class _Speech implements SpeechInput {
  bool started = false;
  int cancelled = 0;
  void Function(String)? onText;
  @override
  Future<bool> start({
    required void Function(String) onText,
    required void Function(String) onError,
    required void Function() onDone,
    required void Function(double) onLevel,
  }) async {
    started = true;
    this.onText = onText;
    return true;
  }

  @override
  Future<String> finish() async => 'Explain offline recovery.';
  @override
  Future<void> cancel() async {
    cancelled++;
  }
}
