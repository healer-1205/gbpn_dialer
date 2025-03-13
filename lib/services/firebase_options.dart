// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCsbJvn6HWC1C1cKH-72lZdvD6xgK8PWhE',
    appId: '1:567512315222:android:89f14df04d1f8cf0d392f7',
    messagingSenderId: '567512315222',
    projectId: 'twiliodemo-bf268',
    storageBucket: 'twiliodemo-bf268.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDioQsRw1LC_m7KYS4VIKMmEmAKg-r3dt0',
    appId: '1:372155560077:ios:8a4974725b93f3a46172c4',
    messagingSenderId: '372155560077',
    projectId: 'homeapp-336516',
    storageBucket: 'homeapp-336516.appspot.com',
    androidClientId: '372155560077-11u4lf5e9i5mlc7t52i9cfmv0sjj68bm.apps.googleusercontent.com',
    iosClientId: '372155560077-5pp197iuoprnt9cmotu67aebkppeetja.apps.googleusercontent.com',
    iosBundleId: 'com.homeapp.ios',
  );
}