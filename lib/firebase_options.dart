// File generated for project charcoal-2fe4b.
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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlfwSR2NBFTu4VkfbCs3hrj9H4bAw4Seg',
    appId: '1:779328678183:web:7c9582d3b6c817cfb16102',
    messagingSenderId: '779328678183',
    projectId: 'charcoal-2fe4b',
    authDomain: 'charcoal-2fe4b.firebaseapp.com',
    databaseURL: 'https://charcoal-2fe4b-default-rtdb.firebaseio.com',
    storageBucket: 'charcoal-2fe4b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC48YtOUQIoYOB_RoCxX4EeyvobgqTrRhQ',
    appId: '1:779328678183:android:f35b142127c4f178b16102',
    messagingSenderId: '779328678183',
    projectId: 'charcoal-2fe4b',
    databaseURL: 'https://charcoal-2fe4b-default-rtdb.firebaseio.com',
    storageBucket: 'charcoal-2fe4b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBlfwSR2NBFTu4VkfbCs3hrj9H4bAw4Seg',
    appId: '1:779328678183:web:7c9582d3b6c817cfb16102',
    messagingSenderId: '779328678183',
    projectId: 'charcoal-2fe4b',
    databaseURL: 'https://charcoal-2fe4b-default-rtdb.firebaseio.com',
    storageBucket: 'charcoal-2fe4b.firebasestorage.app',
  );
}
