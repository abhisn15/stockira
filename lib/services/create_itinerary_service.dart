import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/itinerary.dart';
import 'auth_service.dart';

class CreateItineraryService {
  // Create itinerary with selected stores
  static Future<CreateItineraryResponse> createItinerary({
    required String date,
    required List<int> storeIds,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return CreateItineraryResponse(
          success: false,
          message: 'No authentication token available',
          data: CreateItineraryData(
            itineraries: [],
            messages: [],
          ),
        );
      }

      final url = '${Env.apiBaseUrl}/itineraries';
      print('🌐 [CreateItineraryService] Calling API: $url');
      print('🌐 [CreateItineraryService] Request body: {"date": "$date", "store_ids": $storeIds}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'date': date,
          'store_ids': storeIds,
        }),
      );

      print('🌐 [CreateItineraryService] Response status: ${response.statusCode}');
      print('🌐 [CreateItineraryService] Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('🌐 [CreateItineraryService] Parsed data: ${responseData}');
        return CreateItineraryResponse.fromJson(responseData);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return CreateItineraryResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to create itinerary',
          data: CreateItineraryData(
            itineraries: [],
            messages: [],
          ),
        );
      }
    } catch (e) {
      print('Error creating itinerary: $e');
      return CreateItineraryResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: CreateItineraryData(
          itineraries: [],
          messages: [],
        ),
      );
    }
  }
}

class CreateItineraryResponse {
  final bool success;
  final String message;
  final CreateItineraryData data;

  CreateItineraryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CreateItineraryResponse.fromJson(Map<String, dynamic> json) {
    return CreateItineraryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: CreateItineraryData.fromJson(json['data'] ?? {}),
    );
  }
}

class CreateItineraryData {
  final List<Itinerary> itineraries;
  final List<String> messages;

  CreateItineraryData({
    required this.itineraries,
    required this.messages,
  });

  factory CreateItineraryData.fromJson(Map<String, dynamic> json) {
    return CreateItineraryData(
      itineraries: (json['itineraries'] as List<dynamic>?)
          ?.map((item) => Itinerary.fromJson(item))
          .toList() ?? [],
      messages: (json['messages'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [],
    );
  }
}
