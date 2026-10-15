import 'dart:convert';
import 'dart:typed_data';

class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.base64Data,
    required this.size,
  });

  final String id;
  final String name;
  final String mimeType;
  final String base64Data;
  final int size;

  bool get isImage => mimeType.startsWith('image/');
  bool get isText =>
      mimeType.startsWith('text/') || mimeType == 'application/json';
  Uint8List get bytes => base64Decode(base64Data);
  String get dataUrl => 'data:$mimeType;base64,$base64Data';
  String get readableSize => size < 1024 * 1024
      ? '${(size / 1024).ceil()} KB'
      : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'mimeType': mimeType,
    'base64Data': base64Data,
    'size': size,
  };

  factory ChatAttachment.fromMap(Map<dynamic, dynamic> map) => ChatAttachment(
    id: map['id'] as String,
    name: map['name'] as String,
    mimeType: map['mimeType'] as String,
    base64Data: map['base64Data'] as String,
    size: map['size'] as int,
  );
}

class ChatDraft {
  const ChatDraft({required this.text, this.attachments = const []});
  final String text;
  final List<ChatAttachment> attachments;
}
