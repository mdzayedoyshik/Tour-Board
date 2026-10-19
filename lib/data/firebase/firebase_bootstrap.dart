import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';

/// Builds [FirebaseOptions] from env config instead of a generated
/// firebase_options.dart, so CI can inject per-environment values and no
/// platform config file has to be committed.
FirebaseOptions firebaseOptionsFor(AppConfig config) {
  final isIos = defaultTargetPlatform == TargetPlatform.iOS;
  return FirebaseOptions(
    apiKey: isIos ? config.firebaseIosApiKey : config.firebaseAndroidApiKey,
    appId: isIos ? config.firebaseIosAppId : config.firebaseAndroidAppId,
    messagingSenderId: config.firebaseMessagingSenderId,
    projectId: config.firebaseProjectId,
    storageBucket: config.firebaseStorageBucket.isEmpty
        ? null
        : config.firebaseStorageBucket,
    iosBundleId: isIos && config.firebaseIosBundleId.isNotEmpty
        ? config.firebaseIosBundleId
        : null,
    iosClientId: isIos && config.googleIosClientId.isNotEmpty
        ? config.googleIosClientId
        : null,
  );
}

/// Initialises Firebase and Firestore offline persistence.
///
/// Throws [ConfigException] if required keys are missing, so the caller can
/// render a setup screen rather than crash.
Future<void> initFirebase(AppConfig config) async {
  final missing = config.missingFirebaseKeys();
  if (missing.isNotEmpty) throw ConfigException(missingKeys: missing);

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: firebaseOptionsFor(config));
  }

  final firestore = FirebaseFirestore.instance;
  if (config.useFirebaseEmulator && !config.isProduction) {
    firestore.useFirestoreEmulator(config.firebaseEmulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(
      config.firebaseEmulatorHost,
      9099,
    );
  }

  // Cached reads and queued writes. A bounded cache keeps device storage in
  // check; 50 MB is plenty for MVP-sized tours.
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024,
  );
}
