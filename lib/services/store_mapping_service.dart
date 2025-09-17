import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../services/auth_service.dart';
import '../models/store_mapping.dart';

class StoreMappingService {
  static final StoreMappingService _instance = StoreMappingService._internal();
  factory StoreMappingService() => _instance;
  StoreMappingService._internal();

  Future<List<Store>> getStoresBySubArea(int subAreaId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/stores?conditions[sub_area_id]=$subAreaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((store) => Store.fromJson(store))
              .toList();
        }
      }
      throw Exception('Failed to load stores');
    } catch (e) {
      throw Exception('Error loading stores: $e');
    }
  }

  Future<List<Store>> getStoresByEmployee(int employeeId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/stores?conditions[employees.id]=$employeeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((store) => Store.fromJson(store))
              .toList();
        }
      }
      throw Exception('Failed to load stores');
    } catch (e) {
      throw Exception('Error loading stores: $e');
    }
  }

  Future<List<Area>> getAreas({String? search}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      String url = '${Env.apiBaseUrl}/areas';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((area) => Area.fromJson(area))
              .toList();
        }
      }
      throw Exception('Failed to load areas');
    } catch (e) {
      throw Exception('Error loading areas: $e');
    }
  }

  Future<List<SubArea>> getSubAreas(int areaId, {String? search}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      String url = '${Env.apiBaseUrl}/sub-areas?area_id=$areaId';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((subArea) => SubArea.fromJson(subArea))
              .toList();
        }
      }
      throw Exception('Failed to load sub-areas');
    } catch (e) {
      throw Exception('Error loading sub-areas: $e');
    }
  }

  Future<List<Store>> getEmployeeStores(List<int> storeIds) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/employees/stores'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'store_ids': storeIds}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((store) => Store.fromJson(store))
              .toList();
        }
      }
      throw Exception('Failed to load employee stores');
    } catch (e) {
      throw Exception('Error loading employee stores: $e');
    }
  }

  Future<bool> updateStoreLocation(StoreLocationUpdate locationUpdate) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/stores/location-update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(locationUpdate.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      throw Exception('Failed to update store location');
    } catch (e) {
      throw Exception('Error updating store location: $e');
    }
  }
}
