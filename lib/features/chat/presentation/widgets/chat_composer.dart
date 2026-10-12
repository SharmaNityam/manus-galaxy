import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

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
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Ask anything',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  tooltip: 'Add attachment',
                ),
                const Spacer(),
                IconButton.filled(
                  onPressed: widget.isStreaming ? widget.onStop : _submit,
                  tooltip: widget.isStreaming
                      ? 'Stop response'
                      : 'Send message',
                  icon: Icon(
                    widget.isStreaming
                        ? Icons.stop_rounded
                        : Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
