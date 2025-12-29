import 'package:connectivity_plus/connectivity_plus.dart';

/// IO (Mobile/Desktop) implementation using connectivity_plus.

Future<bool> checkConnectivity() async {
  try {
    final result = await Connectivity().checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  } catch (_) {
    return true; // Assume online if check fails
  }
}

Stream<bool> onConnectivityChanged() {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  });
}

