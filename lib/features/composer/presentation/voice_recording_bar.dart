import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/speech_input.dart';
import 'composer_providers.dart';

class VoiceRecordingBar extends ConsumerStatefulWidget {
  const VoiceRecordingBar({
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });
  final VoidCallback onCancel;
  final void Function(String words, bool send) onConfirm;
  @override
  ConsumerState<VoiceRecordingBar> createState() => _VoiceRecordingBarState();
}

class _VoiceRecordingBarState extends ConsumerState<VoiceRecordingBar>
    with WidgetsBindingObserver {
  late final SpeechInput _speech;
  Timer? _timer;
  var _seconds = 0;
  var _level = 0.0;
  var _starting = true;
  var _finishing = false;
  String? _error;
  String _words = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speech = ref.read(speechInputProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    setState(() {
      _starting = true;
      _error = null;
      _seconds = 0;
      _words = '';
    });
    try {
      final available = await _speech.start(
        onText: (text) {
          if (mounted) setState(() => _words = text);
        },
        onError: (message) {
          if (mounted) {
            _timer?.cancel();
            setState(() {
              _error = message;
              _starting = false;
            });
          }
        },
        onDone: () {
          _timer?.cancel();
          if (mounted) setState(() => _level = 0);
        },
        onLevel: (level) {
          if (mounted) setState(() => _level = level);
        },
      );
      if (!mounted) return;
      setState(() {
        _starting = false;
        if (!available) {
          _error =
              'Enable microphone and speech recognition in Settings to use voice input.';
        }
      });
      if (available && _error == null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _seconds++);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error =
              'Voice input could not start. Check microphone permission and try again.';
        });
      }
    }
  }

  Future<void> _confirm(bool send) async {
    if (_starting || _finishing) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    final words = await _speech.finish();
    if (!mounted) return;
    if (words.trim().isEmpty) {
      setState(() {
        _finishing = false;
        _error = 'No speech detected. Tap the microphone to try again.';
      });
      return;
    }
    widget.onConfirm(words.trim(), send);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_speech.cancel());
      _timer?.cancel();
      if (mounted) {
        setState(
          () => _error =
              'Recording interrupted. Tap the microphone to try again.',
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_speech.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 34,
        child: _error != null
            ? Text(
                _error!,
                maxLines: 3,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8B3939)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_starting || _finishing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Row(
                      children: List.generate(
                        10,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 3,
                          height:
                              4 +
                              (_level.abs().clamp(0, 12) / 12) *
                                  (index.isEven ? 18 : 10),
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF494944),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
      ),
      if (_words.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _words,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          _RoundControl(
            icon: Icons.close_rounded,
            tooltip: 'Cancel recording',
            onTap: widget.onCancel,
          ),
          const Spacer(),
          if (_error != null)
            _RoundControl(
              icon: Icons.mic_none_rounded,
              tooltip: 'Try voice input again',
              onTap: _start,
            )
          else
            _RoundControl(
              icon: Icons.check_rounded,
              tooltip: 'Use transcription',
              onTap: _starting || _finishing ? null : () => _confirm(false),
            ),
          _RoundControl(
            icon: Icons.arrow_upward_rounded,
            tooltip: 'Send transcription',
            dark: true,
            onTap: _starting || _finishing || (_error != null && _words.isEmpty)
                ? null
                : () => _confirm(true),
          ),
        ],
      ),
    ],
  );
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.dark = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool dark;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF171717) : const Color(0xFFF5F5F5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 26,
        color: dark ? Colors.white : const Color(0xFF35352F),
      ),
    ),
  );
}
