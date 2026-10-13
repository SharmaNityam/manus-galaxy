import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manus_trial_app/features/chat/data/datasources/open_router_chat_remote_data_source.dart';

void main() {
  test('parses streamed OpenRouter deltas and sends bearer auth', () async {
    final adapter = _SseAdapter('''
data: {"choices":[{"delta":{"content":"Hello "}}]}

data: {"choices":[{"delta":{"content":"world"}}]}

data: [DONE]

''');
    final dio = Dio()..httpClientAdapter = adapter;
    final source = OpenRouterChatRemoteDataSource(apiKey: 'test-key', dio: dio);

    expect(await source.streamReply('hi').toList(), ['Hello ', 'world']);
    expect(adapter.options?.headers['Authorization'], 'Bearer test-key');
    expect(adapter.options?.uri.path, '/api/v1/chat/completions');
    expect(adapter.requestData?['model'], 'openrouter/free');
    expect(adapter.requestData?['stream'], true);
    expect(adapter.requestData?['max_tokens'], 512);
    expect(adapter.requestData?['reasoning'], {'enabled': false});
    dio.close();
  });
}

class _SseAdapter implements HttpClientAdapter {
  _SseAdapter(this.body);

  final String body;
  RequestOptions? options;
  Map<String, dynamic>? requestData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    requestData = options.data as Map<String, dynamic>;
    return ResponseBody.fromString(
      body,
      200,
      headers: {'content-type': ['text/event-stream']},
    );
  }

  @override
  void close({bool force = false}) {}
}
