import 'dart:convert';
import '../config/env.dart';
import '../models/store.dart';
import 'auth_service.dart';
import 'http_client_service.dart';

class NearestStoresService {
  /// Get nearest stores based on current location
  static Future<NearestStoresResponse> getNearestStores({
    required double latitude,
    required double longitude,
    double radius = 1.0,
    int limit = 20,
    String unit = 'km',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/stores/nearest').replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius': radius.toString(),
          'limit': limit.toString(),
          'unit': unit,
        },
      );

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NearestStoresResponse.fromJson(data);
      } else {
        throw Exception('Failed to load nearest stores: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading nearest stores: $e');
      rethrow;
    }
  }

  /// Get approved stores (history)
  static Future<NearestStoresResponse> getApprovedStores({
    double? latitude,
    double? longitude,
    double radius = 5.0,
    int limit = 50,
    String unit = 'km',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'unit': unit,
        'approved_only': 'true',
      };

      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
        queryParams['radius'] = radius.toString();
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/stores/nearest').replace(
        queryParameters: queryParams,
      );

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NearestStoresResponse.fromJson(data);
      } else {
        throw Exception('Failed to load approved stores: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading approved stores: $e');
      rethrow;
    }
  }

  /// Get store by ID
  static Future<Store?> getStoreById(int storeId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/stores/$storeId');

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Store.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error loading store by ID: $e');
      return null;
    }
  }

  /// Search stores by name
  static Future<NearestStoresResponse> searchStores({
    required String query,
    double? latitude,
    double? longitude,
    double radius = 10.0,
    int limit = 20,
    String unit = 'km',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final queryParams = <String, String>{
        'search': query,
        'limit': limit.toString(),
        'unit': unit,
      };

      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
        queryParams['radius'] = radius.toString();
      }

      final uri = Uri.parse('${Env.apiBaseUrl}/stores/search').replace(
        queryParameters: queryParams,
      );

      final response = await HttpClientService.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NearestStoresResponse.fromJson(data);
      } else {
        throw Exception('Failed to search stores: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching stores: $e');
      rethrow;
    }
  }

  /// Get stores with retry mechanism
  static Future<NearestStoresResponse> getNearestStoresWithRetry({
    required double latitude,
    required double longitude,
    double radius = 1.0,
    int limit = 20,
    String unit = 'km',
    int retryCount = 0,
    int maxRetries = 3,
  }) async {
    try {
      return await getNearestStores(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: limit,
        unit: unit,
      );
    } catch (e) {
      if (retryCount < maxRetries) {
        print('Retrying get nearest stores (attempt ${retryCount + 1}/$maxRetries): $e');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return getNearestStoresWithRetry(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          limit: limit,
          unit: unit,
          retryCount: retryCount + 1,
          maxRetries: maxRetries,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Validate coordinates
  static bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  /// Get default radius
  static double getDefaultRadius() => 1.0;

  /// Get default limit
  static int getDefaultLimit() => 20;

  /// Get max retries
  static int getMaxRetries() => 3;
}
