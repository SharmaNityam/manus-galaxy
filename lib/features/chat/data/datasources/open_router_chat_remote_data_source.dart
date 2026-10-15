import 'remote_chat_failure.dart';
import 'remote_chat_content.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'chat_remote_data_source.dart';

class OpenRouterChatRemoteDataSource implements ChatRemoteDataSource {
  OpenRouterChatRemoteDataSource({
    required String apiKey,
    Dio? dio,
    this.model = 'google/gemma-4-31b-it:free',
  }) : _apiKey = apiKey,
       _dio = dio ?? Dio();

  final String _apiKey;
  final Dio _dio;
  final String model;

  @override
  Stream<String> streamReply(
    String prompt, {
    List<ChatAttachment> attachments = const [],
    List<ChatMessage> history = const [],
  }) async* {
    final cancelToken = CancelToken();
    var receivedText = false;
    try {
      final response = await _dio.post<ResponseBody>(
        'https://openrouter.ai/api/v1/chat/completions',
        data: {
          'model': model,
          'stream': true,
          'max_tokens': 512,
          'reasoning': {'enabled': false},
          if ([
            ...history.expand((message) => message.attachments),
            ...attachments,
          ].any((file) => file.mimeType == 'application/pdf'))
            'plugins': [
              {
                'id': 'file-parser',
                'pdf': {'engine': 'cloudflare-ai'},
              },
            ],
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant. Answer the user directly in natural language. Do not output internal safety labels, routing metadata, or classifications as the answer.',
            },
            for (final message in history)
              {
                'role': message.role.name,
                'content': openRouterContent(
                  message.content,
                  message.attachments,
                ),
              },
            {'role': 'user', 'content': openRouterContent(prompt, attachments)},
          ],
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        cancelToken: cancelToken,
      );
      final body = response.data;
      if (body == null) throw const FormatException('Empty stream response.');

      await for (final line
          in body.stream
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;
        final event = jsonDecode(payload);
        if (event is! Map<String, dynamic>) continue;
        final choices = event['choices'];
        if (choices is! List || choices.isEmpty) continue;
        final delta = choices.first['delta'];
        if (delta is! Map<String, dynamic>) continue;
        final text = delta['content'];
        if (text is String && text.isNotEmpty) {
          receivedText = true;
          yield text;
        }
      }
      if (!receivedText && !cancelToken.isCancelled) {
        throw const FormatException('The model returned no text.');
      }
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) throw describeRemoteFailure(error);
    } finally {
      if (!cancelToken.isCancelled) cancelToken.cancel('Stream closed.');
    }
  }
}
