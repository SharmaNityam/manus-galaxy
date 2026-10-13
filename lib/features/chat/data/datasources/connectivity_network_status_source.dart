import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_status_source.dart';

class ConnectivityNetworkStatusSource implements NetworkStatusSource {
  ConnectivityNetworkStatusSource(this._connectivity);

  final Connectivity _connectivity;

  @override
  Stream<bool> get changes => _connectivity.onConnectivityChanged.map(
    (results) => results.any((result) => result != ConnectivityResult.none),
  );

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
