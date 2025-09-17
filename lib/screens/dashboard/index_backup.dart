import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:stockira/screens/attendance/index.dart';
import 'package:stockira/screens/attendance/CheckIn/maps_checkin_simple.dart';
import 'package:stockira/screens/attendance/CheckOut/maps_checkout_screen.dart';
import 'package:stockira/screens/permit/index.dart';
import 'package:stockira/screens/itinerary/index.dart';
import 'package:stockira/screens/reports/index.dart';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  const DashboardScreen({super.key});

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
      Center(child: Text('Payslip', style: TextStyle(fontSize: 24))),
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
        itineraryCount = response.data[0].stores.length;
        itineraryDate = DateTime.now();
        isLoadingItinerary = false;
      });

      print(
        'Dashboard - Itinerary count loaded: ${response.data[0].stores.length}',
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
              const Text('Profile'),
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
                name ?? 'John Doe',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(profilePosition ?? 'Employee'),
              const SizedBox(height: 4),
              Text(
                profileEmail ?? 'john.doe@company.com',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Employee ID: ${profileEmployeeId ?? 'EMP001'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to edit profile screen
              },
              child: const Text('Edit Profile'),
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
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: theme),
              const SizedBox(width: 8),
              const Text('Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // Handle notification toggle
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // Handle dark mode toggle
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                trailing: const Text('English'),
                onTap: () {
                  // Handle language selection
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('URL Settings'),
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
              child: const Text('Close'),
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
              const Text('Help & Support'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help? We\'re here for you!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.phone,
                title: 'Contact Support',
                subtitle: 'Call us at +1 (555) 123-4567',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                icon: Icons.email,
                title: 'Email Support',
                subtitle: 'support@company.com',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                icon: Icons.chat,
                title: 'Live Chat',
                subtitle: 'Available 24/7',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
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
              const Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('Logout'),
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
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Logging out...'),
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
        const SnackBar(
          content: Text('Successfully logged out'),
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
          content: Text('Logout failed: ${e.toString()}'),
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
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(width: 16),
                  Text('Updating dashboard...'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Use robust reload method
        await _forceReloadData();
        
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
          content: Text('Error during check-in: $e'),
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
          const SnackBar(
            content: Text('You are not currently checked in'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      print('✅ Valid checkout state, showing maps checkout...');
      // Navigate to maps checkout screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => MapsCheckoutScreen(
            currentRecord: todayRecord!,
          ),
        ),
      );
      
      if (result == true) {
        // Checkout successful, reload data
        await _loadTodayRecord();

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
          const SnackBar(content: Text('Successfully checked out')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking out: $e')));
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
          title: const Text('Filter Attendance'),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),

                    // Image capture section
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                const Text('No image selected'),
                                const SizedBox(height: 8),
                                Column(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final image = await picker.pickImage(
                                            source: ImageSource.camera,
                                          );
                                          if (image != null) {
                                            setState(() {
                                              selectedImage = image;
                                            });
                                          }
                                        } catch (e) {
                                          print('Error picking image: $e');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Camera not available: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Take Photo'),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final image = await picker.pickImage(
                                            source: ImageSource.gallery,
                                          );
                                          if (image != null) {
                                            setState(() {
                                              selectedImage = image;
                                            });
                                          }
                                        } catch (e) {
                                          print('Error picking image: $e');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Gallery not available: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text('From Gallery'),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(selectedImage!.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text(
                                          'Failed to load image',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withOpacity(0.9),
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                          onPressed: () async {
                                            try {
                                              final image = await picker
                                                  .pickImage(
                                                    source: ImageSource.camera,
                                                  );
                                              if (image != null) {
                                                setState(() {
                                                  selectedImage = image;
                                                });
                                              }
                                            } catch (e) {
                                              print('Error picking image: $e');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Camera not available: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                          ),
                                          label: const Text('Retake'),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withOpacity(0.9),
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                          onPressed: () async {
                                            try {
                                              final image = await picker
                                                  .pickImage(
                                                    source: ImageSource.gallery,
                                                  );
                                              if (image != null) {
                                                setState(() {
                                                  selectedImage = image;
                                                });
                                              }
                                            } catch (e) {
                                              print('Error picking image: $e');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Gallery not available: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.photo_library,
                                            size: 16,
                                          ),
                                          label: const Text('Gallery'),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withOpacity(0.9),
                                            foregroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              selectedImage = null;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 16,
                                          ),
                                          label: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Note field
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Add any additional notes...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an image first'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.of(
                  context,
                ).pop({'image': selectedImage!, 'note': noteController.text});
              },
              child: const Text('Check Out'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date range picker
              ListTile(
                title: const Text('Start Date'),
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
                title: const Text('End Date'),
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
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'checked_in',
                    child: Text('Checked In'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
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
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
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
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(width: 16),
              Text('Refreshing data...'),
            ],
          ),
          backgroundColor: Color.fromARGB(255, 41, 189, 206),
          duration: Duration(seconds: 2),
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
            child: const Text('Close'),
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
            child: const Text('Cancel'),
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
                    Text('Store: ${record.storeName ?? 'Unknown'}'),
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
            child: const Text('Cancel'),
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
              _mapsService.isSecurelyConfigured ? 'Configured' : 'Missing',
              _mapsService.isSecurelyConfigured ? Colors.green : Colors.red,
            ),
            SizedBox(height: 8),
            _buildSecurityItem(
              'Platform',
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
              'Environment',
              dotenv.env.isNotEmpty ? 'Loaded' : 'Not Loaded',
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
            child: Text('Close'),
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
                                label: 'Attendance',
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
                                label: 'Permit',
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
                                label: 'Itinerary',
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
                                label: 'Reports',
                                color: const Color(0xFF29BDCE),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ReportsScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildFeatureIcon(
                                context: context,
                                icon: Icons.receipt_long,
                                label: 'Payslip',
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
                                label: 'Activity',
                                color: Colors.teal,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _selectedIndex = 2;
                                  });
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
        },
        selectedItemColor: const Color.fromARGB(255, 41, 189, 206),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Payslip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Activity',
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
                              const PopupMenuItem<String>(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Color.fromARGB(255, 41, 189, 206),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Profile'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'settings',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      color: Color.fromARGB(255, 41, 189, 206),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Settings'),
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
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      color: Color.fromARGB(255, 41, 189, 206),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Logout'),
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
                      label: 'Attendance',
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
                      label: 'Permit',
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
                      label: 'Itinerary',
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
                      label: 'Reports',
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
                      label: 'Others',
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
                tooltip: 'Reload',
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
                tooltip: 'Reload',
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
        const Text(
          'Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Use unified timeline widget
        UnifiedTimelineWidget(attendanceRecord: todayRecord),
        const SizedBox(height: 16),
        // Keep old activities as backup/additional info
        if (activities.isNotEmpty) ...[
          const Text(
            'Additional Activities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
  int totalTasks = 0; // 12 for SPG, 10 for MD

  // Task types based on role
  List<String> get taskTypes {
    if (userRole == 'SPG') {
      return [
        'OOS (Out of Stock)',
        'Expired Date',
        'Reguler Display',
        'Price Principal',
        'Price Competitor',
        'Competitor Activity',
        'Promo Tracking',
        'Sales',
        'Survey',
        'Attendance',
        'Display Check',
        'Customer Feedback',
      ];
    } else { // MD
      return [
        'OOS (Out of Stock)',
        'Expired Date',
        'Reguler Display',
        'Price Principal',
        'Price Competitor',
        'Competitor Activity',
        'Promo Tracking',
        'Sales',
        'Survey',
        'Attendance',
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
  
  // Expanded stores state
  Map<String, bool> _expandedStores = {};

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadItinerariesForDate(selectedDate);
    _loadAttendanceRecords();
    _loadTodoItems();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_position') ?? 'SPG';
      setState(() {
        userRole = role.contains('MD') ? 'MD' : 'SPG';
        totalTasks = userRole == 'SPG' ? 12 : 10;
      });
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        userRole = 'SPG';
        totalTasks = 12;
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

      setState(() {
        if (response.success) {
          itineraries = response.data;
          print('Loaded ${itineraries.length} itineraries');
          _checkItineraryCompletion();
          // Generate todos after loading itineraries
          _generateDefaultTodos();
        } else {
          errorMessage = response.message;
          itineraries = [];
        }
        isLoading = false;
      });
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
        // Auto-refresh todo completion status
        _refreshTodoCompletionStatus();
      });
    } catch (e) {
      print('Error loading attendance records: $e');
    }
  }

  void _refreshTodoCompletionStatus() {
    final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    
    bool hasChanges = false;
    for (int i = 0; i < todoItems.length; i++) {
      final todo = todoItems[i];
      final storeId = todo['storeId'] as int? ?? 0;
      final taskName = todo['task'] as String? ?? '';
      final currentCompleted = todo['completed'] == true;
      
      // Check if should be auto-completed
      final shouldBeCompleted = _checkAutoCompletion(storeId, taskName, dateStr);
      
      if (currentCompleted != shouldBeCompleted) {
        todoItems[i]['completed'] = shouldBeCompleted;
        todoItems[i]['autoCompleted'] = shouldBeCompleted;
        if (shouldBeCompleted) {
          todoItems[i]['completedTime'] = DateTime.now().toIso8601String();
        }
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      _saveTodoItems();
      _updateProgress();
    }
  }

  void _checkItineraryCompletion() {
    if (itineraries.isEmpty || attendanceRecords.isEmpty) {
      setState(() {
        isItineraryCompleted = false;
      });
      return;
    }

    // Check if all stores in itinerary have attendance records
    final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    
    final todayAttendance = attendanceRecords.where((record) {
      final recordDate = '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
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
    final allStoresVisited = itineraryStoreIds.every((storeId) => attendanceStoreIds.contains(storeId));
    
    setState(() {
      isItineraryCompleted = allStoresVisited;
    });
  }

  Future<void> _loadTodoItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
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
        _generateDefaultTodos();
      }
    } catch (e) {
      print('Error loading todo items: $e');
      _generateDefaultTodos();
    }
  }

  void _generateDefaultTodos() {
    if (userRole == null || totalTasks == 0) return;
    
    final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    
    // Generate todos for each store in itinerary
    List<Map<String, dynamic>> newTodos = [];
    
    for (var itinerary in itineraries) {
      for (var store in itinerary.stores) {
        print('Generating todos for store: ${store.name} (ID: ${store.id})');
        for (var task in taskTypes) {
          // Check if this task is already completed based on attendance and reports
          final isAutoCompleted = _checkAutoCompletion(store.id, task, dateStr);
          
          newTodos.add({
            'id': DateTime.now().millisecondsSinceEpoch + task.hashCode + store.id,
            'task': task,
            'storeName': store.name,
            'storeId': store.id,
            'time': DateTime.now().toIso8601String(),
            'completed': isAutoCompleted,
            'createdAt': DateTime.now().toIso8601String(),
            'date': dateStr,
            'autoCompleted': isAutoCompleted,
            'completedTime': isAutoCompleted ? DateTime.now().toIso8601String() : null,
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

  bool _checkAutoCompletion(int storeId, String taskName, String dateStr) {
    // Check if user has checked in/out at this store
    final hasAttendance = attendanceRecords.any((record) {
      final recordDate = '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
      if (recordDate != dateStr) return false;
      
      return record.details.any((detail) => detail.storeId == storeId);
    });
    
    // For now, auto-complete based on attendance
    // In real implementation, this would check actual report submissions
    return hasAttendance;
  }

  Future<void> _saveTodoItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      await prefs.setString('todo_items_$dateStr', json.encode(todoItems));
    } catch (e) {
      print('Error saving todo items: $e');
    }
  }

  void _updateProgress() {
    setState(() {
      completedTasks = todoItems.where((item) => item['completed'] == true).length;
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
        'date': '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
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
    final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    await prefs.remove('todo_items_$dateStr');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All activities and todos cleared')),
    );
  }

  List<Map<String, dynamic>> getStoreVisits() {
    // Get stores from itinerary API for selected date
    final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    
    // Get attendance records for today to get check-in/check-out times
    final todayAttendance = attendanceRecords.where((record) {
      final recordDate = '${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
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
            'checkInTime': visitedStores.containsKey(storeId) ? visitedStores[storeId]!['checkInTime'] : null,
            'checkOutTime': visitedStores.containsKey(storeId) ? visitedStores[storeId]!['checkOutTime'] : null,
            'todos': <Map<String, dynamic>>[],
          };
        }
        
        // Get todos for this store
        final storeTodos = todoItems.where((todo) => 
          (todo['storeName'] as String? ?? '') == storeName).toList();
        
        storeVisits[storeName]!['totalTasks'] = storeTodos.length;
        storeVisits[storeName]!['completedTasks'] = storeTodos.where((todo) => todo['completed'] == true).length;
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _loadItinerariesForDate(selectedDate);
                _loadAttendanceRecords();
                _loadTodoItems();
                Navigator.pop(context);
              },
              child: const Text('Apply'),
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

              return ListTile(
                leading: Checkbox(
                  value: item['completed'],
                  onChanged: (value) => _toggleTodoItem(item['id']),
                ),
                title: Text(
                  '${item['task']} - ${item['storeName']}',
                  style: TextStyle(
                    decoration: item['completed']
                        ? TextDecoration.lineThrough
                        : null,
                    color: item['completed'] ? Colors.grey : null,
                  ),
                ),
                subtitle: Text(
                  'Created: ${_formatTime(createdAt)} | Due: ${_formatTime(time)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
            icon: const Icon(Icons.refresh, color: Colors.cyan),
            onPressed: () => _loadItinerariesForDate(selectedDate),
            tooltip: 'Reload',
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
                    '$translate('totalStores') ${itineraries.fold(0, (sum, itinerary) => sum + itinerary.stores.length)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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
                        const Text(
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
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item['completed'],
                                  onChanged: (value) =>
                                      _toggleTodoItem(item['id']),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item['task']} - ${item['storeName']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      decoration: item['completed']
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: item['completed']
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Store visits list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? _buildErrorState(errorMessage!)
                  : getStoreVisits().isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: getStoreVisits().length,
                      itemBuilder: (context, i) {
                        final storeVisit = getStoreVisits()[i];
                        return _buildStoreVisitItem(context, storeVisit, i);
                      },
                    ),
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
          const Text(
            translate('noTasksFound'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
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

  Widget _buildErrorState(String error) {
    return Center(
            child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
              children: [
          Icon(Icons.error_outline, size: 100, color: Colors.red[300]),
          const SizedBox(height: 24),
          const Text(
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
            onPressed: () => _loadItinerariesForDate(selectedDate),
            child: Text(translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreVisitItem(BuildContext context, Map<String, dynamic> storeVisit, int index) {
    final storeName = storeVisit['storeName'] as String? ?? 'Unknown Store';
    final completedTasks = storeVisit['completedTasks'] as int? ?? 0;
    final totalTasks = storeVisit['totalTasks'] as int? ?? 0;
    final checkInTime = storeVisit['checkInTime'] as TimeOfDay?;
    final checkOutTime = storeVisit['checkOutTime'] as TimeOfDay?;
    final todos = storeVisit['todos'] as List<Map<String, dynamic>>? ?? [];
    
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
                          checkInTime != null 
                              ? '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}'
                              : '--:--',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: checkInTime != null ? const Color(0xFF29BDCE) : Colors.grey[400],
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
                              checkInTime != null 
                                  ? _calculateDuration(checkInTime, checkOutTime)
                                  : translate('notCheckedIn'),
                              style: TextStyle(
                                fontSize: 12,
                                color: checkInTime != null ? const Color(0xFF29BDCE) : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  translate('progress') + ': ',
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
                              value: totalTasks > 0 ? completedTasks / totalTasks : 0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completedTasks == totalTasks ? Colors.green : const Color(0xFF29BDCE),
                              ),
                              minHeight: 4,
                            ),
                          ],
                        ),
                      ),
                      
                      // Dropdown arrow
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
                        translate('taskDetails'),
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
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Task content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
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
                              color: isCompleted ? Colors.green[700] : Colors.black87,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              translate('done'),
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
                    
                    Text(
                      isCompleted 
                          ? translate('taskAutoCompleted') 
                          : translate('taskWillAutoComplete'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isCompleted ? Colors.green[600] : Colors.grey[600],
                      ),
                    ),
                    
                    if (isCompleted && todo['completedTime'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        translate('completedAt') + ': ${_formatCompletedTime(todo['completedTime'])}',
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                                translate('taskWillAutoComplete'),
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

  List<Map<String, dynamic>> _getPendingTodosForStore(String storeName) {
    return todoItems
        .where((todo) => !(todo['completed'] == true) && (todo['storeName'] as String? ?? '') == storeName)
        .toList();
  }
}
