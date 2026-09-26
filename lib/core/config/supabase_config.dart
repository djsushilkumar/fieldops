import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yntpxattrcrshrzptkhs.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_D1DoAuXf9ZhUUPkOqQtUGQ_5DP_dVwK',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseUrl != 'https://demo-project.supabase.co' &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'demo-anon-key-placeholder';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static String? _initializationError;
  static String? get initializationError => _initializationError;

  static Future<void> initialize() async {
    if (!isConfigured) {
      _initialized = false;
      _initializationError =
          'Supabase configuration is missing or invalid. Set SUPABASE_URL and SUPABASE_ANON_KEY.';
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _initialized = true;
      _initializationError = null;
    } catch (e) {
      _initialized = false;
      _initializationError = 'Failed to initialize Supabase client: $e';
    }
  }

  static SupabaseClient? get client {
    if (_initialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
