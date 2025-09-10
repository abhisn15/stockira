import 'package:flutter/material.dart';
import 'package:stockira/screens/attandance/index.dart';
import 'package:stockira/screens/permit/index.dart';
import 'package:stockira/screens/itinerary/index.dart';
import 'package:stockira/screens/reports/Survey/index.dart';
import 'package:stockira/screens/auth/index.dart';
import 'package:stockira/screens/url_setting/index.dart';
import 'package:stockira/services/attendance_service.dart';
import 'package:stockira/services/auth_service.dart';
import 'package:stockira/services/itinerary_service.dart';
import 'package:stockira/models/attendance_record.dart';
import 'package:stockira/models/itinerary.dart';
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

  int _selectedIndex = 0;

  // Dummy activities for demonstration
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
        activities: activities,
        onShowAllFeatures: _showAllFeaturesBottomSheet,
        onShowFilters: _showFiltersDialog,
        name: name,
        profileEmail: profileEmail,
        profilePhotoUrl: profilePhotoUrl,
        itineraryList: itineraryList,
      ),
      Center(child: Text('Payslip', style: TextStyle(fontSize: 24))),
      ActivityScreen(activities: activities, onReload: _handleReload),
    ];
  }

  Future<void> _loadTodayRecord() async {
    final record = await _attendanceService.getTodayRecord();
    setState(() {
      todayRecord = record;
      isCheckedIn = record?.isCheckedIn ?? false;
    });
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
      print('API Response Data Length: ${response.data.length}');
      print('API Response Data: ${response.data}');
      print('=======================');

      setState(() {
        itineraryList = response.data;
        itineraryCount = response.data.length;
        itineraryDate = DateTime.now();
        isLoadingItinerary = false;
      });

      print('Dashboard - Itinerary count loaded: ${response.data.length}');
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
      // Show store selection dialog with itinerary data
      final storeData = await _showStoreSelectionDialog();
      if (storeData != null) {
        // Show check-in form with image capture and note
        final result = await _showCheckInForm(storeData);
        if (result != null) {
          await _attendanceService.checkIn(
            storeId: result['storeId'],
            storeName: result['storeName'],
            image: result['image'],
            note: result['note'],
          );
          await _loadTodayRecord();

          setState(() {
            activities.insert(0, {
              'icon': Icons.login,
              'title': 'Checked In',
              'subtitle': 'Store: ${result['storeName']}',
              'time': 'Just now',
              'color': Colors.green,
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully checked in at ${result['storeName']}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking in: $e')));
    }
  }

  Future<void> _handleCheckOut() async {
    try {
      // Show check-out form with image capture and note
      final result = await _showCheckOutForm();
      if (result != null) {
        await _attendanceService.checkOut(
          image: result['image'],
          note: result['note'],
        );
        await _loadTodayRecord();

        setState(() {
          activities.insert(0, {
            'icon': Icons.logout,
            'title': 'Checked Out',
            'subtitle':
                'Working hours: ${todayRecord?.workingHoursFormatted ?? 'N/A'}',
            'time': 'Just now',
            'color': Colors.cyan,
          });
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Successfully checked out')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking out: $e')));
    }
  }

  Future<Map<String, dynamic>?> _showStoreSelectionDialog() async {
    // Get stores from itinerary data
    final stores = <Map<String, dynamic>>[];

    if (itineraryList != null && itineraryList!.isNotEmpty) {
      for (var itinerary in itineraryList!) {
        for (var store in itinerary.stores) {
          stores.add({
            'id': store.id,
            'name': store.name,
            'code': store.code,
            'address': store.address,
          });
        }
      }
    }

    // If no itinerary stores, show default stores
    if (stores.isEmpty) {
      stores.addAll([
        {
          'id': 1,
          'name': 'Store 1',
          'code': 'ST001',
          'address': 'Default Store 1',
        },
        {
          'id': 2,
          'name': 'Store 2',
          'code': 'ST002',
          'address': 'Default Store 2',
        },
        {
          'id': 3,
          'name': 'Store 3',
          'code': 'ST003',
          'address': 'Default Store 3',
        },
      ]);
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Store'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return ListTile(
                title: Text(store['name']),
                subtitle: Text('${store['code']} - ${store['address']}'),
                onTap: () => Navigator.of(context).pop(store),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showCheckInForm(
    Map<String, dynamic> storeData,
  ) async {
    final ImagePicker picker = ImagePicker();
    XFile? selectedImage;
    final TextEditingController noteController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Check In'),
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
                    Text('Store: ${storeData['name']}'),
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

                Navigator.of(context).pop({
                  'storeId': storeData['id'],
                  'storeName': storeData['name'],
                  'image': selectedImage!,
                  'note': noteController.text,
                });
              },
              child: const Text('Check In'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showCheckOutForm() async {
    final ImagePicker picker = ImagePicker();
    XFile? selectedImage;
    final TextEditingController noteController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Check Out'),
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
    // Reload itinerary count and other data
    await _loadItineraryCount();
    await _loadTodayRecord();
    await _loadProfile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Information reloaded! Found $itineraryCount itinerary${itineraryCount != 1 ? 's' : ''}',
          ),
          backgroundColor: const Color.fromARGB(255, 41, 189, 206),
        ),
      );
    }
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
                                color: Colors.red,
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
                                color: Colors.green,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SurveyScreen(),
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
    // Rebuild DashboardHome with latest profile data
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
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      color: Colors.red,
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
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SurveyScreen(),
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
                    if (itineraryCount == 0) {
                      return 'No itinerary today';
                    } else if (itineraryCount == 1) {
                      return 'You have 1 itinerary';
                    } else {
                      print(
                        'UI Debug - Displaying: You have ${itineraryCount} itineraries',
                      );
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
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                itineraryList != null && itineraryList!.isNotEmpty
                    ? itineraryList!.first.date
                    : '-',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckedIn
                        ? Colors.grey[300]
                        : const Color.fromARGB(255, 41, 189, 206),
                    foregroundColor: isCheckedIn
                        ? Colors.black54
                        : Colors.white,
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: isCheckedIn ? null : onCheckIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Check Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckedIn
                        ? Colors.red
                        : Colors.grey[300],
                    foregroundColor: isCheckedIn
                        ? Colors.white
                        : Colors.black54,
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: isCheckedIn ? onCheckOut : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        activities.isEmpty
            ? _buildEmptyActivity(context)
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
                        _buildActivityItem(
                          icon: item['icon'],
                          title: item['title'],
                          subtitle: item['subtitle'],
                          time: item['time'],
                          color: item['color'],
                        ),
                        if (i != activities.length - 1)
                          const Divider(height: 1),
                      ],
                    );
                  }),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyActivity(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
        children: [
          Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No activities yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You haven't performed any activities today. Your check-in, check-out, and other actions will appear here.",
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class ActivityScreen extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final VoidCallback onReload;

  const ActivityScreen({
    super.key,
    required this.activities,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyan),
            onPressed: onReload,
            tooltip: 'Reload',
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: activities.isEmpty
            ? _buildEmptyActivity(context)
            : ListView.separated(
                itemCount: activities.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = activities[i];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(item['icon'], color: item['color'], size: 20),
                    ),
                    title: Text(
                      item['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      item['subtitle'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      item['time'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyActivity(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            "No activities yet",
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
              "You haven't performed any activities yet. Your check-in, check-out, and other actions will be shown here.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
