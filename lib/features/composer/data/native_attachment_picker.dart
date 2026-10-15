import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../chat/domain/entities/chat_attachment.dart';

class NativeAttachmentPicker {
  final _images = ImagePicker();

  Future<List<ChatAttachment>> camera() async {
    final image = await _images.pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    return image == null ? [] : [await _fromImage(image)];
  }

  Future<List<ChatAttachment>> pictures() async {
    final images = await _images.pickMultiImage(
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
      limit: 4,
      requestFullMetadata: false,
    );
    return Future.wait(images.map(_fromImage));
  }

  Future<List<ChatAttachment>> files() async {
    final files = await FilePicker.pickFiles();
    final result = <ChatAttachment>[];
    for (final file in files.take(4)) {
      if ((await file.length() ?? 0) > 5 * 1024 * 1024) {
        throw const FormatException('Choose files smaller than 5 MB.');
      }
      result.add(_create(file.name, await file.readAsBytes()));
    }
    return result;
  }

  Future<List<ChatAttachment>> recoverImages() async {
    final lost = await _images.retrieveLostData();
    if (lost.exception != null) throw lost.exception!;
    return Future.wait((lost.files ?? <XFile>[]).map(_fromImage));
  }

  Future<ChatAttachment> _fromImage(XFile image) async =>
      _create(image.name, await image.readAsBytes());

  ChatAttachment _create(String name, Uint8List bytes) {
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Choose files smaller than 5 MB.');
    }
    final extension = name.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'json' => 'application/json',
      'txt' ||
      'md' ||
      'csv' ||
      'dart' ||
      'js' ||
      'py' ||
      'html' ||
      'css' ||
      'xml' ||
      'yaml' ||
      'yml' => 'text/plain',
      _ => 'application/octet-stream',
    };
    if (mime == 'application/octet-stream') {
      throw const FormatException('Choose an image, PDF, or text file.');
    }
    return ChatAttachment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      mimeType: mime,
      base64Data: base64Encode(bytes),
      size: bytes.length,
    );
  }
}
