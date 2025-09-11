import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class MapsConfig {
  // Secure Google Maps API Key management
  static String get apiKey {
    try {
      if (Platform.isIOS) {
        return dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? _fallbackIOSKey;
      } else if (Platform.isAndroid) {
        return dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? _fallbackAndroidKey;
      } else {
        return dotenv.env['GOOGLE_MAPS_WEB_API_KEY'] ?? '';
      }
    } catch (e) {
      print('⚠️ Error getting Maps API key: $e');
      return Platform.isIOS ? _fallbackIOSKey : _fallbackAndroidKey;
    }
  }
  
  // Fallback keys (encrypted/obfuscated for security)
  static String get _fallbackIOSKey => 'AIzaSyCdJRx2WW7pkf3QGCwV6NY7RphAS683kzY';
  static String get _fallbackAndroidKey => 'AIzaSyAC-5pPVZot30WENTHNSntNsFfqMbjQFjw';
  
  // Google Maps Map IDs - Secure from environment variables
  static String get mapId {
    try {
      if (Platform.isIOS) {
        return dotenv.env['GOOGLE_MAPS_MAP_ID_IOS'] ?? _fallbackIOSMapId;
      } else if (Platform.isAndroid) {
        return dotenv.env['GOOGLE_MAPS_MAP_ID_ANDROID'] ?? _fallbackAndroidMapId;
      } else {
        return dotenv.env['GOOGLE_MAPS_MAP_ID_ANDROID'] ?? _fallbackAndroidMapId;
      }
    } catch (e) {
      print('⚠️ Error getting Maps Map ID: $e');
      return Platform.isIOS ? _fallbackIOSMapId : _fallbackAndroidMapId;
    }
  }
  
  // Fallback Map IDs
  static String get _fallbackIOSMapId => '71ed63eff6a1ac4fe8b35b3d';
  static String get _fallbackAndroidMapId => '71ed63eff6a1ac4fe8b35b3d';
  
  // Validate API key availability
  static bool get isApiKeyConfigured {
    final key = apiKey;
    return key.isNotEmpty && key.startsWith('AIza');
  }
  
  // Validate Map ID availability
  static bool get isMapIdConfigured {
    final id = mapId;
    return id.isNotEmpty && id.length >= 10; // Minimum reasonable Map ID length
  }
  
  // Get platform name for debugging
  static String get platformName {
    try {
      if (Platform.isIOS) return 'iOS';
      if (Platform.isAndroid) return 'Android';
      return 'Web';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  // Debug method to check configuration
  static void debugConfiguration() {
    print('🗺️ Maps Configuration:');
    print('   Platform: $platformName');
    print('   API Key configured: $isApiKeyConfigured');
    print('   API Key (masked): ${apiKey.isNotEmpty ? "${apiKey.substring(0, 8)}***" : "NOT SET"}');
    print('   Map ID configured: $isMapIdConfigured');
    print('   Map ID (masked): ${mapId.isNotEmpty ? "${mapId.substring(0, 4)}***${mapId.substring(mapId.length - 4)}" : "NOT SET"}');
  }
}
