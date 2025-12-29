/// Stub implementation for connectivity check.
/// Used when neither io nor html libraries are available.

Future<bool> checkConnectivity() async {
  // Assume online
  return true;
}

Stream<bool> onConnectivityChanged() {
  // Return empty stream, assume always online
  return const Stream.empty();
}

