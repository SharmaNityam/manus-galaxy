import '../entities/chat_attachment.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class StreamChatReply {
  const StreamChatReply(this._repository);

  final ChatRepository _repository;

  Stream<String> call(
    String prompt, {
    List<ChatAttachment> attachments = const [],
    List<ChatMessage> history = const [],
  }) => _repository.streamReply(
    prompt,
    attachments: attachments,
    history: history,
  );
}
