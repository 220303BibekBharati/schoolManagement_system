import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Manually created Firebase options for this project.
///
/// IMPORTANT:
/// 1. Go to Firebase console → Project settings → Your apps → Web.
/// 2. Copy the values from the firebaseConfig snippet and paste them below.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Web
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBlwhK0FeHsZqU15cf-XcFih1yi1W3f3JY',
        authDomain: 'school-management-system-975a3.firebaseapp.com',
        projectId: 'school-management-system-975a3',
        storageBucket: 'school-management-system-975a3.firebasestorage.app',
        messagingSenderId: '744755894500',
        appId: '1:744755894500:web:f0b2b72ddae0ab5fe5b4f1',
      );
    }

    // Non-web (reuse same for now)
    return const FirebaseOptions(
      apiKey: 'AIzaSyBlwhK0FeHsZqU15cf-XcFih1yi1W3f3JY',
      authDomain: 'school-management-system-975a3.firebaseapp.com',
      projectId: 'school-management-system-975a3',
      storageBucket: 'school-management-system-975a3.firebasestorage.app',
      messagingSenderId: '744755894500',
      appId: '1:744755894500:web:f0b2b72ddae0ab5fe5b4f1',
    );
  }
}