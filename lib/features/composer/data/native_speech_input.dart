import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import '../domain/speech_input.dart';

class NativeSpeechInput implements SpeechInput {
  final _speech = SpeechToText();
  void Function(String)? _onError;
  void Function()? _onDone;
  Completer<void>? _finalResult;
  String _words = '';
  int _generation = 0;

  @override
  Future<bool> start({
    required void Function(String) onText,
    required void Function(String) onError,
    required void Function() onDone,
    required void Function(double) onLevel,
  }) async {
    final generation = ++_generation;
    _words = '';
    _onError = onError;
    _onDone = onDone;
    _finalResult = Completer<void>();
    final available = await _speech.initialize(
      options: [SpeechToText.androidNoBluetooth],
      onError: (error) {
        final message = switch (error.errorMsg) {
          'error_permission' || 'error_permission_denied' =>
            'Microphone permission is off. Enable it in Settings to use voice input.',
          'error_no_match' || 'error_speech_timeout' =>
            'No speech detected. Tap the microphone to try again.',
          'error_network' || 'error_network_timeout' =>
            'Speech recognition needs a connection. Please try again.',
          _ =>
            'Voice input is unavailable. Please try again or type your message.',
        };
        _onError?.call(message);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _onDone?.call();
      },
    );
    if (!available || generation != _generation) return false;
    await _speech.listen(
      onResult: (result) {
        if (generation != _generation) return;
        _words = result.recognizedWords;
        onText(_words);
        if (result.finalResult && !(_finalResult?.isCompleted ?? true)) {
          _finalResult!.complete();
        }
      },
      onSoundLevelChange: onLevel,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 8),
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: true,
      ),
    );
    return true;
  }

  @override
  Future<String> finish() async {
    await _speech.stop();
    await _finalResult?.future.timeout(
      const Duration(milliseconds: 1200),
      onTimeout: () {},
    );
    return _words;
  }

  @override
  Future<void> cancel() async {
    _generation++;
    _onError = null;
    _onDone = null;
    await _speech.cancel();
  }
}
