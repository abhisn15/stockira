import 'package:flutter/material.dart';
import 'package:stockira/screens/attandance/index.dart';
import 'package:stockira/screens/permit/index.dart';
import 'package:stockira/screens/itinerary/index.dart';
import 'package:stockira/screens/reports/Survey/index.dart';
import 'package:stockira/screens/auth/index.dart';
import 'package:stockira/screens/url_setting/index.dart';
import 'package:stockira/services/attendance_service.dart';
import 'package:stockira/services/auth_service.dart';
import 'package:stockira/models/attendance_record.dart';

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

  // Dummy itinerary count and date
  int itineraryCount = 1;
  DateTime itineraryDate = DateTime.now();

  // Check-in/check-out state
  bool isCheckedIn = false;
  AttendanceRecord? todayRecord;
  
  // Filter states
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String? filterStatus;

  // New bottom nav: Home, Payslip, Activity
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadTodayRecord();
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
          title: const Row(
            children: [
              Icon(Icons.person, color: Colors.red),
              SizedBox(width: 8, height: 20),
              Text('Profile'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.red,
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'John Doe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Software Developer'),
              const SizedBox(height: 4),
              Text(
                'john.doe@company.com',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Employee ID: EMP001',
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
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.grey),
              SizedBox(width: 8),
              Text('Settings'),
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
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Help & Support'),
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
        Icon(icon, color: Colors.red, size: 20),
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
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout'),
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
                backgroundColor: Colors.red,
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
      // Perform logout using AuthService
      await AuthService.logout();

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
      // Show store selection dialog
      final store = await _showStoreSelectionDialog();
      if (store != null) {
        await _attendanceService.checkIn(store);
        await _loadTodayRecord();
        
        setState(() {
          activities.insert(0, {
            'icon': Icons.login,
            'title': 'Checked In',
            'subtitle': 'Store: $store',
            'time': 'Just now',
            'color': Colors.green,
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully checked in at $store')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking in: $e')),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    try {
      await _attendanceService.checkOut();
      await _loadTodayRecord();
      
      setState(() {
        activities.insert(0, {
          'icon': Icons.logout,
          'title': 'Checked Out',
          'subtitle': 'Working hours: ${todayRecord?.workingHoursFormatted ?? 'N/A'}',
          'time': 'Just now',
          'color': Colors.cyan,
        });
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully checked out')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking out: $e')),
      );
    }
  }

  Future<String?> _showStoreSelectionDialog() async {
    final stores = ['Store 1', 'Store 2', 'Store 3', 'Store 4', 'Store 5'];
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: stores.map((store) => ListTile(
            title: Text(store),
            onTap: () => Navigator.of(context).pop(store),
          )).toList(),
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
                subtitle: Text(filterStartDate?.toString().split(' ')[0] ?? 'Select date'),
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
                subtitle: Text(filterEndDate?.toString().split(' ')[0] ?? 'Select date'),
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
                  DropdownMenuItem(value: 'checked_in', child: Text('Checked In')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
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

  void _handleReload() {
    setState(() {
      // Simulate reload, e.g. refresh itinerary count or activities
      itineraryCount = itineraryCount; // No change, just for demo
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Information reloaded!')));
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
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
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
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                    MaterialPageRoute(builder: (_) => const PermitScreen()),
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
                                    MaterialPageRoute(builder: (_) => const SurveyScreen()),
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
                              // Uncomment if needed:
                              // _buildFeatureIcon(
                              //   context: context,
                              //   icon: Icons.settings,
                              //   label: 'Settings',
                              //   color: Colors.grey,
                              //   onTap: () {
                              //     Navigator.of(context).pop();
                              //     _showSettingsDialog(context);
                              //   },
                              // ),
                              // _buildFeatureIcon(
                              //   context: context,
                              //   icon: Icons.help_outline,
                              //   label: 'Help',
                              //   color: Colors.orange,
                              //   onTap: () {
                              //     Navigator.of(context).pop();
                              //     _showHelpDialog(context);
                              //   },
                              // ),
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
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.red,
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
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color.fromARGB(255, 41, 189, 206),
                backgroundImage: null,
                child: Icon(Icons.person, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'john.doe@company.com',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications, color: Color.fromARGB(255, 41, 189, 206)),
                onPressed: () {
                  // Handle notifications
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                onSelected: (value) {
                  final state = context
                      .findAncestorStateOfType<_DashboardScreenState>();
                  if (state != null) {
                    state._handleMenuSelection(context, value);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.grey),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'help',
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.orange),
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
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    MaterialPageRoute(builder: (_) => const AttendanceScreen()),
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
                    MaterialPageRoute(builder: (_) => const PermitScreen()),
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
                    MaterialPageRoute(builder: (_) => const ItineraryScreen()),
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
                    MaterialPageRoute(builder: (_) => const SurveyScreen()),
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
                  'You have $itineraryCount itinerary',
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
                "${itineraryDate.day.toString().padLeft(2, '0')} "
                "${_monthName(itineraryDate.month)} "
                "${itineraryDate.year}",
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
                        : Color.fromARGB(255, 41, 189, 206),
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

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
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
          // You can use a network image or asset image for a cartoon/illustration
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
