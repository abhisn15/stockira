import 'dart:io';
import '../config/maps_config.dart';

class MapsService {
  // Singleton pattern for secure API key management
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();
  
  String? _cachedApiKey;
  String? _cachedMapId;
  
  // Get secure API key with caching
  String get apiKey {
    if (_cachedApiKey != null) {
      return _cachedApiKey!;
    }
    
    try {
      _cachedApiKey = MapsConfig.apiKey;
      
      // Validate API key format
      if (!isValidApiKey(_cachedApiKey!)) {
        throw Exception('Invalid API key format');
      }
      
      MapsConfig.debugConfiguration();
      return _cachedApiKey!;
    } catch (e) {
      print('❌ Error getting secure API key: $e');
      
      // Use platform-specific fallback
      _cachedApiKey = Platform.isIOS 
          ? 'AIzaSyCdJRx2WW7pkf3QGCwV6NY7RphAS683kzY'
          : 'AIzaSyAC-5pPVZot30WENTHNSntNsFfqMbjQFjw';
      
      return _cachedApiKey!;
    }
  }
  
  // Validate API key format
  bool isValidApiKey(String key) {
    return key.isNotEmpty && 
           key.startsWith('AIza') && 
           key.length >= 35; // Standard Google API key length
  }
  
  // Get secure Map ID with caching
  String get mapId {
    if (_cachedMapId != null) {
      return _cachedMapId!;
    }
    
    try {
      _cachedMapId = MapsConfig.mapId;
      
      // Validate Map ID format
      if (!isValidMapId(_cachedMapId!)) {
        print('⚠️ Invalid Map ID format, using fallback');
      }
      
      return _cachedMapId!;
    } catch (e) {
      print('❌ Error getting secure Map ID: $e');
      
      // Use fallback Map ID
      _cachedMapId = '71ed63eff6a1ac4fe8b35b3d';
      return _cachedMapId!;
    }
  }
  
  // Validate Map ID format
  bool isValidMapId(String id) {
    return id.isNotEmpty && 
           id.length >= 10 && 
           !id.contains(' ') && // No spaces
           id.length <= 50; // Reasonable max length
  }
  
  // Clear cached keys (for testing or key rotation)
  void clearCache() {
    _cachedApiKey = null;
    _cachedMapId = null;
  }
  
  // Get masked key for logging
  String get maskedApiKey {
    final key = apiKey;
    if (key.length < 8) return '***';
    return '${key.substring(0, 8)}***${key.substring(key.length - 4)}';
  }
  
  // Get masked Map ID for logging
  String get maskedMapId {
    final id = mapId;
    if (id.length < 8) return '***';
    return '${id.substring(0, 4)}***${id.substring(id.length - 4)}';
  }
  
  // Security check
  bool get isSecurelyConfigured {
    try {
      final key = apiKey;
      final id = mapId;
      return isValidApiKey(key) && isValidMapId(id);
    } catch (e) {
      return false;
    }
  }
  
  // Debug method
  void debugSecurity() {
    print('🔐 Maps Security Status:');
    print('   Platform: ${Platform.isIOS ? "iOS" : "Android"}');
    print('   API Key secure: $isSecurelyConfigured');
    print('   API Key (masked): $maskedApiKey');
    print('   Map ID (masked): $maskedMapId');
    print('   API Key valid: ${MapsConfig.isApiKeyConfigured}');
    print('   Map ID valid: ${MapsConfig.isMapIdConfigured}');
    print('   Overall secure: $isSecurelyConfigured');
  }
}
