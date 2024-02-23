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
    apiKey: 'AIzaSyDQIwnHHf93TmAn-b36yjcR5H_gVHi3eCY',
    appId: '1:1092181859695:android:424b4555cccbc3003f5c9a',
    messagingSenderId: '1092181859695',
    projectId: 'myuniv-ed957',
    databaseURL: 'https://myuniv-ed957-default-rtdb.firebaseio.com',
    storageBucket: 'myuniv-ed957.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuVhDugZfNThYRsntJDE6HkzYI5jMKRMU',
    appId: '1:1092181859695:ios:1b5e9e1f6b0c85603f5c9a',
    messagingSenderId: '1092181859695',
    projectId: 'myuniv-ed957',
    databaseURL: 'https://myuniv-ed957-default-rtdb.firebaseio.com',
    storageBucket: 'myuniv-ed957.appspot.com',
    androidClientId: '1092181859695-3mhoq222l4u3lsnrpgkv197lhsq13926.apps.googleusercontent.com',
    iosClientId: '1092181859695-o9662nv4epem3qj6ptfjdbo3l7qclpcp.apps.googleusercontent.com',
    iosBundleId: 'com.example.kluFlutter',
  );
}
