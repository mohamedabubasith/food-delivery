// File generated manually from GoogleService-Info.plist and google-services.json
// This file configures the Firebase SDK for Flutter.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA1UOaJJTJGyR-rz1W0LcnN5XVqxpTF-IM',
    appId: '1:885717421274:web:placeholder',
    messagingSenderId: '885717421274',
    projectId: 'my-project-1630504481421',
    authDomain: 'my-project-1630504481421.firebaseapp.com',
    storageBucket: 'my-project-1630504481421.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA1UOaJJTJGyR-rz1W0LcnN5XVqxpTF-IM',
    appId: '1:885717421274:android:97976119b56a21622aa9e3',
    messagingSenderId: '885717421274',
    projectId: 'my-project-1630504481421',
    authDomain: 'my-project-1630504481421.firebaseapp.com',
    storageBucket: 'my-project-1630504481421.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA1UOaJJTJGyR-rz1W0LcnN5XVqxpTF-IM',
    appId: '1:885717421274:ios:9fb270fe541e76862aa9e3',
    messagingSenderId: '885717421274',
    projectId: 'my-project-1630504481421',
    authDomain: 'my-project-1630504481421.firebaseapp.com',
    storageBucket: 'my-project-1630504481421.firebasestorage.app',
    iosBundleId: 'com.abdelivery.app',
  );
}
