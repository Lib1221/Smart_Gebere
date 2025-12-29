import 'dart:async';
import 'dart:html' as html;

/// Web implementation using Navigator.onLine and online/offline events.

Future<bool> checkConnectivity() async {
  try {
    return html.window.navigator.onLine ?? true;
  } catch (_) {
    return true; // Assume online if check fails
  }
}

Stream<bool> onConnectivityChanged() {
  final controller = StreamController<bool>.broadcast();
  
  // Listen for online event
  html.window.addEventListener('online', (_) {
    controller.add(true);
  });
  
  // Listen for offline event
  html.window.addEventListener('offline', (_) {
    controller.add(false);
  });
  
  return controller.stream;
}

