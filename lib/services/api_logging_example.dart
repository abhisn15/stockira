import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_client_service.dart';
import 'api_logger.dart';
import '../config/env.dart';

/// Contoh penggunaan sistem logging API
/// File ini menunjukkan cara menggunakan HttpClientService dan ApiLogger
class ApiLoggingExample {
  
  /// Contoh GET request dengan logging
  static Future<void> exampleGetRequest() async {
    try {
      print('=== CONTOH GET REQUEST ===');
      
      final response = await HttpClientService.get(
        Uri.parse('${Env.apiBaseUrl}/test'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      print('Response status: ${response.statusCode}');
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Contoh POST request dengan logging
  static Future<void> examplePostRequest() async {
    try {
      print('=== CONTOH POST REQUEST ===');
      
      final response = await HttpClientService.post(
        Uri.parse('${Env.apiBaseUrl}/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: {
          'name': 'Test User',
          'email': 'test@example.com',
        },
      );
      
      print('Response status: ${response.statusCode}');
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Contoh manual logging
  static void exampleManualLogging() {
    print('=== CONTOH MANUAL LOGGING ===');
    
    // Log network status
    ApiLogger.logNetworkStatus(true, details: 'WiFi Connected');
    
    // Log endpoint test
    ApiLogger.logEndpointTest('/api/test', true, statusCode: 200);
    
    // Log error
    try {
      throw Exception('Test error for logging');
    } catch (e, stackTrace) {
      ApiLogger.logError(e, stackTrace, context: 'Manual logging example');
    }
  }

  /// Contoh multipart request dengan logging
  static Future<void> exampleMultipartRequest() async {
    try {
      print('=== CONTOH MULTIPART REQUEST ===');
      
      // Simulasi multipart request
      final response = await HttpClientService.multipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/upload'),
        headers: {
          'Accept': 'application/json',
        },
        fields: {
          'description': 'Test upload',
          'category': 'example',
        },
        files: [
          // Simulasi file upload (dalam real app, gunakan file asli)
          http.MultipartFile.fromString(
            'file',
            'Test file content',
            filename: 'test.txt',
          ),
        ],
      );
      
      print('Response status: ${response.statusCode}');
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Jalankan semua contoh
  static Future<void> runAllExamples() async {
    print('🚀 Memulai contoh API logging...\n');
    
    // Manual logging
    exampleManualLogging();
    print('\n');
    
    // GET request
    await exampleGetRequest();
    print('\n');
    
    // POST request
    await examplePostRequest();
    print('\n');
    
    // Multipart request
    await exampleMultipartRequest();
    print('\n');
    
    print('✅ Semua contoh selesai!');
    print('📝 Cek console untuk melihat log API yang detail');
  }

  /// Test koneksi API
  static Future<void> testApiConnection() async {
    print('🔍 Testing API connection...');
    
    try {
      final response = await HttpClientService.get(
        Uri.parse(Env.baseUrl),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      ApiLogger.logEndpointTest(Env.baseUrl, true, statusCode: response.statusCode);
      print('✅ API connection successful');
    } catch (e) {
      ApiLogger.logEndpointTest(Env.baseUrl, false, message: e.toString());
      print('❌ API connection failed: $e');
    }
  }

  /// Toggle logging on/off
  static void toggleLogging() {
    final currentStatus = ApiLogger.isEnabled;
    ApiLogger.setEnabled(!currentStatus);
    print('📝 API Logging ${!currentStatus ? 'enabled' : 'disabled'}');
  }
}

/// Widget untuk testing logging di UI (optional)
/// Bisa ditambahkan ke debug menu
class ApiLoggingTestWidget {
  static void showTestMenu() {
    print('''
=== API LOGGING TEST MENU ===
1. Test GET Request
2. Test POST Request  
3. Test Multipart Request
4. Test API Connection
5. Toggle Logging
6. Run All Examples
7. Manual Logging Example

Panggil method yang sesuai untuk testing:
- ApiLoggingExample.exampleGetRequest()
- ApiLoggingExample.examplePostRequest()
- ApiLoggingExample.exampleMultipartRequest()
- ApiLoggingExample.testApiConnection()
- ApiLoggingExample.toggleLogging()
- ApiLoggingExample.runAllExamples()
- ApiLoggingExample.exampleManualLogging()
    ''');
  }
}
