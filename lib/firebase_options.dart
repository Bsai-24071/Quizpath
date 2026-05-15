import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlRwJpcf2K8G_egrlaJZ9rSmTvLEC_JxY',
    appId: '1:59506333605:web:2f643bd8f9dd478369fa4c',
    messagingSenderId: '59506333605',
    projectId: 'quizpath-3aa0d',
    authDomain: 'quizpath-3aa0d.firebaseapp.com',
    databaseURL: 'https://quizpath-3aa0d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'quizpath-3aa0d.firebasestorage.app',
    measurementId: 'G-QJD1WE5RF9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBlRwJpcf2K8G_egrlaJZ9rSmTvLEC_JxY',
    appId: '1:59506333605:android:YOUR_ANDROID_ID',
    messagingSenderId: '59506333605',
    projectId: 'quizpath-3aa0d',
    storageBucket: 'quizpath-3aa0d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBlRwJpcf2K8G_egrlaJZ9rSmTvLEC_JxY',
    appId: '1:59506333605:ios:YOUR_IOS_ID',
    messagingSenderId: '59506333605',
    projectId: 'quizpath-3aa0d',
    storageBucket: 'quizpath-3aa0d.firebasestorage.app',
    iosBundleId: 'com.example.appProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBlRwJpcf2K8G_egrlaJZ9rSmTvLEC_JxY',
    appId: '1:59506333605:ios:YOUR_IOS_ID',
    messagingSenderId: '59506333605',
    projectId: 'quizpath-3aa0d',
    storageBucket: 'quizpath-3aa0d.firebasestorage.app',
    iosBundleId: 'com.example.appProject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBlRwJpcf2K8G_egrlaJZ9rSmTvLEC_JxY',
    appId: '1:59506333605:web:2f643bd8f9dd478369fa4c',
    messagingSenderId: '59506333605',
    projectId: 'quizpath-3aa0d',
    authDomain: 'quizpath-3aa0d.firebaseapp.com',
    storageBucket: 'quizpath-3aa0d.firebasestorage.app',
  );
}
