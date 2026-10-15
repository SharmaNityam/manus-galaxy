abstract interface class SpeechInput {
  Future<bool> start({
    required void Function(String) onText,
    required void Function(String) onError,
    required void Function() onDone,
    required void Function(double) onLevel,
  });
  Future<String> finish();
  Future<void> cancel();
}
