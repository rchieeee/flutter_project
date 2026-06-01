import 'package:connectivity_plus/connectivity_plus.dart';

/// Checks and monitors network connectivity.
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Returns true if the device currently has any network connection.
  static Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Stream that emits true when online, false when offline.
  static Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
}
