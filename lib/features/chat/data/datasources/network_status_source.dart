abstract interface class NetworkStatusSource {
  Stream<bool> get changes;

  Future<bool> isOnline();
}
