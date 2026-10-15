import 'dart:convert';
import '../../domain/entities/chat_attachment.dart';

Object openRouterContent(String text, List<ChatAttachment> attachments) {
  if (attachments.isEmpty) return text;
  return <Map<String, Object?>>[
    {
      'type': 'text',
      'text': text.isEmpty ? 'Please review the attached files.' : text,
    },
    for (final file in attachments)
      if (file.isImage)
        {
          'type': 'image_url',
          'image_url': {'url': file.dataUrl},
        }
      else if (file.isText)
        {
          'type': 'text',
          'text':
              'File: ${file.name}\n${utf8.decode(file.bytes, allowMalformed: true)}',
        }
      else
        {
          'type': 'file',
          'file': {'filename': file.name, 'file_data': file.dataUrl},
        },
  ];
}

List<Map<String, Object?>> geminiContent(
  String text,
  List<ChatAttachment> attachments,
) => [
  {'text': text.isEmpty ? 'Please review the attached files.' : text},
  for (final file in attachments)
    if (file.isText)
      {
        'text':
            'File: ${file.name}\n${utf8.decode(file.bytes, allowMalformed: true)}',
      }
    else
      {
        'inlineData': {'mimeType': file.mimeType, 'data': file.base64Data},
      },
];
