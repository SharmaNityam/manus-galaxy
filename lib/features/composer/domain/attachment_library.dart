import '../../chat/domain/entities/chat_attachment.dart';

abstract interface class AttachmentLibrary {
  List<ChatAttachment> load();
  Future<void> save(ChatAttachment attachment);
}
