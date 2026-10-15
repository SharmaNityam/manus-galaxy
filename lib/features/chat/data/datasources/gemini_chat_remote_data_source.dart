import 'remote_chat_failure.dart';
import 'remote_chat_content.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'chat_remote_data_source.dart';

class GeminiChatRemoteDataSource implements ChatRemoteDataSource {
  GeminiChatRemoteDataSource({
    required String apiKey,
    Dio? dio,
    this.model = 'gemini-3.8-flash',
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
        'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse',
        data: {
          'contents': [
            for (final message in history)
              {
                'role': message.role == ChatRole.assistant ? 'model' : 'user',
                'parts': geminiContent(message.content, message.attachments),
              },
            {'role': 'user', 'parts': geminiContent(prompt, attachments)},
          ],
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'x-goog-api-key': _apiKey},
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
        final candidates = event['candidates'];
        if (candidates is! List || candidates.isEmpty) continue;
        final content = candidates.first['content'];
        if (content is! Map<String, dynamic>) continue;
        final parts = content['parts'];
        if (parts is! List) continue;
        for (final part in parts) {
          if (part is Map<String, dynamic> && part['text'] is String) {
            final text = part['text'] as String;
            if (text.isNotEmpty) {
              receivedText = true;
              yield text;
            }
          }
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
