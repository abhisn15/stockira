import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class NetworkService {
  // Test basic internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Test API connectivity
  static Future<bool> testApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse(Env.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      // If we get any response (even 404), the connection is working
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }

  // Test specific API endpoint
  static Future<Map<String, dynamic>> testApiEndpoint(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      return {
        'success': true,
        'statusCode': response.statusCode,
        'message': 'Connection successful',
        'data': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Connection failed: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Get network status info
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    final hasInternet = await hasInternetConnection();
    final apiConnection = await testApiConnection();
    
    return {
      'hasInternet': hasInternet,
      'apiConnection': apiConnection,
      'baseUrl': Env.baseUrl,
      'apiBaseUrl': Env.apiBaseUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
