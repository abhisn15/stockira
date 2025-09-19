import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiLogger {
  static const String _tag = '🌐 API';
  static bool _isEnabled = kDebugMode; // Only log in debug mode

  /// Enable or disable API logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if logging is enabled
  static bool get isEnabled => _isEnabled;

  /// Log HTTP request
  static void logRequest(http.Request request) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('$_tag 📤 REQUEST');
    buffer.writeln('${request.method} ${request.url}');
    
    // Log headers (excluding sensitive data)
    if (request.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      request.headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          buffer.writeln('  $key: Bearer ${_maskToken(value)}');
        } else {
          buffer.writeln('  $key: $value');
        }
      });
    }

    // Log body if present
    if (request.body.isNotEmpty) {
      buffer.writeln('Body:');
      try {
        final jsonBody = jsonDecode(request.body);
        buffer.writeln('  ${const JsonEncoder.withIndent('  ').convert(jsonBody)}');
      } catch (e) {
        buffer.writeln('  ${request.body}');
      }
    }

    _printLog(buffer.toString());
  }

  /// Log HTTP response
  static void logResponse(http.Response response, {Duration? duration}) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('$_tag 📥 RESPONSE');
    buffer.writeln('${response.request?.method} ${response.request?.url}');
    buffer.writeln('Status: ${response.statusCode} ${_getStatusMessage(response.statusCode)}');
    
    if (duration != null) {
      buffer.writeln('Duration: ${duration.inMilliseconds}ms');
    }

    // Log headers
    if (response.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      response.headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    // Log body
    if (response.body.isNotEmpty) {
      buffer.writeln('Body:');
      try {
        final jsonBody = jsonDecode(response.body);
        buffer.writeln('  ${const JsonEncoder.withIndent('  ').convert(jsonBody)}');
      } catch (e) {
        buffer.writeln('  ${response.body}');
      }
    }

    _printLog(buffer.toString());
  }

  /// Log HTTP error
  static void logError(dynamic error, StackTrace? stackTrace, {String? context}) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('$_tag ❌ ERROR');
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    buffer.writeln('Error: $error');
    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace.toString());
    }

    _printLog(buffer.toString());
  }

  /// Log multipart request
  static void logMultipartRequest(http.MultipartRequest request) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('$_tag 📤 MULTIPART REQUEST');
    buffer.writeln('${request.method} ${request.url}');
    
    // Log headers (excluding sensitive data)
    if (request.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      request.headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          buffer.writeln('  $key: Bearer ${_maskToken(value)}');
        } else {
          buffer.writeln('  $key: $value');
        }
      });
    }

    // Log form fields
    if (request.fields.isNotEmpty) {
      buffer.writeln('Fields:');
      request.fields.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    // Log files
    if (request.files.isNotEmpty) {
      buffer.writeln('Files:');
      for (final file in request.files) {
        buffer.writeln('  ${file.field}: ${file.filename} (${file.length} bytes)');
      }
    }

    _printLog(buffer.toString());
  }

  /// Log multipart response
  static void logMultipartResponse(http.StreamedResponse response, {Duration? duration}) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('$_tag 📥 MULTIPART RESPONSE');
    buffer.writeln('${response.request?.method} ${response.request?.url}');
    buffer.writeln('Status: ${response.statusCode} ${_getStatusMessage(response.statusCode)}');
    
    if (duration != null) {
      buffer.writeln('Duration: ${duration.inMilliseconds}ms');
    }

    // Log headers
    if (response.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      response.headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    _printLog(buffer.toString());
  }

  /// Mask sensitive token data
  static String _maskToken(String token) {
    if (token.length <= 8) return '***';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  /// Get status message for HTTP status code
  static String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 204: return 'No Content';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 422: return 'Unprocessable Entity';
      case 500: return 'Internal Server Error';
      case 502: return 'Bad Gateway';
      case 503: return 'Service Unavailable';
      default: return '';
    }
  }

  /// Print log with proper formatting
  static void _printLog(String message) {
    if (kDebugMode) {
      // Use developer.log for better formatting in debug console
      developer.log(
        message,
        name: 'API',
        time: DateTime.now(),
      );
    } else {
      print(message);
    }
  }

  /// Log network connectivity status
  static void logNetworkStatus(bool isConnected, {String? details}) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('$_tag 🌍 NETWORK STATUS');
    buffer.writeln('Connected: ${isConnected ? '✅' : '❌'}');
    if (details != null) {
      buffer.writeln('Details: $details');
    }

    _printLog(buffer.toString());
  }

  /// Log API endpoint test
  static void logEndpointTest(String endpoint, bool success, {String? message, int? statusCode}) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('$_tag 🔍 ENDPOINT TEST');
    buffer.writeln('Endpoint: $endpoint');
    buffer.writeln('Status: ${success ? '✅ SUCCESS' : '❌ FAILED'}');
    if (statusCode != null) {
      buffer.writeln('HTTP Status: $statusCode');
    }
    if (message != null) {
      buffer.writeln('Message: $message');
    }

    _printLog(buffer.toString());
  }
}
