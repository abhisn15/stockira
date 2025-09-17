import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:stockira/screens/attendance/index.dart';
import 'package:stockira/screens/attendance/CheckIn/maps_checkin_simple.dart';
import 'package:stockira/screens/attendance/CheckOut/maps_checkout_screen.dart';
import 'package:stockira/screens/permit/index.dart';
import 'package:stockira/screens/itinerary/index.dart';
import 'package:stockira/screens/reports/index.dart';
import 'package:stockira/screens/Availability/index.dart';
import 'package:stockira/screens/auth/index.dart';
import 'package:stockira/screens/url_setting/index.dart';
import 'package:stockira/services/attendance_service.dart';
import 'package:stockira/services/auth_service.dart';
import 'package:stockira/services/itinerary_service.dart';
import 'package:stockira/services/maps_service.dart';
import 'package:stockira/services/report_completion_service.dart';
import 'package:stockira/services/reports_api_service.dart';
import 'package:stockira/config/maps_config.dart';
import 'package:stockira/models/attendance_record.dart';
import 'package:stockira/models/itinerary.dart';
import 'package:stockira/widgets/unified_timeline_widget.dart';
import 'package:stockira/widgets/realtime_timer_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/settings_service.dart';
import '../../services/language_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_translate/flutter_translate.dart';

class Env {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get prefixApi => dotenv.env['PREFIX_API'] ?? '';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? '';

  static String get apiBaseUrl => '$baseUrl/$prefixApi/$apiVersion';

  static String get loginUrl => '$apiBaseUrl/login';
  static String get profileUrl => '$apiBaseUrl/me';
}

class User {
  final int id;
  final String name;
  final String? username;
  final String email;
  final String? emailVerifiedAt;
  final int? isActive;
  final String? photoPath;
  final String? photoUrl;
  final String? createdAt;
  final String? updatedAt;
  final List<Role> roles;
  final Employee? employee;

  User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.emailVerifiedAt,
    this.isActive,
    this.photoPath,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    required this.roles,
    this.employee,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      isActive: json['is_active'] as int?,
      photoPath: json['photo_path'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((role) => Role.fromJson(role as Map<String, dynamic>))
              .toList() ??
          [],
      employee: json['employee'] != null
          ? Employee.fromJson(json['employee'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'is_active': isActive,
      'photo_path': photoPath,
      'photo_url': photoUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'roles': roles.map((role) => role.toJson()).toList(),
      'employee': employee?.toJson(),
    };
  }
}

class Role {
  final int id;
  final String name;
  final String? guardName;
  final String? description;
  final int? isActive;
  final String? createdAt;
  final String? updatedAt;
  final Pivot? pivot;

