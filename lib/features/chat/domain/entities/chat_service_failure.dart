class ChatServiceFailure implements Exception {
  const ChatServiceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
