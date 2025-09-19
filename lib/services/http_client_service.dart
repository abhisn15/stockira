import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_logger.dart';

class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  /// GET request with logging
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final startTime = DateTime.now();
    final request = http.Request('GET', url);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }

    ApiLogger.logRequest(request);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final httpResponse = http.Response(
        responseBody,
        response.statusCode,
        headers: response.headers,
        request: request,
      );

      final duration = DateTime.now().difference(startTime);
      ApiLogger.logResponse(httpResponse, duration: duration);

      return httpResponse;
    } catch (error, stackTrace) {
      ApiLogger.logError(error, stackTrace, context: 'GET $url');
      rethrow;
    }
  }

  /// POST request with logging
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final startTime = DateTime.now();
    final request = http.Request('POST', url);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }
    
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is Map) {
        request.body = jsonEncode(body);
        request.headers['Content-Type'] = 'application/json';
      } else {
        request.body = body.toString();
      }
    }

    ApiLogger.logRequest(request);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final httpResponse = http.Response(
        responseBody,
        response.statusCode,
        headers: response.headers,
        request: request,
      );

      final duration = DateTime.now().difference(startTime);
      ApiLogger.logResponse(httpResponse, duration: duration);

      return httpResponse;
    } catch (error, stackTrace) {
      ApiLogger.logError(error, stackTrace, context: 'POST $url');
      rethrow;
    }
  }

  /// PUT request with logging
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final startTime = DateTime.now();
    final request = http.Request('PUT', url);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }
    
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is Map) {
        request.body = jsonEncode(body);
        request.headers['Content-Type'] = 'application/json';
      } else {
        request.body = body.toString();
      }
    }

    ApiLogger.logRequest(request);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final httpResponse = http.Response(
        responseBody,
        response.statusCode,
        headers: response.headers,
        request: request,
      );

      final duration = DateTime.now().difference(startTime);
      ApiLogger.logResponse(httpResponse, duration: duration);

      return httpResponse;
    } catch (error, stackTrace) {
      ApiLogger.logError(error, stackTrace, context: 'PUT $url');
      rethrow;
    }
  }

  /// DELETE request with logging
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final startTime = DateTime.now();
    final request = http.Request('DELETE', url);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }
    
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is Map) {
        request.body = jsonEncode(body);
        request.headers['Content-Type'] = 'application/json';
      } else {
        request.body = body.toString();
      }
    }

    ApiLogger.logRequest(request);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final httpResponse = http.Response(
        responseBody,
        response.statusCode,
        headers: response.headers,
        request: request,
      );

      final duration = DateTime.now().difference(startTime);
      ApiLogger.logResponse(httpResponse, duration: duration);

      return httpResponse;
    } catch (error, stackTrace) {
      ApiLogger.logError(error, stackTrace, context: 'DELETE $url');
      rethrow;
    }
  }

  /// Multipart request with logging
  static Future<http.Response> multipartRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final startTime = DateTime.now();
    final request = http.MultipartRequest(method, url);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }
    
    if (fields != null) {
      request.fields.addAll(fields);
    }
    
    if (files != null) {
      request.files.addAll(files);
    }

    ApiLogger.logMultipartRequest(request);

    try {
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      
      final duration = DateTime.now().difference(startTime);
      ApiLogger.logMultipartResponse(streamedResponse, duration: duration);

      return http.Response(
        responseBody,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
      );
    } catch (error, stackTrace) {
      ApiLogger.logError(error, stackTrace, context: '$method $url (multipart)');
      rethrow;
    }
  }

  /// Upload file with progress tracking and logging
  static Future<http.Response> uploadFile(
    Uri url,
    File file, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    String fieldName = 'file',
    String? filename,
    void Function(int sent, int total)? onProgress,
  }) async {
    final startTime = DateTime.now();
    
    final request = http.MultipartRequest('POST', url);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }
    
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add file
    final fileBytes = await file.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      fieldName,
      fileBytes,
      filename: filename ?? file.path.split('/').last,
    );
    request.files.add(multipartFile);

    ApiLogger.logMultipartRequest(request);

    try {
      final streamedResponse = await request.send();
      
      // Track upload progress
      if (onProgress != null) {
        int totalBytes = streamedResponse.contentLength ?? fileBytes.length;
        int sentBytes = 0;
        
        streamedResponse.stream.listen(
          (chunk) {
            sentBytes += chunk.length;
            onProgress(sentBytes, totalBytes);
          },
          onDone: () {
            onProgress(totalBytes, totalBytes);
          },
        );
      }

      final responseBody = await streamedResponse.stream.bytesToString();
      
      final duration = DateTime.now().difference(startTime);
      ApiLogger.logMultipartResponse(streamedResponse, duration: duration);

      return http.Response(
        responseBody,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
      );
    } catch (error, stackTrace) {
      ApiLogger.logError(error, stackTrace, context: 'File upload to $url');
      rethrow;
    }
  }

  /// Download file with progress tracking and logging
  static Future<void> downloadFile(
    Uri url,
    String savePath, {
    Map<String, String>? headers,
    void Function(int received, int total)? onProgress,
  }) async {
    final startTime = DateTime.now();
    final request = http.Request('GET', url);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }

    ApiLogger.logRequest(request);

    try {
      final response = await request.send();
      final file = File(savePath);
      
      if (onProgress != null) {
        int totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        
        await for (final chunk in response.stream) {
          await file.writeAsBytes(chunk, mode: FileMode.append);
          receivedBytes += chunk.length;
          onProgress(receivedBytes, totalBytes);
        }
      } else {
        await file.writeAsBytes(await response.stream.toBytes());
      }

      final duration = DateTime.now().difference(startTime);
      ApiLogger.logResponse(
        http.Response('', response.statusCode, headers: response.headers),
        duration: duration,
      );
    } catch (error, stackTrace) {
      ApiLogger.logError(error, stackTrace, context: 'File download from $url');
      rethrow;
    }
  }
}
