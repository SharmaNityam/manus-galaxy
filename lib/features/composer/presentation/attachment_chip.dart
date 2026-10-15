import 'package:flutter/material.dart';
import '../../chat/domain/entities/chat_attachment.dart';

class AttachmentChip extends StatelessWidget {
  const AttachmentChip({required this.attachment, this.onRemove, super.key});
  final ChatAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 210),
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F4F4),
      border: Border.all(color: const Color(0xFFE4E4E4)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (attachment.isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.memory(
              attachment.bytes,
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          )
        else
          const Icon(Icons.description_outlined, size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                attachment.readableSize,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (onRemove != null)
          SizedBox(
            width: 32,
            height: 36,
            child: IconButton(
              onPressed: onRemove,
              tooltip: 'Remove ${attachment.name}',
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
          ),
      ],
    ),
  );
}
