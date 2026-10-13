abstract interface class ChatRemoteDataSource {
  Stream<String> streamReply(String prompt);
}
