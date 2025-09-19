import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import 'http_client_service.dart';
import 'api_logger.dart';

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
      final response = await HttpClientService.get(
        Uri.parse(Env.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      // If we get any response (even 404), the connection is working
      final isConnected = response.statusCode >= 200 && response.statusCode < 500;
      ApiLogger.logEndpointTest(Env.baseUrl, isConnected, statusCode: response.statusCode);
      return isConnected;
    } catch (e) {
      ApiLogger.logEndpointTest(Env.baseUrl, false, message: e.toString());
      return false;
    }
  }

  // Test specific API endpoint
  static Future<Map<String, dynamic>> testApiEndpoint(String endpoint) async {
    try {
      final url = '${Env.apiBaseUrl}$endpoint';
      final response = await HttpClientService.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final result = {
        'success': true,
        'statusCode': response.statusCode,
        'message': 'Connection successful',
        'data': response.body,
      };
      
      ApiLogger.logEndpointTest(url, true, statusCode: response.statusCode);
      return result;
    } catch (e) {
      final result = {
        'success': false,
        'statusCode': 0,
        'message': 'Connection failed: ${e.toString()}',
        'data': null,
      };
      
      ApiLogger.logEndpointTest('${Env.apiBaseUrl}$endpoint', false, message: e.toString());
      return result;
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
