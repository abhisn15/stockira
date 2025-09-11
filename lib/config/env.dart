import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // API Configuration
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get prefixApi => dotenv.env['PREFIX_API'] ?? '';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? '';
  
  static String get apiBaseUrl => '$baseUrl/$prefixApi/$apiVersion';
  
  static String get loginUrl => '$apiBaseUrl/login';
  static String get profileUrl => '$apiBaseUrl/me';
  
  // Google Maps API Keys - Secure from environment variables
  static String get googleMapsApiKeyIOS => dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? '';
  static String get googleMapsApiKeyAndroid => dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? '';
  static String get googleMapsWebApiKey => dotenv.env['GOOGLE_MAPS_WEB_API_KEY'] ?? '';
  
  // Google Maps Map IDs - Secure from environment variables
  static String get googleMapsMapIdIOS => dotenv.env['GOOGLE_MAPS_MAP_ID_IOS'] ?? '';
  static String get googleMapsMapIdAndroid => dotenv.env['GOOGLE_MAPS_MAP_ID_ANDROID'] ?? '';
  
  // Helper method to get platform-specific API key
  static String get googleMapsApiKey {
    // This will be used in platform-specific implementations
    return googleMapsApiKeyAndroid; // Default fallback
  }
  
  // Helper method to get platform-specific Map ID
  static String get googleMapsMapId {
    // This will be used in platform-specific implementations
    return googleMapsMapIdAndroid; // Default fallback
  }
}
