import 'package:dio/dio.dart';
import 'package:manus_trial_app/features/chat/data/datasources/remote_chat_failure.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:manus_trial_app/features/chat/data/datasources/remote_chat_content.dart';
import 'package:manus_trial_app/features/chat/domain/entities/chat_attachment.dart';
import 'package:manus_trial_app/features/chat/domain/entities/chat_message.dart';

void main() {
  test('rate limits produce a clear retryable message', () {
    final options = RequestOptions(path: '/chat');
    final failure = describeRemoteFailure(
      DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 429),
        type: DioExceptionType.badResponse,
      ),
    );
    expect(failure.message, contains('rate limited'));
    expect(failure.message, contains('Try again'));
  });
  final text = ChatAttachment(
    id: 'a',
    name: 'notes.txt',
    mimeType: 'text/plain',
    base64Data: base64Encode(utf8.encode('Trip budget: 5000')),
    size: 17,
  );
  final image = ChatAttachment(
    id: 'b',
    name: 'photo.png',
    mimeType: 'image/png',
    base64Data: base64Encode([1, 2, 3]),
    size: 3,
  );
  test('attachments survive message serialization with exact bytes', () {
    final message = ChatMessage(
      id: 'u',
      role: ChatRole.user,
      content: 'Review this',
      createdAt: DateTime(2026),
      status: MessageStatus.queued,
      attachments: [text, image],
    );
    final recovered = ChatMessage.fromMap(message.toMap());
    expect(recovered.attachments[0].bytes, text.bytes);
    expect(recovered.attachments[1].mimeType, 'image/png');
    expect(
      recovered.copyWith(status: MessageStatus.complete).attachments.length,
      2,
    );
  });
  test('OpenRouter receives image bytes and decoded document contents', () {
    final parts =
        openRouterContent('Read these', [text, image])
            as List<Map<String, Object?>>;
    expect(parts[1]['text'], contains('Trip budget: 5000'));
    expect(parts[2]['image_url'], {'url': 'data:image/png;base64,AQID'});
  });
  test(
    'Gemini receives inline image data and text files in separate parts',
    () {
      final parts = geminiContent('', [text, image]);
      expect(parts[0]['text'], 'Please review the attached files.');
      expect(parts[1]['text'], contains('Trip budget: 5000'));
      expect(parts[2]['inlineData'], {'mimeType': 'image/png', 'data': 'AQID'});
    },
  );
}
