import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';

abstract interface class ChatRemoteDataSource {
  Stream<String> streamReply(
    String prompt, {
    List<ChatAttachment> attachments = const [],
    List<ChatMessage> history = const [],
  });
}