  Role({
    required this.id,
    required this.name,
    this.guardName,
    this.description,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      guardName: json['guard_name'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      pivot: json['pivot'] != null
          ? Pivot.fromJson(json['pivot'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'guard_name': guardName,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pivot': pivot?.toJson(),
    };
  }
}

class Pivot {
  final String modelType;
  final int modelId;
  final int roleId;

  Pivot({required this.modelType, required this.modelId, required this.roleId});

  factory Pivot.fromJson(Map<String, dynamic> json) {
    return Pivot(
      modelType: json['model_type'] as String,
      modelId: json['model_id'] as int,
      roleId: json['role_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'model_type': modelType, 'model_id': modelId, 'role_id': roleId};
  }
}

class Position {
  final int id;
  final String name;
  final String slug;
  final String? description;

  Position({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'description': description};
  }
}

class Agency {
  final int id;
  final String name;
  final String slug;

  Agency({required this.id, required this.name, required this.slug});

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}

class BranchOffice {
  final int id;
  final String name;

  BranchOffice({required this.id, required this.name});

  factory BranchOffice.fromJson(Map<String, dynamic> json) {
    return BranchOffice(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class City {
  final String id;
  final String code;
  final String name;
  final Meta meta;

  City({
    required this.id,
    required this.code,
    required this.name,
    required this.meta,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'code': code, 'name': name, 'meta': meta.toJson()};
  }
}

class Meta {
  final String lat;
  final String longitude;

  Meta({required this.lat, required this.longitude});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(lat: json['lat'] as String, longitude: json['long'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'long': longitude};
  }
}

class SubArea {
  final int id;
  final String name;
  final String? code;

  SubArea({required this.id, required this.name, this.code});

  factory SubArea.fromJson(Map<String, dynamic> json) {
    return SubArea(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}

class Employee {
  final int id;
  final int? userId;
  final String name;
  final String nik;
  final String nikKtp;
  final String code;
  final String phone;
  final String gender;
  final String joinAt;
  final String? birthDate;
  final String? address;
  final int? isLeader;
  final dynamic leader;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? ktpUrl;
  final String? ktpPath;
  final String? bankAccountUrl;
  final String? bankAccountPath;
  final int? isAppUsed;
  final String? appVersion;
  final String? appDevice;
  final int? isResigned;
  final String? requestedResignedAt;
  final String? resignedAt;
  final String? resignedReason;
  final String? resignedNotes;
  final String? resignedPicName;
  final String? rejoinAt;
  final String? rejoinReason;
  final String? rejoinPicName;
  final String status;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final Position? position;
  final Agency? agency;
  final BranchOffice? branchOffice;
  final City? city;
  final SubArea? subArea;

  Employee({
    required this.id,
    this.userId,
    required this.name,
    required this.nik,
    required this.nikKtp,
    required this.code,
    required this.phone,
    required this.gender,
    required this.joinAt,
    this.birthDate,
    this.address,
    this.isLeader,
    this.leader,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.ktpUrl,
    this.ktpPath,
    this.bankAccountUrl,
    this.bankAccountPath,
    this.isAppUsed,
    this.appVersion,
    this.appDevice,
    this.isResigned,
    this.requestedResignedAt,
    this.resignedAt,
    this.resignedReason,
    this.resignedNotes,
    this.resignedPicName,
    this.rejoinAt,
    this.rejoinReason,
    this.rejoinPicName,
    required this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.position,
    this.agency,
    this.branchOffice,
    this.city,
    this.subArea,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String,
      nik: json['nik'] as String,
      nikKtp: json['nik_ktp'] as String,
      code: json['code'] as String,
      phone: json['phone'] as String,
      gender: json['gender'] as String,
      joinAt: json['join_at'] as String,
      birthDate: json['birth_date'] as String?,
      address: json['address'] as String?,
      isLeader: json['is_leader'] as int?,
      leader: json['leader'],
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      ktpUrl: json['ktp_url'] as String?,
      ktpPath: json['ktp_path'] as String?,
      bankAccountUrl: json['bank_account_url'] as String?,
      bankAccountPath: json['bank_account_path'] as String?,
      isAppUsed: json['is_app_used'] as int?,
      appVersion: json['app_version'] as String?,
      appDevice: json['app_device'] as String?,
      isResigned: json['is_resigned'] as int?,
      requestedResignedAt: json['requested_resigned_at'] as String?,
      resignedAt: json['resigned_at'] as String?,
      resignedReason: json['resigned_reason'] as String?,
      resignedNotes: json['resigned_notes'] as String?,
      resignedPicName: json['resigned_pic_name'] as String?,
      rejoinAt: json['rejoin_at'] as String?,
      rejoinReason: json['rejoin_reason'] as String?,
      rejoinPicName: json['rejoin_pic_name'] as String?,
      status: json['status'] as String,
      deletedAt: json['deleted_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      position: json['position'] != null
          ? Position.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      agency: json['agency'] != null
          ? Agency.fromJson(json['agency'] as Map<String, dynamic>)
          : null,
      branchOffice: json['branch_office'] != null
          ? BranchOffice.fromJson(json['branch_office'] as Map<String, dynamic>)
          : null,
      city: json['city'] != null
          ? City.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      subArea: json['sub_area'] != null
          ? SubArea.fromJson(json['sub_area'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'nik': nik,
      'nik_ktp': nikKtp,
      'code': code,
      'phone': phone,
      'gender': gender,
      'join_at': joinAt,
      'birth_date': birthDate,
      'address': address,
      'is_leader': isLeader,
      'leader': leader,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'ktp_url': ktpUrl,
      'ktp_path': ktpPath,
      'bank_account_url': bankAccountUrl,
      'bank_account_path': bankAccountPath,
      'is_app_used': isAppUsed,
      'app_version': appVersion,
      'app_device': appDevice,
      'is_resigned': isResigned,
      'requested_resigned_at': requestedResignedAt,
      'resigned_at': resignedAt,
      'resigned_reason': resignedReason,
      'resigned_notes': resignedNotes,
      'resigned_pic_name': resignedPicName,
      'rejoin_at': rejoinAt,
      'rejoin_reason': rejoinReason,
      'rejoin_pic_name': rejoinPicName,
      'status': status,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'position': position?.toJson(),
      'agency': agency?.toJson(),
      'branch_office': branchOffice?.toJson(),
      'city': city?.toJson(),
      'sub_area': subArea?.toJson(),
    };
  }
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const DashboardScreen({super.key, this.onThemeChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final theme = const Color.fromARGB(255, 41, 189, 206);
  final AttendanceService _attendanceService = AttendanceService();
  final MapsService _mapsService = MapsService();

  int _selectedIndex = 0;

  // Activities stored in localStorage
  List<Map<String, dynamic>> activities = [];

  // Itinerary data
  int itineraryCount = 0;
  DateTime itineraryDate = DateTime.now();
  bool isLoadingItinerary = false;
  List<Itinerary>? itineraryList;

  // Check-in/check-out state
  bool isCheckedIn = false;
  AttendanceRecord? todayRecord;

  // Filter states
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String? filterStatus;

  // Settings state
  bool _notificationEnabled = true;
  bool _darkModeEnabled = false;
  String _currentLanguage = 'en';

  // Profile data
  String? name;
  String? profileEmail;
  String? profilePhotoUrl;
  String? profilePosition;
  String? profileEmployeeId;

  // New bottom nav: Home, Payslip, Activity
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Debug security configuration on startup
    _mapsService.debugSecurity();

    _loadActivitiesFromStorage();
    _loadTodayRecord();
    _loadProfile();
    _loadItineraryCount();
    _loadSettings();
    _screens = [
      DashboardHome(
        onCheckIn: _handleCheckIn,
        onCheckOut: _handleCheckOut,
        isCheckedIn: isCheckedIn,
        itineraryCount: itineraryCount,
        itineraryDate: itineraryDate,
        onReload: _handleReload,
        activities:
            _getTodayActivities(), // Only show today's activities in home
        onShowAllFeatures: _showAllFeaturesBottomSheet,
        onShowFilters: _showFiltersDialog,
        name: name,
        profilePosition: profilePosition,
        profileEmail: profileEmail,
        profilePhotoUrl: profilePhotoUrl,
        itineraryList: itineraryList,
        todayRecord: todayRecord,
      ),
      Center(
        child: Text(translate('payslip'), style: const TextStyle(fontSize: 24)),
      ),
      ActivityScreen(), // Remove activities parameter, will handle filtering internally
    ];
  }

  // Load activities from SharedPreferences
  Future<void> _loadActivitiesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getString('user_activities');
      if (activitiesJson != null) {
        final List<dynamic> activitiesList = json.decode(activitiesJson);
        setState(() {
          activities = activitiesList
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading activities from storage: $e');
    }
  }

  // Save activities to SharedPreferences
  Future<void> _saveActivitiesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = json.encode(activities);
      await prefs.setString('user_activities', activitiesJson);
    } catch (e) {
      print('Error saving activities to storage: $e');
    }
  }

  // Get only today's activities for home screen
  List<Map<String, dynamic>> _getTodayActivities() {
    final today = DateTime.now();
    return activities.where((activity) {
      // Check if activity has date information and matches today
      if (activity['checkInTime'] != null) {
        final checkInTime = activity['checkInTime'] as DateTime;
        return checkInTime.year == today.year &&
            checkInTime.month == today.month &&
            checkInTime.day == today.day;
      }
      return false;
    }).toList();
  }

  Future<void> _loadTodayRecord() async {
    try {
      print('🔄 Loading today record...');
      final record = await _attendanceService.getTodayRecord();
      print('📋 Record received: ${record?.toString()}');
      print('✅ Check-in status: ${record?.isCheckedIn}');
      print('🏪 Store name: ${record?.storeName}');

      setState(() {
        todayRecord = record;
        isCheckedIn = record?.isCheckedIn ?? false;
      });

      // Save today's record to local storage for activity screen
      if (record != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final recordData = {
            'storeId': record.storeId,
            'storeName': record.storeName,
            'checkInTime': record.checkInTime?.toIso8601String(),
            'checkOutTime': record.checkOutTime?.toIso8601String(),
            'isCheckedIn': record.isCheckedIn,
            'date': record.date.toIso8601String(),
          };

          await prefs.setString(
            'today_attendance_record',
            jsonEncode(recordData),
          );
          print(
            '💾 Saved today record to local storage: store ${record.storeId}, checkIn=${record.checkInTime}, checkOut=${record.checkOutTime}',
          );
        } catch (e) {
          print('❌ Error saving today record to local storage: $e');
        }
      }

      print('🎯 State updated - isCheckedIn: $isCheckedIn');
      print('🏪 State updated - store: ${todayRecord?.storeName}');
    } catch (e) {
      print('❌ Error loading today record: $e');
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // Load user data from SharedPreferences (saved during login)
    setState(() {
      name = prefs.getString('user_name') ?? '';
      profileEmail = prefs.getString('user_email') ?? '';
      profilePhotoUrl = prefs.getString('user_profile') ?? '';
      profilePosition = prefs.getString('user_position') ?? '';
      profileEmployeeId = prefs.getString('user_employee_id') ?? '';
    });

    print('Profile loaded: $name, $profileEmail, $profilePosition');
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getAllSettings();
    setState(() {
      _notificationEnabled = settings['notification'] as bool;
      _darkModeEnabled = settings['darkMode'] as bool;
      _currentLanguage = settings['language'] as String;
    });
    // Language service is now handled by flutter_translate
  }

  Future<void> _updateNotificationSetting(bool enabled) async {
    await SettingsService.setNotificationEnabled(enabled);
    setState(() {
      _notificationEnabled = enabled;
    });
  }

  Future<void> _updateDarkModeSetting(bool enabled) async {
    await SettingsService.setDarkModeEnabled(enabled);
    setState(() {
      _darkModeEnabled = enabled;
    });
    // Trigger theme change in main app
    widget.onThemeChanged?.call();
  }

  Future<void> _updateLanguageSetting(String language) async {
    await SettingsService.setLanguage(language);
    changeLocale(context, language);
    setState(() {
      _currentLanguage = language;
    });
    // Trigger rebuild to update all text
    setState(() {});
  }

  // Calculate active itinerary count (stores that are not yet checked out)
  int _calculateActiveItineraryCount(List<dynamic> stores) {
    int activeCount = 0;
    
    for (final store in stores) {
      final storeId = store['id'] as int? ?? 0;
      final attendanceStatus = _getAttendanceStatus(storeId);
      
      if (attendanceStatus == null) {
        // No attendance data - store is still active
        activeCount++;
        print('🏪 Store $storeId: No attendance data - ACTIVE');
      } else {
        final checkInTime = attendanceStatus['checkInTime'] as String?;
        final checkOutTime = attendanceStatus['checkOutTime'] as String?;
        
        if (checkInTime != null && checkOutTime == null) {
          // Checked in but not checked out - still active
          activeCount++;
          print('🏪 Store $storeId: Checked in but not out - ACTIVE (Check-in: $checkInTime)');
        } else if (checkInTime == null) {
          // Not checked in - still active
          activeCount++;
          print('🏪 Store $storeId: Not checked in - ACTIVE');
        } else if (checkInTime != null && checkOutTime != null) {
          // Both checked in and out - completed
          print('🏪 Store $storeId: Checked in and out - COMPLETED (Check-in: $checkInTime, Check-out: $checkOutTime)');
        }
      }
    }
    
    print('📊 Total active itineraries: $activeCount out of ${stores.length}');
    return activeCount;
  }

  Future<void> _loadItineraryCount() async {
    setState(() {
      isLoadingItinerary = true;
    });

    try {
      // Use the main itineraries endpoint to get all itineraries
      final response = await ItineraryService.getItineraries();

      // Debug logging to see what data we're getting
      print('=== ITINERARY DEBUG ===');
      print('API Response Success: ${response.success}');
      print('API Response Message: ${response.message}');
      print('API Response Data Length: ${response.data[0].stores.length}');
      print('API Response Data: ${response.data}');
      print('=======================');

      setState(() {
        itineraryList = response.data;
        // Calculate active itinerary count (not yet checked out)
        itineraryCount = _calculateActiveItineraryCount(response.data[0].stores);
        itineraryDate = DateTime.now();
        isLoadingItinerary = false;
      });

      print(
        'Dashboard - Active itinerary count: $itineraryCount',
      );
      print('Dashboard - itineraryList length: ${itineraryList?.length}');
      print('Dashboard - itineraryCount: $itineraryCount');
    } catch (e) {
      print('Error loading itinerary count: $e');
      setState(() {
        itineraryList = [];
        itineraryCount = 0;
        itineraryDate = DateTime.now();
        isLoadingItinerary = false;
      });
    }
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        _showProfileDialog(context);
        break;
      case 'settings':
        _showSettingsDialog(context);
        break;
      case 'help':
        _showHelpDialog(context);
        break;
      case 'debug_clear':
        _handleDebugClear();
        break;
      case 'force_checkin':
        _handleForceCheckinState();
        break;
      case 'debug_security':
        _handleDebugSecurity();
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person, color: theme),
              const SizedBox(width: 8, height: 20),
              Text(translate('profile')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme,
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                name ?? translate('johnDoe'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(profilePosition ?? translate('employee')),
              const SizedBox(height: 4),
              Text(
                profileEmail ?? 'john.doe@company.com',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                '${translate('employeeId')}: ${profileEmployeeId ?? translate('emp001')}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translate('close')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to edit profile screen
              },
              child: Text(translate('editProfile')),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: theme),
              const SizedBox(width: 8),
                  Text(translate('settings')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                  // Notifications
              ListTile(
                leading: const Icon(Icons.notifications),
                    title: Text(translate('notifications')),
                trailing: Switch(
                      value: _notificationEnabled,
                  onChanged: (value) {
                        _updateNotificationSetting(value);
                        setDialogState(() {});
                  },
                ),
              ),

                  // Dark Mode
              ListTile(
                leading: const Icon(Icons.dark_mode),
                    title: Text(translate('darkMode')),
                trailing: Switch(
                      value: _darkModeEnabled,
                  onChanged: (value) {
                        _updateDarkModeSetting(value);
                        setDialogState(() {});
                  },
                ),
              ),

                  // Language
              ListTile(
                leading: const Icon(Icons.language),
                    title: Text(translate('language')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          SettingsService.getLanguageDisplayName(
                            _currentLanguage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                onTap: () {
                      _showLanguageDialog(context, setDialogState);
                },
              ),

                  // URL Settings
              ListTile(
                leading: const Icon(Icons.link),
                    title: Text(translate('urlSettings')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pop(); // Close settings dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UrlSettingScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
                  child: Text(translate('close')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translate('selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(translate('english')),
                trailing: _currentLanguage == 'en'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _updateLanguageSetting('en');
                  setDialogState(() {});
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(translate('indonesian')),
                trailing: _currentLanguage == 'id'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _updateLanguageSetting('id');
                  setDialogState(() {});
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translate('cancel')),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: theme),
              const SizedBox(width: 8),
              Text(translate('helpSupport')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translate('needHelp'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.phone,
                title: translate('contactSupport'),
                subtitle: translate('callUs'),
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                icon: Icons.email,
                title: translate('emailSupport'),
                subtitle: 'support@company.com',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                icon: Icons.chat,
                title: translate('liveChat'),
                subtitle: 'Available 24/7',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translate('close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: theme),
              const SizedBox(width: 8),
              Text(translate('logout')),
            ],
          ),
          content: Text(
            translate('areYouSureLogout'),
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme,
                foregroundColor: Colors.white,
              ),
              child: Text(translate('logout')),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    // Store context references before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(translate('loggingOut')),
            ],
          ),
        );
      },
    );

    try {
      // Call logout API first (while token is still available)
      final logoutSuccess = await AuthService.logoutApi();
      if (logoutSuccess) {
        print('Logout API successful');
      } else {
        print('Logout API failed, but continuing with local logout');
      }

      // Clear authentication data after API call
      await AuthService.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remembered_email');

      // Clear user profile data
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_profile');
      await prefs.remove('user_employee_id');
      await prefs.remove('user_position');

      // Try to delete from secure storage, fallback to SharedPreferences
      try {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'remembered_password');
      } catch (e) {
        print(
          'Secure storage not available, removing from SharedPreferences: $e',
        );
        await prefs.remove('remembered_password');
      }

      // Close loading dialog
      navigator.pop();

      // Navigate back to auth screen
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(translate('successfullyLoggedOut')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Handle any errors gracefully
      print('Error during logout: $e');
      // Close loading dialog
      navigator.pop();

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${translate('logoutFailed')}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCheckIn() async {
    try {
      print('🚀 Starting check-in process...');

      // Check if itinerary is available
      if (itineraryList == null || itineraryList!.isEmpty) {
        print('❌ No itinerary available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No itinerary available. Please check your schedule.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('📍 Navigating to maps check-in screen...');

      // Navigate directly to simplified maps check-in screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) =>
              MapsCheckinSimpleScreen(itineraryList: itineraryList!),
        ),
      );

      print('🔄 Navigation result: $result');

      // If check-in was successful, reload data and update UI
      if (result == true) {
        print('✅ Check-in successful, reloading data...');

        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Text(translate('updatingDashboard')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Use robust reload method
        await _forceReloadData();

        // Save attendance data to local storage - temporarily disabled
        // if (todayRecord != null) {
        //   await _saveAttendanceData(todayRecord!, 'checkin');
        // }

        // Add to activities with current time
        final now = DateTime.now();
        final timeString = _formatTimeForActivity(now);

        setState(() {
          activities.insert(0, {
            'icon': Icons.login,
            'title': 'Check In',
            'subtitle': todayRecord?.storeName ?? 'Unknown Store',
            'time': timeString,
            'checkInTime': now,
            'color': Colors.green,
            'type': 'checkin',
            'timestamp': now,
          });
        });
        _saveActivitiesToStorage();

        print('✅ Dashboard updated successfully');
        print('🏪 Current store: ${todayRecord?.storeName}');
        print('✅ Is checked in: $isCheckedIn');
      } else {
        print('❌ Check-in was cancelled or failed');
      }
    } catch (e) {
      print('❌ Error during check-in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${translate('errorDuringCheckIn')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _forceReloadData() async {
    print('🔄 Force reloading all data...');

    // Debug current attendance data
    await _attendanceService.debugAllRecords();

    // Try multiple times to ensure data is loaded
    for (int i = 0; i < 3; i++) {
      print('🔄 Attempt ${i + 1} to reload data...');
      await _loadTodayRecord();

      // If we successfully have the check-in data and isCheckedIn is true, break
      if (todayRecord?.checkInTime != null &&
          todayRecord?.checkOutTime == null) {
        print('✅ Successfully loaded ACTIVE check-in data on attempt ${i + 1}');
        break;
      }

      print(
        '⚠️ Attempt ${i + 1}: checkIn=${todayRecord?.checkInTime}, checkOut=${todayRecord?.checkOutTime}, isCheckedIn=${todayRecord?.isCheckedIn}',
      );

      // Wait before retry
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Force a setState to trigger rebuild
    setState(() {
      // This will trigger a rebuild
    });
  }

  // Debug method to clear conflicting data
  Future<void> _clearOldAttendanceData() async {
    print('🧹 Clearing old attendance data...');
    await _attendanceService.clearAllAttendanceData();
    setState(() {
      todayRecord = null;
      isCheckedIn = false;
      activities.clear();
    });
    await _loadTodayRecord();
  }

  Future<void> _handleCheckOut() async {
    try {
      print('🔴 DASHBOARD CHECKOUT CALLED!');
      print(
        '✅ Current state: isCheckedIn=$isCheckedIn, store=${todayRecord?.storeName}',
      );

      // ✅ Guard: pastikan benar-benar sedang checked-in
      if (!isCheckedIn ||
          todayRecord == null ||
          todayRecord!.checkInTime == null) {
        print('❌ Invalid checkout attempt - not currently checked in');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('notCurrentlyCheckedIn')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('✅ Valid checkout state, showing maps checkout...');
      // Navigate to maps checkout screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => MapsCheckoutScreen(currentRecord: todayRecord!),
        ),
      );

      if (result == true) {
        // Checkout successful, reload data
        await _loadTodayRecord();

        // Save attendance data to local storage - temporarily disabled
        // if (todayRecord != null) {
        //   await _saveAttendanceData(todayRecord!, 'checkout');
        // }

        final now = DateTime.now();
        final timeString = _formatTimeForActivity(now);

        setState(() {
          activities.insert(0, {
            'icon': Icons.logout,
            'title': 'Check Out',
            'subtitle': todayRecord?.storeName ?? 'Unknown Store',
            'time': timeString,
            'checkOutTime': now,
            'duration': todayRecord?.workingHoursFormatted ?? '-',
            'color': Colors.red,
            'type': 'checkout',
            'timestamp': now,
          });
        });
        _saveActivitiesToStorage();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('successfullyCheckedOut'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${translate('errorCheckingOut')}: $e')),
      );
    }
  }

  String _formatTimeForActivity(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(translate('filterAttendance')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date range picker
              ListTile(
                title: Text(translate('startDate')),
                subtitle: Text(
                  filterStartDate?.toString().split(' ')[0] ?? 'Select date',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filterStartDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() {
                      filterStartDate = date;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(translate('endDate')),
                subtitle: Text(
                  filterEndDate?.toString().split(' ')[0] ?? 'Select date',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filterEndDate ?? DateTime.now(),
                    firstDate: filterStartDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() {
                      filterEndDate = date;
                    });
                  }
                },
              ),
              // Status filter
              DropdownButtonFormField<String>(
                value: filterStatus,
                decoration: InputDecoration(labelText: translate('status')),
                items: [
                  DropdownMenuItem(value: null, child: Text(translate('all'))),
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text(translate('pending')),
                  ),
                  DropdownMenuItem(
                    value: 'checked_in',
                    child: Text(translate('checkedIn')),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text(translate('completed')),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    filterStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  filterStartDate = null;
                  filterEndDate = null;
                  filterStatus = null;
                });
              },
              child: Text(translate('clear')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.of(context).pop();
              },
              child: Text(translate('apply')),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReload() async {
    print('🔄 Manual reload triggered...');

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(width: 16),
              Text(translate('refreshingData')),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 41, 189, 206),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Debug attendance data before reload
    await _attendanceService.debugAllRecords();

    // Reload all data
    await _loadItineraryCount();
    await _forceReloadData(); // Use robust reload method
    await _loadProfile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data refreshed! Found $itineraryCount itinerary${itineraryCount != 1 ? 's' : ''}${isCheckedIn ? ' • Currently checked in at ${todayRecord?.storeName}' : ''}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Temporary debug method for clearing old data
  void _handleDebugClear() async {
    // Show current state first
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Current State'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('isCheckedIn: $isCheckedIn'),
            Text('todayRecord: ${todayRecord != null ? "exists" : "null"}'),
            Text('checkInTime: ${todayRecord?.checkInTime}'),
            Text('checkOutTime: ${todayRecord?.checkOutTime}'),
            Text('storeName: ${todayRecord?.storeName}'),
            Text('record.isCheckedIn: ${todayRecord?.isCheckedIn}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translate('close')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _attendanceService.debugAllRecords();
            },
            child: const Text('Debug Records'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showClearDataDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Attendance Data'),
        content: const Text(
          'This will clear all old attendance data and reset state. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear & Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearOldAttendanceData();

      // Force reload semua data
      await _loadItineraryCount();
      await _loadProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Data cleared and state reset'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Method untuk force fix check-in state yang bermasalah
  void _handleForceCheckinState() async {
    print('🔧 Force fixing check-in state...');
    await _attendanceService.debugAllRecords();

    // Cari semua record hari ini
    final allRecords = await _attendanceService.getAllRecords();
    final today = DateTime.now();

    final todayRecords = allRecords
        .where(
          (r) =>
              r.date.year == today.year &&
              r.date.month == today.month &&
              r.date.day == today.day,
        )
        .toList();

    if (todayRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No records found for today'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tampilkan dialog untuk pilih record
    final selectedRecord = await showDialog<AttendanceRecord>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Record to Activate'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: todayRecords.length,
            itemBuilder: (context, index) {
              final record = todayRecords[index];
              return ListTile(
                title: Text('Record ${index + 1}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${translate('store')}: ${record.storeName ?? translate('unknown')}',
                    ),
                    Text('CheckIn: ${record.checkInTime}'),
                    Text('CheckOut: ${record.checkOutTime}'),
                    Text('IsCheckedIn: ${record.isCheckedIn}'),
                  ],
                ),
                onTap: () => Navigator.pop(context, record),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translate('cancel')),
          ),
        ],
      ),
    );

    if (selectedRecord != null) {
      // Force set state dengan record yang dipilih
      setState(() {
        todayRecord = selectedRecord;
        isCheckedIn = selectedRecord.isCheckedIn;
      });

      print(
        '✅ Manually set state: isCheckedIn=$isCheckedIn, store=${selectedRecord.storeName}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ State manually set! isCheckedIn: $isCheckedIn'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Method untuk debug security configuration
  void _handleDebugSecurity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Security Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityItem(
              'Maps API Key',
              _mapsService.isSecurelyConfigured
                  ? translate('configured')
                  : translate('missing'),
              _mapsService.isSecurelyConfigured ? Colors.green : Colors.red,
            ),
            SizedBox(height: 8),
            _buildSecurityItem(
              translate('platform'),
              MapsConfig.platformName,
              Colors.blue,
            ),
            SizedBox(height: 8),
            _buildSecurityItem(
              'API Key (Masked)',
              _mapsService.maskedApiKey,
              Colors.grey,
            ),
            SizedBox(height: 8),
            _buildSecurityItem(
              'Map ID (Masked)',
              _mapsService.maskedMapId,
              Colors.grey,
            ),
            SizedBox(height: 8),
            _buildSecurityItem(
              translate('environment'),
              dotenv.env.isNotEmpty
                  ? translate('loaded')
                  : translate('notLoaded'),
              dotenv.env.isNotEmpty ? Colors.green : Colors.orange,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API keys are secured via environment variables and not exposed in source code',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mapsService.debugSecurity();
              MapsConfig.debugConfiguration();
            },
            child: Text('Debug Console'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translate('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _showAllFeaturesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (ctx) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: MediaQuery.of(ctx).viewInsets,
          child: FractionallySizedBox(
            widthFactor: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const Text(
                        'All Features',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 3;
                          if (constraints.maxWidth > 600) crossAxisCount = 4;
                          return GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 24,
                                  crossAxisSpacing: 24,
                                  childAspectRatio: 0.95,
                                ),
                            children: [
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.access_time,
                                label: translate('attendance'),
                                color: const Color(0xFF29BDCE),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AttendanceScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.event_note,
                                label: translate('permit'),
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PermitScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.route,
                                label: translate('itinerary'),
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ItineraryScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.assessment,
                                label: translate('reports'),
                                color: const Color(0xFF29BDCE),
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  final result = await Navigator.of(context)
                                      .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => const ReportsScreen(),
                                    ),
                                  );
                                  // Refresh todo completion status if report was submitted
                                  if (result == true) {
                                    print(
                                      '🔄 Report submitted, refreshing todo completion status...',
                                    );
                                    setState(() {});
                                  }
                                },
                              ),
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.receipt_long,
                                label: translate('payslip'),
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _selectedIndex = 1;
                                  });
                                },
                              ),
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.list_alt,
                                label: translate('activity'),
                                color: Colors.teal,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _selectedIndex = 2;
                                  });
                                },
                              ),
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.storefront,
                                label: translate('Availability'),
                                color: const Color(0xFF2E7D32),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AvailabilityScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureIcon({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild DashboardHome with latest data
    _screens[0] = DashboardHome(
      onCheckIn: _handleCheckIn,
      onCheckOut: _handleCheckOut,
      isCheckedIn: isCheckedIn,
      itineraryCount: itineraryCount,
      itineraryDate: itineraryDate,
      onReload: _handleReload,
      activities: activities,
      onShowAllFeatures: _showAllFeaturesBottomSheet,
      onShowFilters: _showFiltersDialog,
      name: name,
      profilePosition: profilePosition,
      profileEmail: profileEmail,
      profilePhotoUrl: profilePhotoUrl,
      itineraryList: itineraryList,
      todayRecord: todayRecord,
    );

    print(
      '🔧 Build called - isCheckedIn: $isCheckedIn, store: ${todayRecord?.storeName}',
    );
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Refresh itinerary data when switching to home tab
          if (index == 0) {
            _loadItineraryCount();
          }
          // Refresh todo completion status when switching to activity tab
          if (index == 2) {
            // ActivityScreen will handle its own refresh
            setState(() {});
          }
        },
        selectedItemColor: const Color.fromARGB(255, 41, 189, 206),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: translate('payslip'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: translate('activity'),
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final bool isCheckedIn;
  final int itineraryCount;
  final DateTime itineraryDate;
  final VoidCallback onReload;
  final List<Map<String, dynamic>> activities;
  final void Function(BuildContext) onShowAllFeatures;
  final VoidCallback onShowFilters;
  final String? name;
  final String? profilePosition;
  final String? profileEmail;
  final String? profilePhotoUrl;
  final List<Itinerary>? itineraryList;
  final AttendanceRecord? todayRecord;

  const DashboardHome({
    super.key,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.isCheckedIn,
    required this.itineraryCount,
    required this.itineraryDate,
    required this.onReload,
    required this.activities,
    required this.onShowAllFeatures,
    required this.onShowFilters,
    this.name,
    this.profilePosition,
    this.profileEmail,
    this.profilePhotoUrl,
    this.itineraryList,
    this.todayRecord,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onReload();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountCard(context),
            const SizedBox(height: 20),
            _buildInformationCard(context),
            const SizedBox(height: 20),
            _buildRecentActivities(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final displayName = (name != null && name!.trim().isNotEmpty)
        ? (profilePosition != null && profilePosition!.trim().isNotEmpty
              ? '$name ($profilePosition)'
              : name!)
        : 'John Doe (SPG)';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 16,
      ), // Tambahkan margin top agar tidak terlalu nempel atas
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // SVG Siluet Background
          // SVG siluet batik elegan dan siluet orang SPG, memenuhi card & terpengaruh padding
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: 1,
                  child: SvgPicture.string('''
                    <svg width="100%" height="100%" viewBox="0 0 400 180" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <!-- Batik wave motif background -->
                      <path d="M0 150 Q60 120 120 150 T240 150 T400 150 V180 H0 Z" fill="#29BDCE" fill-opacity="0.13"/>
                      <path d="M0 130 Q80 100 160 130 T320 130 T400 130" stroke="#29BDCE" stroke-width="2" fill="none" opacity="0.18"/>
                      <path d="M0 170 Q100 140 200 170 T400 170" stroke="#29BDCE" stroke-width="2" fill="none" opacity="0.10"/>
                      <ellipse cx="60" cy="60" rx="24" ry="8" fill="#29BDCE" fill-opacity="0.10"/>
                      <ellipse cx="340" cy="40" rx="40" ry="40" fill="#29BDCE" fill-opacity="0.08"/>
                      <path d="M80 100 Q100 90 120 100 Q140 110 160 100" stroke="#29BDCE" stroke-width="1.5" fill="none" opacity="0.15"/>
                      <path d="M260 110 Q280 100 300 110 Q320 120 340 110" stroke="#29BDCE" stroke-width="1.5" fill="none" opacity="0.15"/>
                      <circle cx="200" cy="40" r="18" fill="#29BDCE" fill-opacity="0.07"/>
                    </svg>
                    ''', fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          // Background gradient for a modern look
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 41, 189, 206).withOpacity(0.12),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile photo with border and shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              41,
                              189,
                              206,
                            ).withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color.fromARGB(255, 41, 189, 206),
                          width: 2,
                        ),
                      ),
                      child:
                          profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(profilePhotoUrl!),
                            )
                          : const CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 36,
                                color: Color.fromARGB(255, 41, 189, 206),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  (profileEmail != null &&
                                          profileEmail!.trim().isNotEmpty)
                                      ? profileEmail!
                                      : 'john.doe@company.com',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Notification icon with badge
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 6.0,
                                ), // Tambahkan padding top agar badge tidak ketutupan
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.notifications_none,
                                    color: Color.fromARGB(255, 41, 189, 206),
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    // Handle notifications
                                  },
                                ),
                              ),
                              // Example badge, replace with your notification count logic
                              Positioned(
                                right: 6,
                                top:
                                    2, // Geser badge ke bawah agar tidak ketutupan
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    '3',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                          // More menu
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.black54,
                            ),
                            onSelected: (value) {
                              final state = context
                                  .findAncestorStateOfType<
                                    _DashboardScreenState
                                  >();
                              if (state != null) {
                                state._handleMenuSelection(context, value);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Color.fromARGB(255, 41, 189, 206),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(translate('profile')),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'settings',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.settings,
                                      color: Color.fromARGB(255, 41, 189, 206),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(translate('settings')),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'help',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.help_outline,
                                      color: Color.fromARGB(255, 41, 189, 206),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Help & Support'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'debug_clear',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cleaning_services,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Debug State'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'force_checkin',
                                child: Row(
                                  children: [
                                    Icon(Icons.build, color: Colors.blue),
                                    SizedBox(width: 12),
                                    Text('Fix Check-in State'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'debug_security',
                                child: Row(
                                  children: [
                                    Icon(Icons.security, color: Colors.green),
                                    SizedBox(width: 12),
                                    Text('Security Status'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: Color.fromARGB(255, 41, 189, 206),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(translate('logout')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Menu buttons with modern look
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMenuButton(
                      context: context,
                      icon: Icons.access_time,
                      label: translate('attendance'),
                      color: const Color(0xFF29BDCE),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AttendanceScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuButton(
                      context: context,
                      icon: Icons.event_note,
                      label: translate('permit'),
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PermitScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuButton(
                      context: context,
                      icon: Icons.route,
                      label: translate('itinerary'),
                      color: Colors.purple,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ItineraryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuButton(
                      context: context,
                      icon: Icons.assessment,
                      label: translate('reports'),
                      color: const Color(0xFF29BDCE),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuButton(
                      context: context,
                      icon: Icons.apps,
                      label: translate('others'),
                      color: Colors.blue,
                      onTap: () {
                        onShowAllFeatures(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context) {
    print('🔍 Building information card:');
    print('   - isCheckedIn: $isCheckedIn');
    print('   - todayRecord: ${todayRecord != null ? "exists" : "null"}');
    print('   - todayRecord.checkInTime: ${todayRecord?.checkInTime}');
    print('   - todayRecord.checkOutTime: ${todayRecord?.checkOutTime}');
    print('   - todayRecord.storeName: ${todayRecord?.storeName}');
    print('   - todayRecord.isCheckedIn: ${todayRecord?.isCheckedIn}');

    // ✅ Triple check kondisi untuk checkout card
    final shouldShowCheckoutCard =
        todayRecord != null &&
        todayRecord!.checkInTime != null &&
        todayRecord!.checkOutTime == null &&
        todayRecord!.isCheckedIn &&
        isCheckedIn;

    if (shouldShowCheckoutCard) {
      print('✅ All conditions met - Showing CHECK-OUT card');
      return _buildCheckedInCard(context);
    } else {
      print('📋 Conditions not met - Showing CHECK-IN card');
      print('   - Reasons:');
      print('     • todayRecord exists: ${todayRecord != null}');
      print('     • has checkInTime: ${todayRecord?.checkInTime != null}');
      print('     • no checkOutTime: ${todayRecord?.checkOutTime == null}');
      print('     • record.isCheckedIn: ${todayRecord?.isCheckedIn}');
      print('     • state.isCheckedIn: $isCheckedIn');
      return _buildItineraryCard(context);
    }
  }

  Widget _buildItineraryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: Colors.purple, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  () {
                    if (isCheckedIn && todayRecord != null) {
                      return 'Current Store: ${todayRecord!.storeName ?? 'Unknown Store'}';
                    } else if (itineraryCount == 0) {
                      return 'No itinerary today';
                    } else if (itineraryCount == 1) {
                      return 'You have 1 itinerary';
                    } else {
                      return 'You have ${itineraryCount} itineraries';
                    }
                  }(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.cyan),
                onPressed: onReload,
                tooltip: translate('reload'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isCheckedIn ? Icons.access_time : Icons.calendar_today,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(() {
                if (isCheckedIn && todayRecord?.checkInTime != null) {
                  final checkInTime = todayRecord!.checkInTime!;
                  return 'Checked in at ${_formatTime(checkInTime)}';
                } else if (itineraryList != null && itineraryList!.isNotEmpty) {
                  return itineraryList!.first.date;
                } else {
                  return '-';
                }
              }(), style: const TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Check In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 41, 189, 206),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 45),
              ),
              onPressed: onCheckIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedInCard(BuildContext context) {
    final checkInTime = todayRecord!.checkInTime!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with store info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayRecord!.storeName ?? 'Current Store',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Checked in at ${_formatTime(checkInTime)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.cyan),
                onPressed: onReload,
                tooltip: translate('reload'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Working time only
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.work, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Working Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RealtimeTimerWidget(
                      attendanceRecord: todayRecord,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Check-out button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Check Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 45),
              ),
              onPressed: onCheckOut,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('activity'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Use unified timeline widget
        UnifiedTimelineWidget(attendanceRecord: todayRecord),
        const SizedBox(height: 16),
        // Keep old activities as backup/additional info
        if (activities.isNotEmpty) ...[
          Text(
            translate('additionalActivities'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        activities.isEmpty
            ? const SizedBox.shrink()
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(activities.length, (i) {
                    final item = activities[i];
                    return Column(
                      children: [
                        _buildTimelineActivityItem(
                          icon: item['icon'],
                          title: item['title'],
                          subtitle: item['subtitle'],
                          time: item['time'],
                          color: item['color'],
                          isLast: i == activities.length - 1,
                        ),
                      ],
                    );
                  }),
                ),
              ),
      ],
    );
  }

  Widget _buildTimelineActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column with time and line
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 12),
                ),
                if (!isLast) ...[
                  Container(width: 2, height: 20, color: Colors.grey[300]),
                ],
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Activity content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTodayRecordToStorage(AttendanceRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordData = {
        'storeId': record.storeId,
        'storeName': record.storeName,
        'checkInTime': record.checkInTime?.toIso8601String(),
        'checkOutTime': record.checkOutTime?.toIso8601String(),
        'isCheckedIn': record.isCheckedIn,
        'date': record.date.toIso8601String(),
      };

      await prefs.setString('today_attendance_record', jsonEncode(recordData));
      print(
        '💾 Saved today record to local storage: store ${record.storeId}, checkIn=${record.checkInTime}, checkOut=${record.checkOutTime}',
      );
    } catch (e) {
      print('❌ Error saving today record to local storage: $e');
    }
  }
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Itinerary data
  List<Itinerary> itineraries = [];
  List<AttendanceRecord> attendanceRecords = [];
  bool isLoading = false;
  String? errorMessage;

  // User role detection
  String? userRole; // 'SPG' or 'MD'
  int totalTasks = 0; // 10 for SPG, 11 for MD

  // Task types based on role
  List<String> get taskTypes {
    if (userRole == 'SPG') {
      return [
        translate('sales'),
        translate('oosOutOfStock'),
        translate('expiredDate'),
        translate('survey'),
        translate('regularDisplay'),
        translate('pricePrincipal'),
        translate('priceCompetitor'),
        translate('promoTracking'),
        translate('competitorActivity'),
        'Kegiatan Lain-lain',
        translate('attendance'),
      ];
    } else {
      // MD
      return [
        translate('productFocus'),
        translate('oosOutOfStock'),
        translate('expiredDate'),
        translate('display'),
        translate('pricePrincipal'),
        translate('priceCompetitor'),
        translate('promoTracking'),
        translate('competitorActivity'),
        translate('survey'),
        translate('productBelgianBerry'),
        'Kegiatan Lain-lain',
        translate('attendance'),
      ];
    }
  }

  // Selected date for filtering
  DateTime selectedDate = DateTime.now();

  // Todo items with timeline
  List<Map<String, dynamic>> todoItems = [];
  bool showTodoTimeline = false;

  // Progress tracking
  int completedTasks = 0;
  bool isItineraryCompleted = false;
  bool isLoadingReports = false;
  
  // Lazy loading state
  Map<String, bool> _loadingStates = {}; // Key: "storeId_taskName", Value: loading state
  Map<String, bool> _completionStates = {}; // Key: "storeId_taskName", Value: completion state
  Map<String, String?> _completionTimes = {}; // Key: "storeId_taskName", Value: completion time
  
  // Attendance data from API
  Map<String, Map<String, dynamic>> _attendanceData = {}; // Key: "storeId", Value: attendance details
  bool _isLoadingAttendance = false;
  DateTime? _lastAttendanceLoadTime;
  
  // Pagination state
  int _currentPage = 1;
  int _itemsPerPage = 5;

  // Expanded stores state
  Map<String, bool> _expandedStores = {};

  // Timer for real-time duration updates
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadItinerariesForDate(selectedDate);
    _loadAttendanceRecords();
    _loadTodoItems();
    // Refresh todo completion status on init
    _refreshTodoCompletionStatus();

    // Start timer for real-time duration updates
    _startDurationTimer();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  // Start timer for real-time duration updates
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger rebuild and update duration display
        });
      }
    });
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_position') ?? 'SPG';
      setState(() {
        userRole = role.contains('MD') ? 'MD' : 'SPG';
        totalTasks = userRole == 'SPG' ? 10 : 11;
      });
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        userRole = 'SPG';
        totalTasks = 10;
      });
    }
  }

  Future<void> _loadItinerariesForDate(DateTime date) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      print('Loading itineraries for date: $dateStr');
      final response = await ItineraryService.getItineraryByDate(dateStr);

        if (response.success) {
        setState(() {
          itineraries = response.data;
          print('Loaded ${itineraries.length} itineraries');
          _checkItineraryCompletion();
          isLoading = false;
          // Reset pagination when new data is loaded
          _currentPage = 1;
        });
        
        // Load attendance data from API
        await _loadAttendanceData();
        
        // Generate todos after loading itineraries
        await _generateDefaultTodos();
        // Refresh todo completion status to check for completed reports
        await _refreshTodoCompletionStatusOptimized();
        } else {
        setState(() {
          errorMessage = response.message;
          itineraries = [];
        isLoading = false;
      });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load itineraries: ${e.toString()}';
        itineraries = [];
        isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceRecords() async {
    try {
      final response = await AttendanceService().getAllRecords();
      setState(() {
        attendanceRecords = response;
        _checkItineraryCompletion();
      });

      // Debug: Print attendance records
      print('📋 Loaded ${attendanceRecords.length} attendance records');
      for (var record in attendanceRecords) {
        print(
          '📋 Record date: ${record.date}, details: ${record.details.length}',
        );
        for (var detail in record.details) {
          print(
            '📋   Store ${detail.storeId}: checkIn=${detail.checkInTime}, checkOut=${detail.checkOutTime}',
          );
        }
      }

      // Auto-refresh todo completion status
      await _refreshTodoCompletionStatus();
    } catch (e) {
      print('Error loading attendance records: $e');
    }
  }

  Future<void> _refreshTodoCompletionStatus() async {
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    bool hasChanges = false;
    for (int i = 0; i < todoItems.length; i++) {
      final todo = todoItems[i];
      final storeId = todo['storeId'] as int? ?? 0;
      final taskName = todo['task'] as String? ?? '';
      final currentCompleted = todo['completed'] == true;

      // Check if should be auto-completed
      final shouldBeCompleted = await _checkAutoCompletion(
        storeId,
        taskName,
        dateStr,
      );

      if (currentCompleted != shouldBeCompleted) {
        todoItems[i]['completed'] = shouldBeCompleted;
        todoItems[i]['autoCompleted'] = shouldBeCompleted;
        if (shouldBeCompleted) {
          todoItems[i]['completedTime'] = await _getActualCompletionTime(storeId, taskName, dateStr);
          // Log additional activity when task is completed
          await _saveAdditionalActivityLog(
            taskName,
            todo['storeName'] as String? ?? 'Unknown Store',
            storeId,
            'completed',
          );
        }
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _saveTodoItems();
      _updateProgress();
    }
  }

  Future<void> _refreshTodoCompletionStatusOptimized() async {
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    print('🔄 [Lazy Loading] Initializing todo completion status for date: $dateStr');
    
    // Clear previous states
    setState(() {
      _loadingStates.clear();
      _completionStates.clear();
      _completionTimes.clear();
    });
    
    print('ℹ️ [Lazy Loading] Todo items ready for lazy loading. Tap any item to check completion status.');
  }

  void _checkItineraryCompletion() {
    if (itineraries.isEmpty || attendanceRecords.isEmpty) {
      setState(() {
        isItineraryCompleted = false;
      });
      return;
    }

    // Check if all stores in itinerary have attendance records
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final todayAttendance = attendanceRecords.where((record) {
      final recordDate =
          '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      return recordDate == dateStr;
    }).toList();

    // Get all store IDs from itinerary
    final itineraryStoreIds = <int>{};
    for (var itinerary in itineraries) {
      for (var store in itinerary.stores) {
        itineraryStoreIds.add(store.id);
      }
    }

    // Get all store IDs from attendance
    final attendanceStoreIds = <int>{};
    for (var record in todayAttendance) {
      for (var detail in record.details) {
        attendanceStoreIds.add(detail.storeId);
      }
    }

    // Check if all itinerary stores have attendance
    final allStoresVisited = itineraryStoreIds.every(
      (storeId) => attendanceStoreIds.contains(storeId),
    );

    setState(() {
      isItineraryCompleted = allStoresVisited;
    });
  }

  Future<void> _loadTodoItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr =
          '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final todoJson = prefs.getString('todo_items_$dateStr');

      if (todoJson != null) {
        final List<dynamic> todoList = json.decode(todoJson);
        setState(() {
          todoItems = todoList
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _updateProgress();
        });
      } else {
        // Generate default todos if none exist
        await _generateDefaultTodos();
      }
    } catch (e) {
      print('Error loading todo items: $e');
      await _generateDefaultTodos();
    }
  }

  Future<void> _generateDefaultTodos() async {
    if (userRole == null || totalTasks == 0) return;

    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    // Generate todos for each store in itinerary
    List<Map<String, dynamic>> newTodos = [];

    for (var itinerary in itineraries) {
      for (var store in itinerary.stores) {
        print('Generating todos for store: ${store.name} (ID: ${store.id})');
        for (var task in taskTypes) {
          // Check if this task is already completed based on attendance and reports
          final isAutoCompleted = await _checkAutoCompletion(
            store.id,
            task,
            dateStr,
          );

          newTodos.add({
            'id':
                DateTime.now().millisecondsSinceEpoch +
                task.hashCode +
                store.id,
            'task': task,
            'storeName': store.name,
            'storeId': store.id,
            'time': DateTime.now().toIso8601String(),
            'completed': isAutoCompleted,
            'createdAt': DateTime.now().toIso8601String(),
            'date': dateStr,
            'autoCompleted': isAutoCompleted,
            'completedTime': isAutoCompleted
                ? await _getActualCompletionTime(store.id, task, dateStr)
                : null,
          });
        }
      }
    }

    print('Generated ${newTodos.length} todos');
    setState(() {
      todoItems = newTodos;
    });
    _saveTodoItems();
    _updateProgress();
  }

  Future<bool> _checkAutoCompletion(
int storeId,
    String taskName,
    String dateStr,
  ) async {
    // Special handling for Attendance task
    if (taskName == translate('attendance')) {
      return await _checkAttendanceCompletion(storeId, dateStr);
    }

    // Check if specific report has been completed using API
    String reportType = _getReportTypeFromTask(taskName);
    if (reportType.isNotEmpty) {
      try {
        final isReportCompleted = await ReportsApiService.isReportCompleted(
          reportType: reportType,
          date: dateStr,
          storeId: storeId,
        );

        if (isReportCompleted) {
          // Get completion time from API
          final completionTime = await ReportsApiService.getReportCompletionTime(
            reportType: reportType,
            date: dateStr,
            storeId: storeId,
          );

          print(
            '✅ Auto-completion: $taskName completed for store $storeId on $dateStr',
          );
          if (completionTime != null) {
            print('✅ Completion time: $completionTime');
          }
          return true;
        }
      } catch (e) {
        print('❌ Error checking API completion for $taskName: $e');
        // Fallback to local storage check
        final isLocalCompleted = await ReportCompletionService.isReportCompleted(
          storeId: storeId,
          reportType: reportType,
          date: dateStr,
        );
        if (isLocalCompleted) {
          print('✅ Fallback to local completion: $taskName completed for store $storeId on $dateStr');
          return true;
        }
      }
    }

    // For other tasks, check if user has checked in/out at this store
    final hasAttendance = attendanceRecords.any((record) {
      final recordDate =
          '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      if (recordDate != dateStr) return false;

      return record.details.any((detail) => detail.storeId == storeId);
    });

    return hasAttendance;
  }

  Future<bool> _checkAttendanceCompletion(int storeId, String dateStr) async {
    // Check attendance status from API data
    final attendanceStatus = _getAttendanceStatus(storeId);
    if (attendanceStatus != null) {
      final isCheckedIn = attendanceStatus['isCheckedIn'] == true;
      final isCheckedOut = attendanceStatus['isCheckedOut'] == true;
      
      // Consider attendance completed if both check-in and check-out are done
      if (isCheckedIn && isCheckedOut) {
        print('✅ [Attendance API] Store $storeId: Check-in: ${attendanceStatus['checkInTime']}, Check-out: ${attendanceStatus['checkOutTime']} - COMPLETED');
        return true;
      } else if (isCheckedIn && !isCheckedOut) {
        print('🔄 [Attendance API] Store $storeId: Check-in: ${attendanceStatus['checkInTime']}, Check-out: null - IN PROGRESS');
        return false;
      } else {
        print('❌ [Attendance API] Store $storeId: No check-in data - NOT STARTED');
        return false;
      }
    }
    
    // Fallback to local storage if API data not available
    print('⚠️ [Attendance API] No API data for store $storeId, checking local storage...');
    final hasCheckIn = attendanceRecords.any((record) {
      final recordDate =
          '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      return recordDate == dateStr &&
          record.details.any((detail) => detail.storeId == storeId);
    });

    print('📋 [Local Storage] Store $storeId attendance: ${hasCheckIn ? "FOUND" : "NOT FOUND"}');
    return hasCheckIn;
  }

  String _getReportTypeFromTask(String taskName) {
    // Map task names to report types (matching API report types)
    final taskToReportMap = {
      'OOS': 'out_of_stock',
      'OOS (Out of Stock)': 'out_of_stock',
      'Out of Stock': 'out_of_stock',
      'Price Principal': 'price',
      'Price Competitor': 'price_competitor',
      'Promo Tracking': 'promo_tracking',
      'Competitor Activity': 'competitor_activity',
      'Activity Other': 'activity_other',
      'Kegiatan Lain-lain': 'activity_other',
      translate('survey'): 'survey',
      'Product Focus': 'product_focus',
      'Regular Display': 'reguler_display',
      'Reguler Display': 'reguler_display',
      translate('display'): 'display',
      'Product Belgian Berry': 'product_belgian_berry',
      'Expired Date': 'expired_date',
      'Display Check': 'display',
      translate('sales'): 'sales',
      'Customer Feedback': 'customer_feedback',
    };

    return taskToReportMap[taskName] ?? '';
  }

  Future<String?> _getActualCompletionTime(int storeId, String taskName, String dateStr) async {
    try {
      String reportType = _getReportTypeFromTask(taskName);
      if (reportType.isNotEmpty) {
        final completionTime = await ReportsApiService.getReportCompletionTime(
          reportType: reportType,
          date: dateStr,
          storeId: storeId,
        );
        return completionTime;
      }
      return DateTime.now().toIso8601String();
    } catch (e) {
      print('❌ Error getting actual completion time: $e');
      return DateTime.now().toIso8601String();
    }
  }

  Future<void> _saveTodoItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr =
          '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      await prefs.setString('todo_items_$dateStr', json.encode(todoItems));
    } catch (e) {
      print('Error saving todo items: $e');
    }
  }

  // Save additional activity log
  Future<void> _saveAdditionalActivityLog(
    String taskName,
    String storeName,
    int storeId,
    String status,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr =
          '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      // Get existing activity logs
      final existingLogs =
          prefs.getString('additional_activity_logs_$dateStr') ?? '[]';
      final List<dynamic> activityLogs = json.decode(existingLogs);

      // Add new activity log
      final newLog = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'taskName': taskName,
        'storeName': storeName,
        'storeId': storeId,
        'status': status, // 'completed' or 'started'
        'timestamp': DateTime.now().toIso8601String(),
        'date': dateStr,
      };

      activityLogs.add(newLog);

      // Save back to preferences
      await prefs.setString(
        'additional_activity_logs_$dateStr',
        json.encode(activityLogs),
      );

      print(
        '📝 Additional activity logged: $taskName - $status at ${newLog['timestamp']}',
      );
    } catch (e) {
      print('Error saving additional activity log: $e');
    }
  }

  // Get additional activity logs
  Future<List<Map<String, dynamic>>> _getAdditionalActivityLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr =
          '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      final logsData =
          prefs.getString('additional_activity_logs_$dateStr') ?? '[]';
      final List<dynamic> logs = json.decode(logsData);

      return logs.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting additional activity logs: $e');
      return [];
    }
  }

  void _updateProgress() {
    setState(() {
      completedTasks = todoItems
          .where((item) => item['completed'] == true)
          .length;
    });
  }

  void _addTodoItem(String task, String storeName, DateTime time) {
    setState(() {
      todoItems.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'task': task,
        'storeName': storeName,
        'time': time.toIso8601String(),
        'completed': false,
        'createdAt': DateTime.now().toIso8601String(),
        'date':
            '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
      });
    });
    _saveTodoItems();
    _updateProgress();
  }

  void _toggleTodoItem(int id) {
    setState(() {
      final index = todoItems.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        todoItems[index]['completed'] = !todoItems[index]['completed'];
      }
    });
    _saveTodoItems();
    _updateProgress();
  }

  void _deleteTodoItem(int id) {
    setState(() {
      todoItems.removeWhere((item) => item['id'] == id);
    });
    _saveTodoItems();
    _updateProgress();
  }

  Future<void> _clearAllActivities() async {
    setState(() {
      todoItems.clear();
      itineraries.clear();
      completedTasks = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    await prefs.remove('todo_items_$dateStr');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All activities and todos cleared')),
    );
  }

  List<Map<String, dynamic>> getStoreVisits() {
    // Get stores from itinerary API for selected date
    final dateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    // Get attendance records for today to get check-in/check-out times
    final todayAttendance = attendanceRecords.where((record) {
      final recordDate =
          '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      return recordDate == dateStr;
    }).toList();

    // Create a map of visited stores from attendance records
    Map<int, Map<String, dynamic>> visitedStores = {};
    for (var record in todayAttendance) {
      for (var detail in record.details) {
        visitedStores[detail.storeId] = {
          'checkInTime': detail.checkInTime,
          'checkOutTime': detail.checkOutTime,
          'storeName': detail.storeName,
        };
      }
    }

    // Group by store from itinerary API - show ALL stores from itinerary
    Map<String, Map<String, dynamic>> storeVisits = {};

    for (var itinerary in itineraries) {
      for (var store in itinerary.stores) {
        final storeName = store.name;
        final storeId = store.id;

        // Show ALL stores from itinerary, regardless of attendance
        if (!storeVisits.containsKey(storeName)) {
          storeVisits[storeName] = {
            'storeName': storeName,
            'storeId': storeId,
            'totalTasks': 0,
            'completedTasks': 0,
            'checkInTime': visitedStores.containsKey(storeId)
                ? visitedStores[storeId]!['checkInTime']
                : null,
            'checkOutTime': visitedStores.containsKey(storeId)
                ? visitedStores[storeId]!['checkOutTime']
                : null,
            'todos': <Map<String, dynamic>>[],
          };
        }

        // Get todos for this store
        final storeTodos = todoItems
            .where((todo) => (todo['storeName'] as String? ?? '') == storeName)
            .toList();

        storeVisits[storeName]!['totalTasks'] = storeTodos.length;
        storeVisits[storeName]!['completedTasks'] = storeTodos
            .where((todo) => todo['completed'] == true)
            .length;
        storeVisits[storeName]!['todos'] = storeTodos;
      }
    }

    return storeVisits.values.toList();
  }

  String _calculateDuration(TimeOfDay? checkIn, TimeOfDay? checkOut) {
    if (checkIn == null || checkOut == null) return '0 hours 0 minutes';

    final checkInMinutes = checkIn.hour * 60 + checkIn.minute;
    final checkOutMinutes = checkOut.hour * 60 + checkOut.minute;
    final durationMinutes = checkOutMinutes - checkInMinutes;

    if (durationMinutes < 0) return '0 hours 0 minutes';

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    return '$hours hours $minutes minutes';
  }

  // Calculate duration from string times (for local storage data)
  String _calculateDurationFromStrings(
    String? checkInTime,
    String? checkOutTime,
  ) {
    if (checkInTime == null) return '0';

    try {
      DateTime checkIn;
      DateTime checkOut;

      // Parse check-in time
      if (checkInTime.contains('T')) {
        // ISO format: 2025-09-15T10:17:03.112158
        checkIn = DateTime.parse(checkInTime);
      } else if (checkInTime.contains(':')) {
        // Time format: 10:17:03
        final today = DateTime.now();
        final checkInParts = checkInTime.split(':');

        checkIn = DateTime(
          today.year,
          today.month,
          today.day,
          int.parse(checkInParts[0]),
          int.parse(checkInParts[1]),
        );
      } else {
        return '0';
      }

      // If checkOutTime is provided, use it; otherwise use current time (real-time duration)
      if (checkOutTime != null) {
        if (checkOutTime.contains('T')) {
          checkOut = DateTime.parse(checkOutTime);
        } else if (checkOutTime.contains(':')) {
          final today = DateTime.now();
          final checkOutParts = checkOutTime.split(':');

          checkOut = DateTime(
            today.year,
            today.month,
            today.day,
            int.parse(checkOutParts[0]),
            int.parse(checkOutParts[1]),
          );
        } else {
          checkOut = DateTime.now(); // Fallback to current time
        }
      } else {
        // No check-out time, calculate duration from check-in to now (real-time)
        checkOut = DateTime.now();
      }

      final duration = checkOut.difference(checkIn);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    } catch (e) {
      print('Error calculating duration: $e');
      return '0';
    }
  }

  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Selected Date'),
                subtitle: Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() {
                      selectedDate = date;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                await _loadItinerariesForDate(selectedDate);
                _loadAttendanceRecords();
                _loadTodoItems();
                await _refreshTodoCompletionStatusOptimized();
                Navigator.pop(context);
              },
              child: Text(translate('apply')),
            ),
          ],
        ),
      ),
    );
  }

