// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7_af_Q3xJHw_d7LP8ZbgJEoXsKMpr0qo',
    appId: '1:475681071444:web:a845c1f43db42eb5b3a8c1',
    messagingSenderId: '475681071444',
    projectId: 'gebere-44c39',
    authDomain: 'gebere-44c39.firebaseapp.com',
    storageBucket: 'gebere-44c39.firebasestorage.app',
    measurementId: 'G-G0KXBFDRGF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDp5RXqJ3_zA8pOEO8M8_krhoZm2ESFZ5c',
    appId: '1:475681071444:android:03ae4203fe2b900ab3a8c1',
    messagingSenderId: '475681071444',
    projectId: 'gebere-44c39',
    storageBucket: 'gebere-44c39.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjGhxE95ARTAsmIDbZXNMJUk9vhUeMHSU',
    appId: '1:475681071444:ios:96acebf2e8f0b4b6b3a8c1',
    messagingSenderId: '475681071444',
    projectId: 'gebere-44c39',
    storageBucket: 'gebere-44c39.firebasestorage.app',
    iosBundleId: 'com.example.smartGebere',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAjGhxE95ARTAsmIDbZXNMJUk9vhUeMHSU',
    appId: '1:475681071444:ios:96acebf2e8f0b4b6b3a8c1',
    messagingSenderId: '475681071444',
    projectId: 'gebere-44c39',
    storageBucket: 'gebere-44c39.firebasestorage.app',
    iosBundleId: 'com.example.smartGebere',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA7_af_Q3xJHw_d7LP8ZbgJEoXsKMpr0qo',
    appId: '1:475681071444:web:656e02215b3510ffb3a8c1',
    messagingSenderId: '475681071444',
    projectId: 'gebere-44c39',
    authDomain: 'gebere-44c39.firebaseapp.com',
    storageBucket: 'gebere-44c39.firebasestorage.app',
    measurementId: 'G-5F0H9GG5KS',
  );
}
