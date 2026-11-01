import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the Chat S Android application.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Chat S Firebase configuration is currently Android-only.');
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0YfXScN-U1k5WcS_5SMk_L_bnehJBfNc',
    appId: '1:614610813726:android:6ae39eb01c796e53007f0f',
    messagingSenderId: '614610813726',
    projectId: 'chat-s-d8536',
    storageBucket: 'chat-s-d8536.firebasestorage.app',
  );
}
