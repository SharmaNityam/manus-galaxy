import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../chat/domain/entities/chat_attachment.dart';
import '../domain/attachment_library.dart';

class HiveAttachmentLibrary implements AttachmentLibrary {
  const HiveAttachmentLibrary(this.box);
  final Box<Map> box;

  @override
  List<ChatAttachment> load() =>
      box.values.map(ChatAttachment.fromMap).toList().reversed.toList();

  @override
  Future<void> save(ChatAttachment attachment) async {
    await box.put(attachment.id, attachment.toMap());
    while (box.length > 40) {
      await box.deleteAt(0);
    }
  }
}
