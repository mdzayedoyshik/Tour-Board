import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Which env file to load: `--dart-define=ENV=prod` for release builds.
const String appEnvironment = String.fromEnvironment(
  'ENV',
  defaultValue: 'dev',
);

/// Non-secret runtime configuration loaded from `env/<ENV>.env`.
///
/// Firebase client options are public by design (access is enforced by
/// Security Rules). Never place service-account keys or server credentials
/// in these files.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.firebaseProjectId,
    required this.firebaseMessagingSenderId,
    required this.firebaseStorageBucket,
    required this.firebaseAndroidApiKey,
    required this.firebaseAndroidAppId,
    required this.firebaseIosApiKey,
    required this.firebaseIosAppId,
    required this.firebaseIosBundleId,
    required this.googleServerClientId,
    required this.googleIosClientId,
    required this.inviteLinkBase,
    required this.mapTileUrl,
    required this.mapTileAttribution,
    required this.mapAttributionUrl,
    required this.placeSearchProvider,
    required this.nominatimUrl,
    required this.placeSearchContactEmail,
    required this.useFirebaseEmulator,
    required this.firebaseEmulatorHost,
  });

  factory AppConfig.fromMap(String environment, Map<String, String> env) {
    String value(String key, [String fallback = '']) {
      final v = env[key]?.trim();
      return v == null || v.isEmpty ? fallback : v;
    }

    return AppConfig(
      environment: environment,
      firebaseProjectId: value('FIREBASE_PROJECT_ID'),
      firebaseMessagingSenderId: value('FIREBASE_MESSAGING_SENDER_ID'),
      firebaseStorageBucket: value('FIREBASE_STORAGE_BUCKET'),
      firebaseAndroidApiKey: value('FIREBASE_ANDROID_API_KEY'),
      firebaseAndroidAppId: value('FIREBASE_ANDROID_APP_ID'),
      firebaseIosApiKey: value('FIREBASE_IOS_API_KEY'),
      firebaseIosAppId: value('FIREBASE_IOS_APP_ID'),
      firebaseIosBundleId: value('FIREBASE_IOS_BUNDLE_ID'),
      googleServerClientId: value('GOOGLE_SERVER_CLIENT_ID'),
      googleIosClientId: value('GOOGLE_IOS_CLIENT_ID'),
      inviteLinkBase: value('INVITE_LINK_BASE', 'https://tourboard.app/join'),
      mapTileUrl: value(
        'MAP_TILE_URL',
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
      mapTileAttribution: value(
        'MAP_TILE_ATTRIBUTION',
        '© OpenStreetMap contributors',
      ),
      mapAttributionUrl: value(
        'MAP_ATTRIBUTION_URL',
        'https://www.openstreetmap.org/copyright',
      ),
      placeSearchProvider: value('PLACE_SEARCH_PROVIDER', 'none'),
      nominatimUrl: value(
        'NOMINATIM_URL',
        'https://nominatim.openstreetmap.org',
      ),
      placeSearchContactEmail: value('PLACE_SEARCH_CONTACT_EMAIL'),
      useFirebaseEmulator: value('USE_FIREBASE_EMULATOR') == 'true',
      firebaseEmulatorHost: value('FIREBASE_EMULATOR_HOST', 'localhost'),
    );
  }

  /// Loads `env/<environment>.env`. Throws [ConfigException] when the file
  /// is missing so the app can show setup instructions instead of crashing.
  static Future<AppConfig> load({String environment = appEnvironment}) async {
    final file = 'env/$environment.env';
    try {
      final text = await rootBundle.loadString(file);
      final env = DotEnv()..loadFromString(envString: text);
      return AppConfig.fromMap(environment, Map.of(env.env));
    } on FlutterError {
      throw ConfigException(missingFile: file);
    }
  }

  final String environment;
  final String firebaseProjectId;
  final String firebaseMessagingSenderId;
  final String firebaseStorageBucket;
  final String firebaseAndroidApiKey;
  final String firebaseAndroidAppId;
  final String firebaseIosApiKey;
  final String firebaseIosAppId;
  final String firebaseIosBundleId;
  final String googleServerClientId;
  final String googleIosClientId;
  final String inviteLinkBase;
  final String mapTileUrl;
  final String mapTileAttribution;
  final String mapAttributionUrl;

  /// 'nominatim' or 'none' (manual place entry only).
  final String placeSearchProvider;
  final String nominatimUrl;
  final String placeSearchContactEmail;
  final bool useFirebaseEmulator;
  final String firebaseEmulatorHost;

  bool get isProduction => environment == 'prod';

  /// Names of required keys that are empty for the current platform.
  List<String> missingFirebaseKeys() {
    final missing = <String>[
      if (firebaseProjectId.isEmpty) 'FIREBASE_PROJECT_ID',
      if (firebaseMessagingSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
    ];
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS) {
      if (firebaseIosApiKey.isEmpty) missing.add('FIREBASE_IOS_API_KEY');
      if (firebaseIosAppId.isEmpty) missing.add('FIREBASE_IOS_APP_ID');
    } else {
      if (firebaseAndroidApiKey.isEmpty) {
        missing.add('FIREBASE_ANDROID_API_KEY');
      }
      if (firebaseAndroidAppId.isEmpty) missing.add('FIREBASE_ANDROID_APP_ID');
    }
    return missing;
  }
}

class ConfigException implements Exception {
  const ConfigException({this.missingFile, this.missingKeys = const []});

  final String? missingFile;
  final List<String> missingKeys;

  @override
  String toString() => missingFile != null
      ? 'Missing configuration file $missingFile'
      : 'Missing configuration keys: ${missingKeys.join(', ')}';
}
