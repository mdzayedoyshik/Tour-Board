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
/// Firebase itself is configured by the FlutterFire CLI
/// (lib/firebase_options.dart), not by env values. Never place
/// service-account keys or server credentials in these files.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
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
      apiBaseUrl: value(
        'API_BASE_URL',
        'https://tour-board-backend.onrender.com',
      ).replaceAll(RegExp(r'/+$'), ''),
      useFirebaseEmulator: value('USE_FIREBASE_EMULATOR') == 'true',
      firebaseEmulatorHost: value('FIREBASE_EMULATOR_HOST', 'localhost'),
    );
  }

  /// Loads `env/<environment>.env`. Every key has a safe default, so a
  /// missing file simply means "use defaults".
  static Future<AppConfig> load({String environment = appEnvironment}) async {
    try {
      final text = await rootBundle.loadString('env/$environment.env');
      final env = DotEnv()..loadFromString(envString: text);
      return AppConfig.fromMap(environment, Map.of(env.env));
    } on FlutterError {
      return AppConfig.fromMap(environment, const {});
    }
  }

  final String environment;

  /// Tour Board backend (notifications, cleanup, place search).
  final String apiBaseUrl;
  final bool useFirebaseEmulator;
  final String firebaseEmulatorHost;

  bool get isProduction => environment == 'prod';
}

/// Raised when Firebase has not been configured with `flutterfire configure`.
class ConfigException implements Exception {
  const ConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}
