import '../repositories/chat_repository.dart';

class StreamChatReply {
  const StreamChatReply(this._repository);

  final ChatRepository _repository;

  Stream<String> call(String prompt) => _repository.streamReply(prompt);
}
