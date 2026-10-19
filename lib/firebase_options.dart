// Placeholder. Replace by running, from the project root:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id> \
//       --platforms=android,ios
//
// The CLI overwrites this file and writes android/app/google-services.json
// and ios/Runner/GoogleService-Info.plist. Those files hold public client
// configuration (protected by Security Rules), so commit them for CI builds.
// Until then the app starts on a "Setup needed" screen instead of crashing.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase is not configured. Run `flutterfire configure`.',
  );
}
