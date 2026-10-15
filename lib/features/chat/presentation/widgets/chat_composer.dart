import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../../composer/presentation/add_to_chat_sheet.dart';
import '../../../composer/presentation/composer_editor.dart';
import '../../../composer/presentation/composer_providers.dart';
import '../../../composer/presentation/voice_recording_bar.dart';
import '../../../connectors/presentation/connectors_sheet.dart';
import '../../domain/entities/chat_attachment.dart';

class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({
    required this.onSend,
    this.homeStyle = false,
    this.onFocusChanged,
    this.isStreaming = false,
    this.onStop,
    super.key,
  });
  final ValueChanged<ChatDraft> onSend;
  final bool homeStyle;
  final ValueChanged<bool>? onFocusChanged;
  final bool isStreaming;
  final VoidCallback? onStop;
  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _attachments = <ChatAttachment>[];
  bool _recording = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pick(ref.read(attachmentPickerProvider).recoverImages),
      );
    }
  }

  void _handleFocusChange() => widget.onFocusChanged?.call(_focusNode.hasFocus);
  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if ((text.isEmpty && _attachments.isEmpty) || widget.isStreaming || _busy) {
      return;
    }
    widget.onSend(
      ChatDraft(text: text, attachments: List.unmodifiable(_attachments)),
    );
    _controller.clear();
    setState(() {
      _attachments.clear();
      _error = null;
    });
  }

  Future<void> _pick(Future<List<ChatAttachment>> Function() picker) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files = await picker();
      if (!mounted) return;
      if (_attachments.length + files.length > 4) {
        throw const FormatException('Add up to four files per message.');
      }
      if ([
            ..._attachments,
            ...files,
          ].fold<int>(0, (sum, file) => sum + file.size) >
          10 * 1024 * 1024) {
        throw const FormatException(
          'Keep the total attachment size below 10 MB.',
        );
      }
      for (final file in files) {
        await ref.read(attachmentLibraryProvider).save(file);
      }
      if (mounted) {
        setState(() {
          for (final file in files) {
            if (!_attachments.any((item) => item.id == file.id)) {
              _attachments.add(file);
            }
          }
        });
      }
    } catch (error, stack) {
      logFailure('attachment_pick_failed', error, stack, scope: 'composer');
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Could not add the file. Check permission and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addAttachment() async {
    _focusNode.unfocus();
    final action = await showAddToChatSheet(context);
    if (!mounted || action == null) return;
    final picker = ref.read(attachmentPickerProvider);
    switch (action) {
      case AddToChatAction.camera:
        await _pick(picker.camera);
      case AddToChatAction.picture:
        await _pick(picker.pictures);
      case AddToChatAction.file:
        await _pick(picker.files);
      case AddToChatAction.library:
        final files = await context.push<List<ChatAttachment>>('/library');
        if (files != null && mounted) await _pick(() async => files);
      case AddToChatAction.creations ||
          AddToChatAction.recentTasks ||
          AddToChatAction.skills:
        final kind = action == AddToChatAction.creations
            ? 'creations'
            : action == AddToChatAction.skills
            ? 'skills'
            : 'recent-tasks';
        final text = await context.push<String>('/composer/$kind');
        if (text != null && mounted) {
          _controller.text = [
            _controller.text,
            text,
          ].where((part) => part.isNotEmpty).join('\n\n');
          _focusNode.requestFocus();
        }
    }
  }

  @override
  Widget build(BuildContext context) => ResponsiveContent(
    maxWidth: 800,
    horizontalPadding: widget.homeStyle ? 0 : 16,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.homeStyle ? 16 : 0,
          8,
          widget.homeStyle ? 16 : 0,
          12,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.homeStyle ? const Color(0xFFF3F3F4) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.homeStyle)
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Flexible(
                          child: _ComposerChoice(icon: 'cloud', label: 'Cloud'),
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          flex: 2,
                          child: _ComposerChoice(
                            icon: 'archive',
                            label: 'No project',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(2, 12, 2, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _recording
                    ? VoiceRecordingBar(
                        onCancel: () => setState(() => _recording = false),
                        onConfirm: (words, send) {
                          setState(() => _recording = false);
                          _controller.text = [
                            _controller.text.trim(),
                            words,
                          ].where((text) => text.isNotEmpty).join(' ');
                          if (send) {
                            _submit();
                          } else {
                            _focusNode.requestFocus();
                          }
                        },
                      )
                    : ComposerEditor(
                        controller: _controller,
                        focusNode: _focusNode,
                        homeStyle: widget.homeStyle,
                        isStreaming: widget.isStreaming,
                        busy: _busy,
                        attachments: _attachments,
                        onRemove: (file) =>
                            setState(() => _attachments.remove(file)),
                        onAttachment: _addAttachment,
                        onConnectors: () {
                          _focusNode.unfocus();
                          unawaited(showConnectorsSheet(context));
                        },
                        onVoice: () {
                          _focusNode.unfocus();
                          setState(() => _recording = true);
                        },
                        onSubmit: _submit,
                        onStop: widget.onStop,
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A3535),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ComposerChoice extends StatelessWidget {
  const _ComposerChoice({required this.icon, required this.label});
  final String icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppIcon(icon, size: 20, color: const Color(0xFF666661)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      const SizedBox(width: 3),
      const AppIcon('chevrons-up-down', size: 16, color: Color(0xFF8B8B87)),
    ],
  );
}
