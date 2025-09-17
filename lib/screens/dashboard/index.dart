import 'dart:convert';
import 'dart:async';
import '../payslip/index.dart';
import '../activity/index.dart';
import '../../components/bottom_navigation.dart';

import 'package:flutter/material.dart';
import 'package:stockira/screens/attendance/index.dart';
import 'package:stockira/screens/attendance/CheckIn/maps_checkin_simple.dart';
import 'package:stockira/screens/attendance/CheckOut/maps_checkout_screen.dart';
import 'package:stockira/screens/permit/index.dart';
import 'package:stockira/screens/itinerary/index.dart';
import 'package:stockira/screens/reports/index.dart';
import 'package:stockira/screens/Availability/index.dart';
import 'package:stockira/screens/store_mapping/index.dart';
import 'package:stockira/screens/auth/index.dart';
import 'package:stockira/screens/url_setting/index.dart';
import 'package:stockira/services/attendance_service.dart';
import 'package:stockira/services/auth_service.dart';
import 'package:stockira/services/itinerary_service.dart';
import 'package:stockira/services/maps_service.dart';
import 'package:stockira/config/maps_config.dart';
import 'package:stockira/models/attendance_record.dart';
import 'package:stockira/models/itinerary.dart';
import 'package:stockira/widgets/unified_timeline_widget.dart';
import 'package:stockira/widgets/realtime_timer_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/settings_service.dart';
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
      const PayslipScreen(),
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

  // Calculate active itinerary count (all stores from itinerary API)
  int _calculateActiveItineraryCount(List<dynamic> stores) {
    // Simply return the total number of stores from itinerary API
    // No need to match with attendance data for itinerary count
    final totalStores = stores.length;
    print('📊 Total itineraries from API: $totalStores stores');
    return totalStores;
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
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.map,
                                label: 'Store Mapping',
                                color: Colors.indigo,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const StoreMappingScreen(),
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
      bottomNavigationBar: CustomBottomNavigation(
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

}


// ActivityScreen moved to lib/screens/activity/index.dart
