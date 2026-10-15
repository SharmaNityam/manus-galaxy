import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/attachment_library.dart';
import '../domain/speech_input.dart';
import '../data/native_speech_input.dart';
import '../data/native_attachment_picker.dart';

final attachmentLibraryProvider = Provider<AttachmentLibrary>(
  (ref) => throw UnimplementedError(
    'Attachment library must be configured at startup.',
  ),
);
final attachmentPickerProvider = Provider<NativeAttachmentPicker>(
  (ref) => NativeAttachmentPicker(),
);

final speechInputProvider = Provider<SpeechInput>((ref) {
  final speech = NativeSpeechInput();
  ref.onDispose(speech.cancel);
  return speech;
});