  void _showTodoTimelineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Todo Timeline'),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: todoItems.length,
            itemBuilder: (context, index) {
              final item = todoItems[index];
              final time = DateTime.parse(item['time']);
              final createdAt = DateTime.parse(item['createdAt']);
              final storeId = item['storeId'] as int? ?? 0;
              final taskName = item['task'] as String? ?? '';
              
              // Check lazy loading states
              final needsLoading = !_completionStates.containsKey('${storeId}_$taskName');
              final isLoading = _isTodoLoading(storeId, taskName);
              final isApiCompleted = _isTodoCompleted(storeId, taskName);
              final completionTime = _getTodoCompletionTime(storeId, taskName);
              final finalCompleted = item['completed'] == true || isApiCompleted;

              return ListTile(
                leading: Checkbox(
                  value: finalCompleted,
                  onChanged: (value) => _toggleTodoItem(item['id']),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                  '${item['task']} - ${item['storeName']}',
                  style: TextStyle(
                          decoration: finalCompleted
                        ? TextDecoration.lineThrough
                        : null,
                          color: finalCompleted ? Colors.grey : null,
                        ),
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      )
                    else if (needsLoading)
                      IconButton(
                        icon: Icon(Icons.refresh, size: 16, color: Colors.grey[400]),
                        onPressed: () => _loadTodoCompletionStatus(storeId, taskName),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                  'Created: ${_formatTime(createdAt)} | Due: ${_formatTime(time)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (finalCompleted && completionTime != null)
                      Text(
                        'Selesai pada: ${_formatCompletionTime(completionTime)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTodoItem(item['id']),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translate('close')),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    final months = [
      translate('jan'),
      translate('feb'),
      translate('mar'),
      translate('apr'),
      translate('may'),
      translate('jun'),
      translate('jul'),
      translate('aug'),
      translate('sep'),
      translate('oct'),
      translate('nov'),
      translate('dec'),
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDateFilterDialog,
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () =>
                setState(() => showTodoTimeline = !showTodoTimeline),
            tooltip: 'Todo Timeline',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllActivities,
            tooltip: 'Clear All',
          ),
          IconButton(
            icon: _isLoadingAttendance 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.cyan),
            onPressed: _isLoadingAttendance ? null : () async {
              await _loadItinerariesForDate(selectedDate);
              await _refreshAttendanceData();
              await _refreshTodoCompletionStatus();
            },
            tooltip: _isLoadingAttendance ? 'Refreshing...' : 'Reload',
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with date and store count
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                        color: Color(0xFF29BDCE),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                        '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                    style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF29BDCE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${translate('totalStores')}: ${itineraries.fold(0, (sum, itinerary) => sum + itinerary.stores.length)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Todo Timeline (if enabled)
            if (showTodoTimeline && todoItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list_alt, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          translate('todoTimeline'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.fullscreen),
                          onPressed: _showTodoTimelineDialog,
                          tooltip: translate('viewFullTimeline'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...todoItems
                        .take(3)
                        .map(
                          (item) => _buildLazyTodoItem(item),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Store visits list with pagination
            Expanded(
              child: isLoading || _isLoadingAttendance
                  ? _buildSkeletonLoading()
                  : errorMessage != null
                  ? _buildErrorState(errorMessage!)
                  : getStoreVisits().isEmpty
                  ? _buildEmptyState()
                  : _buildPaginatedStoreList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            translate('noTasksFound'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              translate('noTasksScheduled'),
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginatedStoreList() {
    final allStores = getStoreVisits();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, allStores.length);
    final currentPageStores = allStores.sublist(startIndex, endIndex);
    
    return Column(
      children: [
        // Store list
        Expanded(
          child: ListView.builder(
            itemCount: currentPageStores.length,
            itemBuilder: (context, i) {
              final storeVisit = currentPageStores[i];
              return _buildStoreVisitItem(context, storeVisit, startIndex + i);
            },
          ),
        ),
        
        // Pagination controls
        if (allStores.length > _itemsPerPage)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                ElevatedButton.icon(
                  onPressed: _currentPage > 1 ? _previousPage : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage > 1 ? const Color(0xFF29BDCE) : Colors.grey[300],
                    foregroundColor: _currentPage > 1 ? Colors.white : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                
                // Page info
                Text(
                  'Page $_currentPage of ${(allStores.length / _itemsPerPage).ceil()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Next button
                ElevatedButton.icon(
                  onPressed: _currentPage < (allStores.length / _itemsPerPage).ceil() ? _nextPage : null,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage < (allStores.length / _itemsPerPage).ceil() ? const Color(0xFF29BDCE) : Colors.grey[300],
                    foregroundColor: _currentPage < (allStores.length / _itemsPerPage).ceil() ? Colors.white : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    final totalPages = (getStoreVisits().length / _itemsPerPage).ceil();
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.red[300]),
          const SizedBox(height: 24),
            Text(
            translate('errorLoadingData'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              error,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await _loadItinerariesForDate(selectedDate);
              await _refreshTodoCompletionStatus();
            },
            child: Text(translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreVisitItem(
    BuildContext context,
    Map<String, dynamic> storeVisit,
    int index,
  ) {
    final storeName = storeVisit['storeName'] as String? ?? 'Unknown Store';
    final storeId = storeVisit['storeId'] as int? ?? 0;
    final completedTasks = storeVisit['completedTasks'] as int? ?? 0;
    final totalTasks = storeVisit['totalTasks'] as int? ?? 0;
    final todos = storeVisit['todos'] as List<Map<String, dynamic>>? ?? [];
    
    // Get attendance data from API
    final attendanceStatus = _getAttendanceStatus(storeId);
    final attendanceStatusText = _getAttendanceStatusText(storeId);

    return StatefulBuilder(
      builder: (context, setState) {
        // Use a key to maintain state for each store
        final storeKey = '${storeName}_$index';
        bool isExpanded = _expandedStores[storeKey] ?? false;

        return Container(
      margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main store visit info
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedStores[storeKey] = !isExpanded;
                  });
                  // Also update the main widget state
                  this.setState(() {});
                },
      child: Padding(
        padding: const EdgeInsets.all(16),
                  child: Row(
          children: [
                      // Time
                Container(
                          width: 60,
                          child: Text(
                            attendanceStatus?['checkInTime'] ?? '--:--',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: attendanceStatus?['isCheckedIn'] == true
                                  ? const Color(0xFF29BDCE)
                                  : Colors.grey[400],
                            ),
                          ),
                      ),

                      const SizedBox(width: 12),

                      // Store icon and name
                      Container(
                        width: 40,
                        height: 40,
                  decoration: BoxDecoration(
                          color: const Color(0xFF29BDCE).withOpacity(0.1),
                          shape: BoxShape.circle,
                  ),
                        child: const Icon(
                          Icons.store,
                          color: Color(0xFF29BDCE),
                          size: 20,
                ),
                      ),

                const SizedBox(width: 12),

                      // Store details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                              storeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                              attendanceStatusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: attendanceStatus?['isCheckedIn'] == true
                                    ? const Color(0xFF29BDCE)
                                    : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Progress: ',
                          style: TextStyle(
                            fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '$completedTasks/$totalTasks',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF29BDCE),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: totalTasks > 0
                                  ? completedTasks / totalTasks
                                  : 0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completedTasks == totalTasks
                                    ? Colors.green
                                    : const Color(0xFF29BDCE),
                              ),
                              minHeight: 4,
                            ),
                    ],
                  ),
                ),

                      // Dropdown arrow
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                          ),
                    ],
                  ),
                ),
              ),

              // Expanded task details
              if (isExpanded) ...[
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[200],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      const Text(
                        'Task Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF29BDCE),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTimelineTodos(todos),
                    ],
                  ),
                ),
                      ],
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildTimelineTodos(List<Map<String, dynamic>> todos) {
    return Column(
      children: todos.asMap().entries.map((entry) {
        final index = entry.key;
        final todo = entry.value;
        final isCompleted = todo['completed'] == true;
        final taskName = todo['task'] as String? ?? 'Unknown Task';
        final storeName = todo['storeName'] as String? ?? 'Unknown Store';
        final isLast = index == todos.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                // Timeline dot
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.grey[400],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                // Timeline line
                if (!isLast)
                  Container(width: 2, height: 60, color: Colors.grey[300]),
              ],
            ),

            const SizedBox(width: 16),

            // Task content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.05)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Row(
              children: [
                Expanded(
                          child: Text(
                            taskName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? Colors.green[700]
                                  : Colors.black87,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                    padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DONE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                  ),
                ),
              ],
            ),

                    const SizedBox(height: 8),

                    // Special handling for Attendance task
                    if (taskName == 'Attendance') ...[
                      _buildAttendanceStatus(todo, isCompleted),
                    ] else ...[
                      Text(
                        isCompleted
                            ? translate('taskAutoCompleted')
                            : translate('taskWillAutoComplete'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isCompleted
                              ? Colors.green[600]
                              : Colors.grey[600],
                        ),
                      ),
                    ],

                    if (isCompleted && todo['completedTime'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${translate('completedAt')} ${_formatCompletedTime(todo['completedTime'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    if (!isCompleted) ...[
                      const SizedBox(height: 8),
                      Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                        ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                  ),
                  child: Row(
                    children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[600],
                              size: 16,
                            ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                                'Task akan otomatis completed saat check-in/out di store',
                                style: TextStyle(
                            fontSize: 12,
                                  color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatCompletedTime(String? completedTime) {
    if (completedTime == null) return '';
    try {
      final dateTime = DateTime.parse(completedTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildAttendanceStatus(Map<String, dynamic> todo, bool isCompleted) {
    final storeId = todo['storeId'] as int? ?? 0;
    final dateStr = todo['date'] as String? ?? '';

    print(
      '🔍 _buildAttendanceStatus: storeId=$storeId, dateStr=$dateStr, isCompleted=$isCompleted',
    );

    // Use API data for attendance status
    final attendanceStatus = _getAttendanceStatus(storeId);
    
    if (attendanceStatus == null) {
      return Text(
        'Belum check-in',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final checkInTime = attendanceStatus['checkInTime'] as String?;
    final checkOutTime = attendanceStatus['checkOutTime'] as String?;
    final isCheckedIn = checkInTime != null;
    final isCheckedOut = checkOutTime != null;

    print(
      '🔍 API attendance status: hasCheckIn=$isCheckedIn ($checkInTime), hasCheckOut=$isCheckedOut ($checkOutTime)',
    );

    if (isCheckedIn && isCheckedOut) {
      // Both check-in and check-out exist - show duration
      final duration = _calculateDurationFromAPI(checkInTime, checkOutTime);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            duration,
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.login, size: 16, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(
                'Check-in: ${_formatTimeFromString(checkInTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.green[600]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.logout, size: 16, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(
                'Check-out: ${_formatTimeFromString(checkOutTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.green[600]),
              ),
            ],
          ),
        ],
      );
    } else if (isCheckedIn && !isCheckedOut) {
      // Only check-in exists - show real-time duration from check-in to now
      final duration = _calculateDurationFromAPI(checkInTime, null); // null = use current time

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            duration,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.login, size: 16, color: Colors.orange[600]),
              const SizedBox(width: 4),
              Text(
                'Check-in: ${_formatTimeFromString(checkInTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.orange[600]),
              ),
            ],
          ),
        ],
      );
    } else {
      // No check-in
      return Text(
        'Belum check-in',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _getLocalAttendanceData(
    int storeId,
    String dateStr,
  ) async {
    try {
      // Get today's date string
      final today = DateTime.now();
      final todayStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Only check for today's attendance
      if (dateStr != todayStr) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final todayRecordData = prefs.getString('today_attendance_record');

      if (todayRecordData != null) {
        final data = jsonDecode(todayRecordData);
        final recordStoreId = data['storeId'] as int? ?? 0;

        if (recordStoreId == storeId) {
          return data;
        }
      }

      return null;
    } catch (e) {
      print('🔍 Error getting local attendance data: $e');
      return null;
    }
  }

  String _formatTimeFromString(String timeString) {
    try {
      // Handle different time formats
      if (timeString.contains('T')) {
        // ISO format: 2025-09-15T10:17:03.112158
        final dateTime = DateTime.parse(timeString);
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (timeString.contains(':')) {
        // Time format: 10:17:03
        final parts = timeString.split(':');
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      } else {
        return timeString;
      }
    } catch (e) {
      return timeString;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getPendingTodosForStore(String storeName) {
    return todoItems
        .where(
          (todo) =>
              !(todo['completed'] == true) &&
              (todo['storeName'] as String? ?? '') == storeName,
        )
        .toList();
  }

  String _formatCompletionTime(String? completionTime) {
    if (completionTime == null) return '';
    
    try {
      // Handle different time formats from API
      DateTime dateTime;
      if (completionTime.contains('T')) {
        // ISO format: 2025-09-17T11:30:18.000000Z
        dateTime = DateTime.parse(completionTime);
      } else if (completionTime.contains(' ')) {
        // Format: 2025-09-17 11:30:18
        dateTime = DateTime.parse(completionTime);
      } else {
        // Fallback
        return completionTime;
      }
      
      // Format as "HH:mm" (24-hour format)
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error formatting completion time: $e');
      return completionTime;
    }
  }

  // Lazy loading method for individual todo items
  Future<void> _loadTodoCompletionStatus(int storeId, String taskName) async {
    final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final key = '${storeId}_$taskName';
    
    // Skip if already loading or already checked
    if (_loadingStates[key] == true || _completionStates.containsKey(key)) {
      return;
    }
    
    // Set loading state
    setState(() {
      _loadingStates[key] = true;
    });
    
    try {
      print('🔄 [Lazy Loading] Checking completion for: $taskName at store $storeId');
      
      String reportType = _getReportTypeFromTask(taskName);
      bool isCompleted = false;
      String? completionTime;
      
      if (reportType.isNotEmpty) {
        // Check if report is completed
        isCompleted = await ReportsApiService.isReportCompleted(
          reportType: reportType,
          date: dateStr,
          storeId: storeId,
        );
        
        if (isCompleted) {
          // Get completion time
          completionTime = await ReportsApiService.getReportCompletionTime(
            reportType: reportType,
            date: dateStr,
            storeId: storeId,
          );
        }
      }
      
      // Update states
      setState(() {
        _loadingStates[key] = false;
        _completionStates[key] = isCompleted;
        _completionTimes[key] = completionTime;
      });
      
      print('✅ [Lazy Loading] $taskName at store $storeId: ${isCompleted ? "COMPLETED" : "NOT COMPLETED"}');
      if (isCompleted && completionTime != null) {
        print('✅ [Lazy Loading] Completion time: $completionTime');
      }
      
    } catch (e) {
      print('❌ [Lazy Loading] Error checking $taskName: $e');
      setState(() {
        _loadingStates[key] = false;
        _completionStates[key] = false;
        _completionTimes[key] = null;
      });
    }
  }
  
  // Check if todo item is loading
  bool _isTodoLoading(int storeId, String taskName) {
    final key = '${storeId}_$taskName';
    return _loadingStates[key] == true;
  }
  
  // Check if todo item is completed
  bool _isTodoCompleted(int storeId, String taskName) {
    final key = '${storeId}_$taskName';
    return _completionStates[key] == true;
  }
  
  // Get completion time for todo item
  String? _getTodoCompletionTime(int storeId, String taskName) {
    final key = '${storeId}_$taskName';
    return _completionTimes[key];
  }

  // Load attendance data from API
  Future<void> _loadAttendanceData() async {
    if (_isLoadingAttendance) {
      print('⚠️ [Attendance API] Already loading, skipping...');
      return;
    }
    
    // Debouncing: prevent multiple calls within 2 seconds
    final now = DateTime.now();
    if (_lastAttendanceLoadTime != null && 
        now.difference(_lastAttendanceLoadTime!).inSeconds < 2) {
      print('⚠️ [Attendance API] Debouncing: Too soon since last load, skipping...');
      return;
    }
    
    print('🔄 [Attendance API] Starting to load attendance data...');
    _lastAttendanceLoadTime = now;
    setState(() {
      _isLoadingAttendance = true;
    });
    
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ No token found for attendance API');
        return;
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
      print('URL: ${Env.apiBaseUrl}/attendances/store/check-in');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final attendanceList = data['data'] as List<dynamic>;
          
          // Clear previous data
          _attendanceData.clear();
          
          // Process each attendance record
          for (final attendanceRecord in attendanceList) {
            final details = attendanceRecord['details'] as List<dynamic>? ?? [];
            
            // Process each store detail in the attendance record
            for (final detail in details) {
              final storeId = detail['store_id'] as int? ?? 0;
              final storeName = detail['store_name'] as String? ?? '';
              final checkInTime = detail['check_in_time'] as String?;
              final checkOutTime = detail['check_out_time'] as String?;
              final isApproved = detail['is_approved'] as int? ?? 0;
              
              _attendanceData[storeId.toString()] = {
                'storeId': storeId,
                'storeName': storeName,
                'checkInTime': checkInTime,
                'checkOutTime': checkOutTime,
                'isApproved': isApproved,
                'isCheckedIn': checkInTime != null,
                'isCheckedOut': checkOutTime != null,
              };
              
              print('📊 Store $storeId ($storeName): Check-in: $checkInTime, Check-out: $checkOutTime');
            }
          }
          
          setState(() {});
          print('✅ [Attendance API] Attendance data loaded successfully');
          
          // Update itinerary count based on attendance data
          if (itineraryList != null && itineraryList!.isNotEmpty) {
            final newItineraryCount = _calculateActiveItineraryCount(itineraryList![0].stores);
            if (newItineraryCount != itineraryCount) {
              setState(() {
                itineraryCount = newItineraryCount;
              });
              print('🔄 [Itinerary Count] Updated to $itineraryCount active itineraries');
            }
          }
        } else {
          print('⚠️ [Attendance API] No attendance data found in response');
        }
      } else {
        print('❌ [Attendance API] Failed to load attendance data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Attendance API] Error loading attendance data: $e');
    } finally {
      print('🏁 [Attendance API] Loading completed, resetting loading state');
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  // Get attendance status for a store
  Map<String, dynamic>? _getAttendanceStatus(int storeId) {
    return _attendanceData[storeId.toString()];
  }

  // Refresh attendance data manually
  Future<void> _refreshAttendanceData() async {
    print('🔄 [Manual Refresh] Refreshing attendance data...');
    // Reset debouncing for manual refresh
    _lastAttendanceLoadTime = null;
    await _loadAttendanceData();
  }

  // Calculate duration between check-in and check-out
  String _calculateDurationFromAPI(String? checkInTime, String? checkOutTime) {
    if (checkInTime == null) return 'Belum check-in';
    
    try {
      // Parse check-in time (format: "09:30:36")
      final checkIn = TimeOfDay(
        hour: int.parse(checkInTime.split(':')[0]),
        minute: int.parse(checkInTime.split(':')[1]),
      );
      
      final checkInMinutes = checkIn.hour * 60 + checkIn.minute;
      
      if (checkOutTime == null) {
        // Calculate real-time duration from check-in to now
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final durationMinutes = currentMinutes - checkInMinutes;
        
        if (durationMinutes < 0) {
          return 'Masih di toko';
        }
        
        // Format real-time duration
        if (durationMinutes < 60) {
          return '${durationMinutes}m (live)';
        } else {
          final hours = durationMinutes ~/ 60;
          final minutes = durationMinutes % 60;
          if (minutes == 0) {
            return '${hours}h (live)';
          } else {
            return '${hours}h ${minutes}m (live)';
          }
        }
      } else {
        // Calculate duration between check-in and check-out
        final checkOut = TimeOfDay(
          hour: int.parse(checkOutTime.split(':')[0]),
          minute: int.parse(checkOutTime.split(':')[1]),
        );
        
        final checkOutMinutes = checkOut.hour * 60 + checkOut.minute;
        final durationMinutes = checkOutMinutes - checkInMinutes;
        
        if (durationMinutes < 0) {
          return 'Invalid duration';
        }
        
        // Format duration
        if (durationMinutes < 60) {
          return '${durationMinutes}m';
        } else {
          final hours = durationMinutes ~/ 60;
          final minutes = durationMinutes % 60;
          if (minutes == 0) {
            return '${hours}h';
          } else {
            return '${hours}h ${minutes}m';
          }
        }
      }
    } catch (e) {
      print('Error calculating duration: $e');
      return 'Error';
    }
  }

  // Get attendance status text
  String _getAttendanceStatusText(int storeId) {
    final status = _getAttendanceStatus(storeId);
    if (status == null) {
      print('📋 [Status Text] Store $storeId: No attendance data - Belum check-in');
      return 'Belum check-in';
    }
    
    final isCheckedIn = status['isCheckedIn'] == true;
    final isCheckedOut = status['isCheckedOut'] == true;
    final checkInTime = status['checkInTime'] as String?;
    final checkOutTime = status['checkOutTime'] as String?;
    
    print('📋 [Status Text] Store $storeId: Check-in=$isCheckedIn ($checkInTime), Check-out=$isCheckedOut ($checkOutTime)');
    
    if (!isCheckedIn || checkInTime == null) {
      return 'Belum check-in';
    } else if (isCheckedIn && (!isCheckedOut || checkOutTime == null)) {
      return 'Masih di toko (Check-in: $checkInTime)';
    } else if (isCheckedIn && isCheckedOut && checkOutTime != null) {
      final duration = _calculateDurationFromAPI(checkInTime, checkOutTime);
      return 'Selesai ($duration)';
    }
    
    return 'Unknown status';
  }

  // Skeleton loading widget
  Widget _buildSkeletonLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) => _buildSkeletonCard()),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Time skeleton
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Store info skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress skeleton
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Todo items skeleton
          ...List.generate(2, (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                child: Container(
                    height: 12,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }


  // Build lazy loading todo item widget
  Widget _buildLazyTodoItem(Map<String, dynamic> item) {
    final storeId = item['storeId'] as int? ?? 0;
    final taskName = item['task'] as String? ?? '';
    final storeName = item['storeName'] as String? ?? '';
    final isCompleted = item['completed'] == true;
    
    // Check if we need to load completion status
    final needsLoading = !_completionStates.containsKey('${storeId}_$taskName');
    final isLoading = _isTodoLoading(storeId, taskName);
    final isApiCompleted = _isTodoCompleted(storeId, taskName);
    final completionTime = _getTodoCompletionTime(storeId, taskName);
    
    // Determine final completion state
    final finalCompleted = isCompleted || isApiCompleted;
    
    // Auto-trigger lazy loading for attendance tasks
    if (taskName == 'Attendance' && needsLoading && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTodoCompletionStatus(storeId, taskName);
      });
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          // Trigger lazy loading on tap
          if (needsLoading && !isLoading) {
            _loadTodoCompletionStatus(storeId, taskName);
          }
        },
                  child: Row(
                    children: [
            Checkbox(
              value: finalCompleted,
              onChanged: (value) => _toggleTodoItem(item['id']),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
                      const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$taskName - $storeName',
                          style: TextStyle(
                            fontSize: 12,
                            decoration: finalCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: finalCompleted
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.blue,
                          ),
                        )
                      else if (needsLoading)
                        Icon(
                          Icons.refresh,
                          size: 12,
                          color: Colors.grey[400],
                      ),
                    ],
                  ),
                  if (finalCompleted && completionTime != null)
                    Text(
                      'Selesai pada: ${_formatCompletionTime(completionTime)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
