import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_content.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    required this.onSend,
    this.isStreaming = false,
    this.onStop,
    super.key,
  });

  final ValueChanged<String> onSend;
  final bool isStreaming;
  final VoidCallback? onStop;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      maxWidth: 800,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.35),
                  cursorColor: AppTheme.accent,
                  decoration: const InputDecoration(
                    hintText: 'Assign a task or ask anything',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      tooltip: 'Add attachment',
                      icon: const Icon(Icons.add_rounded, size: 30),
                      color: AppTheme.secondaryText,
                    ),
                    const Spacer(),
                    IconButton.filled(
                      onPressed: widget.isStreaming ? widget.onStop : _submit,
                      tooltip: widget.isStreaming
                          ? 'Stop response'
                          : 'Send message',
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(52, 52),
                        maximumSize: const Size(52, 52),
                        shape: const CircleBorder(),
                      ),
                      icon: Icon(
                        widget.isStreaming
                            ? Icons.stop_rounded
                            : Icons.arrow_upward_rounded,
                        size: 27,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
