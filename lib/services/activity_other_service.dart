import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/env.dart';
import '../services/auth_service.dart';
import '../models/activity_other.dart';

class ActivityOtherService {
  static Future<AttendanceResponse> getAttendanceData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/attendances/store/check-in'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('=== ATTENDANCE API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = AttendanceResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        return data;
      } else {
        throw Exception('Failed to load attendance data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading attendance data: $e');
      rethrow;
    }
  }

  static Future<ActivityOtherResponse> submitActivityOther({
    required String activityName,
    required List<String> approves,
    required int storeId,
    XFile? documentationImageFirst,
    XFile? documentationImageSecond,
    XFile? documentationImageThird,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/reports/activity-other'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['activity_name'] = activityName;
      request.fields['store_id'] = storeId.toString();
      
      // Add approves array
      for (int i = 0; i < approves.length; i++) {
        request.fields['approves[$i]'] = approves[i];
      }

      // Add image files if provided
      if (documentationImageFirst != null) {
        final file = await http.MultipartFile.fromPath(
          'documentation_image_first',
          documentationImageFirst.path,
        );
        request.files.add(file);
      }

      if (documentationImageSecond != null) {
        final file = await http.MultipartFile.fromPath(
          'documentation_image_second',
          documentationImageSecond.path,
        );
        request.files.add(file);
      }

      if (documentationImageThird != null) {
        final file = await http.MultipartFile.fromPath(
          'documentation_image_third',
          documentationImageThird.path,
        );
        request.files.add(file);
      }

      print('=== ACTIVITY OTHER REQUEST ===');
      print('Activity Name: $activityName');
      print('Store ID: $storeId');
      print('Approves: $approves');
      print('Images: ${documentationImageFirst != null}, ${documentationImageSecond != null}, ${documentationImageThird != null}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== ACTIVITY OTHER RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ActivityOtherResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        return data;
      } else {
        throw Exception('Failed to submit activity other: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error submitting activity other: $e');
      rethrow;
    }
  }
}
