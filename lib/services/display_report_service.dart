import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/env.dart';
import 'auth_service.dart';
import '../models/display_report.dart';
import 'report_completion_service.dart';

class DisplayReportService {
  static final ImagePicker _picker = ImagePicker();

  // Submit display report
  static Future<DisplayReportResponse> submitDisplayReport({
    required int storeId,
    required int typeAdditionalId,
    required String constraint,
    required int totalBucketProduct,
    required List<XFile> images,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return DisplayReportResponse(
          success: false,
          message: 'No authentication token available',
        );
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/reports/display'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['store_id'] = storeId.toString();
      request.fields['type_additional_id'] = typeAdditionalId.toString();
      request.fields['constraint'] = constraint;
      request.fields['total_bucket_product'] = totalBucketProduct.toString();

      // Add images as individual array elements using multipart files
      for (XFile image in images) {
        var imageField = await http.MultipartFile.fromPath(
          'images[]',
          image.path,
          filename: 'display_report_${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg',
        );
        request.files.add(imageField);
      }

      print('Submitting display report...');
      print('Store ID: $storeId');
      print('Type Additional ID: $typeAdditionalId');
      print('Constraint: $constraint');
      print('Total Bucket Product: $totalBucketProduct');
      print('Images count: ${images.length}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Display report response: ${response.statusCode}');
      print('Display report body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Save completion status to local storage
        final submissionTime = DateTime.now();
        final todayDate = submissionTime.toIso8601String().split('T')[0];
        await ReportCompletionService.markReportCompleted(
          storeId: storeId,
          reportType: 'display_report',
          date: todayDate,
          completedAt: submissionTime,
          reportData: {
            'typeAdditionalId': typeAdditionalId,
            'constraint': constraint,
            'totalBucketProduct': totalBucketProduct,
            'imagesCount': images.length,
            'submittedAt': submissionTime.toIso8601String(),
          },
        );
        
        return DisplayReportResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return DisplayReportResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to submit display report',
          );
        } catch (e) {
          return DisplayReportResponse(
            success: false,
            message: 'Failed to submit display report (HTTP ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      print('Error submitting display report: $e');
      return DisplayReportResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get type additionals
  static Future<TypeAdditionalResponse> getTypeAdditionals() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return TypeAdditionalResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/type/additional'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Type additionals API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return TypeAdditionalResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return TypeAdditionalResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to fetch type additionals',
            data: [],
          );
        } catch (e) {
          return TypeAdditionalResponse(
            success: false,
            message: 'Failed to fetch type additionals (HTTP ${response.statusCode})',
            data: [],
          );
        }
      }
    } catch (e) {
      print('Error fetching type additionals: $e');
      return TypeAdditionalResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get attendance check-in data
  static Future<AttendanceResponse> getAttendanceCheckIn() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return AttendanceResponse(
          success: false,
          message: 'No authentication token available',
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/attendances/store/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Attendance check-in API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return AttendanceResponse.fromJson(responseData);
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return AttendanceResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to fetch attendance check-in',
            data: [],
          );
        } catch (e) {
          return AttendanceResponse(
            success: false,
            message: 'Failed to fetch attendance check-in (HTTP ${response.statusCode})',
            data: [],
          );
        }
      }
    } catch (e) {
      print('Error fetching attendance check-in: $e');
      return AttendanceResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Image picker methods
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  static Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultipleMedia(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return images;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
}
