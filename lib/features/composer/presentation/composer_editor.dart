import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../chat/domain/entities/chat_attachment.dart';
import 'attachment_chip.dart';

class ComposerEditor extends StatelessWidget {
  const ComposerEditor({
    required this.controller,
    required this.focusNode,
    required this.homeStyle,
    required this.isStreaming,
    required this.busy,
    required this.attachments,
    required this.onRemove,
    required this.onAttachment,
    required this.onConnectors,
    required this.onVoice,
    required this.onSubmit,
    this.onStop,
    super.key,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool homeStyle;
  final bool isStreaming;
  final bool busy;
  final List<ChatAttachment> attachments;
  final ValueChanged<ChatAttachment> onRemove;
  final VoidCallback onAttachment;
  final VoidCallback onConnectors;
  final VoidCallback onVoice;
  final VoidCallback onSubmit;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final enabled = controller.text.trim().isNotEmpty || attachments.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (attachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 44 + MediaQuery.textScalerOf(context).scale(16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) => AttachmentChip(
                  attachment: attachments[index],
                  onRemove: () => onRemove(attachments[index]),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            style: TextStyle(fontSize: homeStyle ? 16 : 17, height: 1.4),
            cursorColor: const Color(0xFF171717),
            decoration: InputDecoration(
              hintText: homeStyle
                  ? 'Assign a task or type / for more'
                  : 'Assign a task or ask anything',
              hintStyle: TextStyle(
                color: const Color(0xFFB6B6B3),
                fontSize: homeStyle ? 16 : 17,
                height: 1.4,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: busy || isStreaming ? null : onAttachment,
              tooltip: 'Add attachment',
              padding: EdgeInsets.zero,
              icon: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const AppIcon('plus', size: 24),
              color: const Color(0xFF35352F),
            ),
            IconButton(
              onPressed: isStreaming ? null : onConnectors,
              tooltip: 'Connectors',
              alignment: const Alignment(-.5, 0),
              padding: EdgeInsets.zero,
              icon: const AppIcon('cable', size: 24),
              color: const Color(0xFF35352F),
            ),
            const Spacer(),
            IconButton(
              onPressed: isStreaming ? null : onVoice,
              tooltip: 'Voice input',
              alignment: const Alignment(.36, 0),
              padding: EdgeInsets.zero,
              icon: const AppIcon('mic', size: 24),
              color: const Color(0xFF35352F),
            ),
            IconButton(
              onPressed: isStreaming
                  ? onStop
                  : enabled && !busy
                  ? onSubmit
                  : null,
              tooltip: isStreaming ? 'Stop response' : 'Send message',
              padding: EdgeInsets.zero,
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isStreaming || enabled
                      ? const Color(0xFF171717)
                      : const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isStreaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                  size: 27,
                  color: isStreaming || enabled
                      ? Colors.white
                      : const Color(0xFFE8E8E8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
