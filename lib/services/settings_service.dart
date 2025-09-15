import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _notificationKey = 'notification_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _languageKey = 'language';

  // Notification settings
  static Future<bool> getNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationKey) ?? true; // Default: enabled
  }

  static Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationKey, enabled);
  }

  // Dark mode settings
  static Future<bool> getDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false; // Default: light mode
  }

  static Future<void> setDarkModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  // Language settings
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en'; // Default: English
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  // Get all settings
  static Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'notification': await getNotificationEnabled(),
      'darkMode': await getDarkModeEnabled(),
      'language': await getLanguage(),
    };
  }

  // Language helper methods
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'id':
        return 'Bahasa Indonesia';
      default:
        return 'English';
    }
  }

  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'id':
        return 'Indonesia';
      default:
        return 'English';
    }
  }
}
