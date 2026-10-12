class MockChatRemoteDataSource {
  Stream<String> streamReply(String prompt) async* {
    final response = 'I can help with that. You asked: $prompt';
    for (var index = 0; index < response.length; index += 3) {
      await Future<void>.delayed(const Duration(milliseconds: 35));
      yield response.substring(index, (index + 3).clamp(0, response.length));
    }
  }
}
