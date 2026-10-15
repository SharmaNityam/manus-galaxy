import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_remote_data_source.dart';

class UnconfiguredChatRemoteDataSource implements ChatRemoteDataSource {
  const UnconfiguredChatRemoteDataSource(this.provider);

  final String provider;

  @override
  Stream<String> streamReply(
    String prompt, {
    List<ChatAttachment> attachments = const [],
    List<ChatMessage> history = const [],
  }) => Stream.error(
    StateError(
      '$provider is selected, but no API key is configured. Add the key using a local dart define.',
    ),
  );
}
