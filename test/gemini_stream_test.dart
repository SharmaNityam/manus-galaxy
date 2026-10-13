import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manus_trial_app/features/chat/data/datasources/gemini_chat_remote_data_source.dart';

void main() {
  test(
    'parses separate Gemini SSE text events and sends the key in a header',
    () async {
      final adapter = _SseAdapter('''
data: {"candidates":[{"content":{"parts":[{"text":"Hello "}]}}]}

data: {"candidates":[{"content":{"parts":[{"text":"world"}]}}]}

''');
      final dio = Dio()..httpClientAdapter = adapter;
      final source = GeminiChatRemoteDataSource(apiKey: 'test-key', dio: dio);

      expect(await source.streamReply('hi').toList(), ['Hello ', 'world']);
      expect(adapter.options?.headers['x-goog-api-key'], 'test-key');
      expect(
        adapter.options?.path,
        contains('models/gemini-3.8-flash:streamGenerateContent'),
      );
      expect(adapter.options?.uri.queryParameters['alt'], 'sse');
      dio.close();
    },
  );
}

class _SseAdapter implements HttpClientAdapter {
  _SseAdapter(this.body);

  final String body;
  RequestOptions? options;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        'content-type': ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
