import 'package:shared_preferences/shared_preferences.dart';

/// App-level configuration persisted on the device.
/// Never hardcode the server URL or token here.
class AppConfig {
  static const _baseUrlKey = 'base_url';
  static const _authTokenKey = 'auth_token';

  final String baseUrl;
  final String authToken;

  const AppConfig({required this.baseUrl, required this.authToken});

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig(
      baseUrl: prefs.getString(_baseUrlKey) ?? '',
      authToken: prefs.getString(_authTokenKey) ?? '',
    );
  }

  static Future<void> saveBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, value.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  static Future<void> saveAuthToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, value.trim());
  }
}
