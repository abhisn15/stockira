import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  static const String _attendanceKey = 'attendance_records';
  
  // Singleton pattern
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  // Get all attendance records
  Future<List<AttendanceRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList(_attendanceKey) ?? [];
    
    return recordsJson
        .map((json) => AttendanceRecord.fromJson(jsonDecode(json)))
        .toList();
  }

  // Get records by date range
  Future<List<AttendanceRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allRecords = await getAllRecords();
    return allRecords.where((record) {
      return record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             record.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get records by status
  Future<List<AttendanceRecord>> getRecordsByStatus(String status) async {
    final allRecords = await getAllRecords();
    return allRecords.where((record) => record.status == status).toList();
  }

  // Get today's record
  Future<AttendanceRecord?> getTodayRecord() async {
    final today = DateTime.now();
    final allRecords = await getAllRecords();
    
    try {
      return allRecords.firstWhere((record) {
        return record.date.year == today.year &&
               record.date.month == today.month &&
               record.date.day == today.day;
      });
    } catch (e) {
      return null;
    }
  }

  // Save or update a record
  Future<void> saveRecord(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final allRecords = await getAllRecords();
    
    // Remove existing record with same ID
    allRecords.removeWhere((r) => r.id == record.id);
    
    // Add updated record
    allRecords.add(record);
    
    // Save back to preferences
    final recordsJson = allRecords
        .map((r) => jsonEncode(r.toJson()))
        .toList();
    
    await prefs.setStringList(_attendanceKey, recordsJson);
  }

  // Create new record for today
  Future<AttendanceRecord> createTodayRecord() async {
    final today = DateTime.now();
    final existingRecord = await getTodayRecord();
    
    if (existingRecord != null) {
      return existingRecord;
    }
    
    final newRecord = AttendanceRecord(
      id: '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}',
      date: today,
      createdAt: today,
      updatedAt: today,
    );
    
    await saveRecord(newRecord);
    return newRecord;
  }

  // Check in
  Future<AttendanceRecord> checkIn(String store) async {
    final today = DateTime.now();
    final timeString = '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    
    final record = await createTodayRecord();
    final updatedRecord = record.copyWith(
      checkInTime: timeString,
      store: store,
      status: 'checked_in',
      updatedAt: today,
    );
    
    await saveRecord(updatedRecord);
    return updatedRecord;
  }

  // Check out
  Future<AttendanceRecord> checkOut() async {
    final today = DateTime.now();
    final timeString = '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    
    final record = await getTodayRecord();
    if (record == null || record.checkInTime == null) {
      throw Exception('No check-in found for today');
    }
    
    // Calculate duration
    final checkInParts = record.checkInTime!.split(':');
    final checkInMinutes = int.parse(checkInParts[0]) * 60 + int.parse(checkInParts[1]);
    final checkOutMinutes = today.hour * 60 + today.minute;
    final duration = checkOutMinutes - checkInMinutes;
    
    final updatedRecord = record.copyWith(
      checkOutTime: timeString,
      duration: duration,
      status: 'completed',
      updatedAt: today,
    );
    
    await saveRecord(updatedRecord);
    return updatedRecord;
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    final records = await getRecordsByDateRange(start, end);
    
    final totalDays = records.length;
    final completedDays = records.where((r) => r.isCompleted).length;
    final totalWorkingMinutes = records
        .where((r) => r.isCompleted)
        .fold(0, (sum, r) => sum + r.workingMinutes);
    
    final averageWorkingMinutes = completedDays > 0 
        ? totalWorkingMinutes ~/ completedDays 
        : 0;
    
    return {
      'totalDays': totalDays,
      'completedDays': completedDays,
      'totalWorkingMinutes': totalWorkingMinutes,
      'averageWorkingMinutes': averageWorkingMinutes,
      'completionRate': totalDays > 0 ? (completedDays / totalDays * 100).round() : 0,
    };
  }

  // Clear all records (for testing)
  Future<void> clearAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attendanceKey);
  }
}
