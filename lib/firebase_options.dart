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
    apiKey: 'AIzaSyC6oNebFayQ-UJcd_uRkk_T9XlwsxSf0Fc',
    appId: '1:985472923092:web:4a8f4b2fffb3b90fce1241',
    messagingSenderId: '985472923092',
    projectId: 'resi-5c32a',
    authDomain: 'resi-5c32a.firebaseapp.com',
    storageBucket: 'resi-5c32a.firebasestorage.app',
    measurementId: 'G-M7G7F936M0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD7-rB0SVNZ1yjCkNdpZ4VEVZUJg7bKLy8',
    appId: '1:985472923092:android:d318e03d7bb6394ece1241',
    messagingSenderId: '985472923092',
    projectId: 'resi-5c32a',
    storageBucket: 'resi-5c32a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCc9ZqAclTn73t5eQsYi2Q6zhrD2bre20A',
    appId: '1:985472923092:ios:0930852497c8685cce1241',
    messagingSenderId: '985472923092',
    projectId: 'resi-5c32a',
    storageBucket: 'resi-5c32a.firebasestorage.app',
    iosClientId:
        '985472923092-pdd5hvd9e3csb1tn9vd97lbf0k00rh0a.apps.googleusercontent.com',
    iosBundleId: 'africa.resi.pro',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCc9ZqAclTn73t5eQsYi2Q6zhrD2bre20A',
    appId: '1:985472923092:ios:0930852497c8685cce1241',
    messagingSenderId: '985472923092',
    projectId: 'resi-5c32a',
    storageBucket: 'resi-5c32a.firebasestorage.app',
    iosClientId:
        '985472923092-pdd5hvd9e3csb1tn9vd97lbf0k00rh0a.apps.googleusercontent.com',
    iosBundleId: 'africa.resi.pro',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC6oNebFayQ-UJcd_uRkk_T9XlwsxSf0Fc',
    appId: '1:985472923092:web:d8bddaea4b3c1f1bce1241',
    messagingSenderId: '985472923092',
    projectId: 'resi-5c32a',
    authDomain: 'resi-5c32a.firebaseapp.com',
    storageBucket: 'resi-5c32a.firebasestorage.app',
    measurementId: 'G-TD5GP234RY',
  );
}
