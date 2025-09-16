import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/permit_service.dart';
import '../../models/permit.dart';

class PermitScreen extends StatefulWidget {
  const PermitScreen({Key? key}) : super(key: key);

  @override
  State<PermitScreen> createState() => _PermitScreenState();
}

class _PermitScreenState extends State<PermitScreen> {
  
  // Form controllers
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPermitTypeId;
  File? _selectedImage;
  
  // Data
  List<Permit> _permits = [];
  List<Permit> _filteredPermits = [];
  List<PermitType> _permitTypes = [];
  bool _isLoading = false;
  bool _isLoadingPermits = false;
  
  // Authentication for getting permits (auto-loaded from login data)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Filter states
  String _selectedFilter = 'pending'; // 'all', 'pending', 'approved', 'rejected' - default to 'pending' (not checked)
  DateTime _selectedMonth = DateTime.now();
  
  
  // Duration field
  String _selectedDuration = 'Full day'; // 'Full day', 'Half day'

  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
    _loadPermitTypes();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load saved user credentials from login data
  Future<void> _loadUserCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get from login data first
      final loginData = prefs.getString('login_data');
      print('🔍 Login data found: ${loginData != null}');
      
      if (loginData != null) {
        final data = json.decode(loginData);
        final email = data['email'] ?? data['username'] ?? '';
        final password = data['password'] ?? '';
        
        print('📧 Email: $email');
        print('🔑 Password: ${password.isNotEmpty ? "***" : "empty"}');
        
        _emailController.text = email;
        _passwordController.text = password;
        
        // Auto-load permits if credentials are available
        if (email.isNotEmpty && password.isNotEmpty) {
          print('✅ Auto-loading permits with credentials');
          _loadPermits();
        } else {
          print('⚠️ Credentials empty, trying to load permits anyway');
          _loadPermits();
        }
      } else {
        // Fallback to old method
        final email = prefs.getString('user_email') ?? '';
        final password = prefs.getString('user_password') ?? '';
        
        print('📧 Fallback email: $email');
        print('🔑 Fallback password: ${password.isNotEmpty ? "***" : "empty"}');
        
        _emailController.text = email;
        _passwordController.text = password;
        
        // Auto-load permits if credentials are available
        if (email.isNotEmpty && password.isNotEmpty) {
          print('✅ Auto-loading permits with fallback credentials');
          _loadPermits();
        } else {
          print('⚠️ Fallback credentials empty, trying to load permits anyway');
          _loadPermits();
        }
      }
    } catch (e) {
      print('❌ Error loading user credentials: $e');
      // Try to load permits anyway
      _loadPermits();
    }
  }

  // Load permit types
  Future<void> _loadPermitTypes() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await PermitService.getPermitTypes();
      if (result['success']) {
        setState(() {
          _permitTypes = (result['data'] as List)
              .map((json) => PermitType.fromJson(json))
              .toList();
        });
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Error loading permit types: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Load permits
  Future<void> _loadPermits() async {
    setState(() => _isLoadingPermits = true);
    
    try {
      // Try to load permits even if credentials are empty (API might work with token only)
      final result = await PermitService.getPermits(
        emailOrUsername: _emailController.text.isNotEmpty ? _emailController.text : 'dummy',
        password: _passwordController.text.isNotEmpty ? _passwordController.text : 'dummy',
        rememberMe: true,
      );
      
      if (result['success']) {
        setState(() {
          _permits = (result['data'] as List)
              .map((json) => Permit.fromJson(json))
              .toList();
          _applyFilters(); // Apply current filters
        });
        print('✅ Loaded ${_permits.length} permits');
      } else {
        print('❌ Failed to load permits: ${result['message']}');
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      print('❌ Error loading permits: $e');
      _showErrorSnackBar('Error loading permits: $e');
    } finally {
      setState(() => _isLoadingPermits = false);
    }
  }


  // Pick image from camera only
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  // Submit permit
  Future<void> _submitPermit() async {
    if (_selectedPermitTypeId == null) {
      _showErrorSnackBar('Please select permit type');
      return;
    }
    
    if (_startDate == null) {
      _showErrorSnackBar('Please select start date');
      return;
    }
    
    if (_endDate == null) {
      _showErrorSnackBar('Please select end date');
      return;
    }
    
    if (_reasonController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter reason');
      return;
    }
    
    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await PermitService.submitPermit(
        permitTypeId: _getPermitTypeId(_selectedPermitTypeId!),
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        reason: _reasonController.text.trim(),
        imageFile: _selectedImage!,
      );

      if (result['success']) {
        _showSuccessSnackBar(result['message']);
        _clearForm();
        _loadPermits(); // Refresh permits list
        // Dialog will close automatically after submit
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Error submitting permit: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Map string permit type to integer ID
  int _getPermitTypeId(String permitType) {
    switch (permitType) {
      case 'sakit': return 1;
      case 'izin': return 2;
      case 'cuti': return 3;
      case 'off': return 4;
      case 'store_closed': return 5;
      case 'izin_khusus': return 6;
      case 'extra_off': return 7;
      default: return 1;
    }
  }

  // Clear form
  void _clearForm() {
    setState(() {
      _selectedPermitTypeId = null;
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
      _selectedImage = null;
      _selectedDuration = 'Full day';
    });
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Apply filters to permits
  void _applyFilters() {
    print('🔍 Applying filters...');
    print('📊 Total permits: ${_permits.length}');
    print('🎯 Selected filter: $_selectedFilter');
    print('📅 Selected month: ${_selectedMonth.year}-${_selectedMonth.month}');
    
    _filteredPermits = _permits.where((permit) {
      // Filter by status
      bool statusMatch = true;
      if (_selectedFilter != 'all') {
        statusMatch = permit.status.toLowerCase() == _selectedFilter;
      }
      
      // Filter by month/year - make it more flexible
      bool dateMatch = true;
      try {
        final permitDate = DateTime.parse(permit.createdAt);
        dateMatch = permitDate.year == _selectedMonth.year && 
                   permitDate.month == _selectedMonth.month;
      } catch (e) {
        print('⚠️ Error parsing date for permit ${permit.id}: $e');
        // If date parsing fails, include the permit anyway
        dateMatch = true;
      }
      
      final matches = statusMatch && dateMatch;
      if (matches) {
        print('✅ Permit ${permit.id} matches filter');
      }
      
      return matches;
    }).toList();
    
    print('📋 Filtered permits: ${_filteredPermits.length}');
  }

  // Get filter counts
  Map<String, int> _getFilterCounts() {
    final counts = <String, int>{
      'all': 0,
      'pending': 0,
      'approved': 0,
      'rejected': 0,
    };
    
    for (final permit in _permits) {
      try {
        final permitDate = DateTime.parse(permit.createdAt);
        final isInSelectedMonth = permitDate.year == _selectedMonth.year && 
                                 permitDate.month == _selectedMonth.month;
        
        if (isInSelectedMonth) {
          counts['all'] = (counts['all'] ?? 0) + 1;
          final status = permit.status.toLowerCase();
          if (counts.containsKey(status)) {
            counts[status] = (counts[status] ?? 0) + 1;
          }
        }
      } catch (e) {
        // Skip invalid dates
      }
    }
    
    return counts;
  }

  // Get count for specific filter
  int _getFilterCount(String filterValue) {
    if (filterValue == 'all') {
      return _permits.where((permit) {
        try {
          final permitDate = DateTime.parse(permit.createdAt);
          return permitDate.year == _selectedMonth.year && 
                 permitDate.month == _selectedMonth.month;
        } catch (e) {
          return false;
        }
      }).length;
    }
    
    return _permits.where((permit) {
      try {
        final permitDate = DateTime.parse(permit.createdAt);
        final isInSelectedMonth = permitDate.year == _selectedMonth.year && 
                                 permitDate.month == _selectedMonth.month;
        return isInSelectedMonth && permit.status.toLowerCase() == filterValue;
      } catch (e) {
        return false;
      }
    }).length;
  }

  // Show month/year picker
  Future<void> _showMonthYearPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Month and Year',
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('permits')),
        backgroundColor: Colors.yellow[800],
        foregroundColor: Colors.white,
      ),
      body: _buildPermitsListTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSubmitPermitDialog();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Show submit permit dialog
  void _showSubmitPermitDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'Submit Permit',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Permit Type
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tipe Izin',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedPermitTypeId,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Tipe Izin',
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'sakit',
                                      child: Text(translate('sick')),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'izin',
                                      child: Text(translate('leave')),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'cuti',
                                      child: Text(translate('vacation')),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'off',
                                      child: Text(translate('off')),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'store_closed',
                                      child: Text(translate('storeClosed')),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'izin_khusus',
                                      child: Text(translate('specialLeave')),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'extra_off',
                                      child: Text(translate('extraOff')),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {
                                      _selectedPermitTypeId = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Duration
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Durasi:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedDuration,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Full day',
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'Full day',
                                      child: Text(translate('fullDay')),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Half day',
                                      child: Text(translate('halfDay')),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {
                                      _selectedDuration = value ?? 'Full day';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Date Range
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal Mulai',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(translate('startDate')),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () async {
                                              final date = await showDatePicker(
                                                context: context,
                                                initialDate: _startDate ?? DateTime.now(),
                                                firstDate: DateTime.now(),
                                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                              );
                                              if (date != null) {
                                                setDialogState(() {
                                                  _startDate = date;
                                                  if (_endDate != null && _endDate!.isBefore(date)) {
                                                    _endDate = null;
                                                  }
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.calendar_today),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _startDate != null
                                                          ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                                          : 'Tanggal Mulai',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(translate('endDate')),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () async {
                                              if (_startDate == null) {
                                                _showErrorSnackBar('Please select start date first');
                                                return;
                                              }
                                              
                                              final date = await showDatePicker(
                                                context: context,
                                                initialDate: _endDate ?? _startDate!,
                                                firstDate: _startDate!,
                                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                              );
                                              if (date != null) {
                                                setDialogState(() {
                                                  _endDate = date;
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.calendar_today),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _endDate != null
                                                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                                          : 'Tanggal Akhir',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Reason
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alasan',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _reasonController,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    hintText: 'Alasan',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Photo
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Foto',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: double.infinity,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _selectedImage != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                                              const SizedBox(height: 8),
                                              Text(translate('takePhoto')),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Submit button
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            await _submitPermit();
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Submit', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Permits list tab
  Widget _buildPermitsListTab() {
    final filterCounts = _getFilterCounts();
    
    return Column(
      children: [
        
        // Filter section with slide view
        if (_permits.isNotEmpty) ...[
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Status Filter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // Date filter
                      InkWell(
                        onTap: _showMonthYearPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM yyyy').format(_selectedMonth),
                                style: const TextStyle(color: Colors.blue, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status filter buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('All', 'all', Colors.blue),
                        const SizedBox(width: 8),
                        _buildFilterButton('Not Checked', 'pending', Colors.orange),
                        const SizedBox(width: 8),
                        _buildFilterButton('Approved', 'approved', Colors.green),
                        const SizedBox(width: 8),
                        _buildFilterButton('Rejected', 'rejected', Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Permits list
        Expanded(
          child: _isLoadingPermits
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _permits.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadPermits,
                      child: ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: Text(
                              'No permits found\nPull down to refresh',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredPermits.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _loadPermits,
                          child: ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(
                                child: Text(
                                  'No permits match the current filter\nPull down to refresh',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPermits,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredPermits.length,
                            itemBuilder: (context, index) {
                              final permit = _filteredPermits[index];
                              return _buildPermitCard(permit);
                            },
                          ),
                        ),
                    ),
      ],
    );
  }

  // Build permit card based on the design
  Widget _buildPermitCard(Permit permit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with permit type and icon
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getPermitTypeColor(permit.permitTypeName),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            permit.permitTypeName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        permit.permitTypeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getPermitTypeColor(permit.permitTypeName),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Duration
                  Text(
                    'Durasi : ${permit.formattedStartDate}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reason section
                  const Text(
                    'Reason',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Reason input field style
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            permit.reason,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (permit.imageUrl != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showImagePopup(permit.imageUrl!),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status message
                  if (permit.status == 'rejected' && permit.approvedBy != null)
                    Text(
                      'Absen di Reject dengan alasan ${permit.approvedBy}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (permit.status == 'approved')
                    Text(
                      'Disetujui oleh ${permit.approvedBy}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      'Menunggu persetujuan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Status ribbon
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: permit.statusColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                permit.statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build filter button
  Widget _buildFilterButton(String label, String value, Color color) {
    final count = _getFilterCount(value);
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Get permit type color
  Color _getPermitTypeColor(String permitType) {
    switch (permitType.toLowerCase()) {
      case 'sakit':
        return Colors.pink;
      case 'izin':
        return Colors.blue;
      case 'cuti':
        return Colors.green;
      case 'off':
        return Colors.orange;
      case 'store closed':
        return Colors.purple;
      case 'competitor':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // Show image popup
  void _showImagePopup(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Background overlay
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Image container
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Permit Image',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    // Image
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
    );
  }

  // Show permit details
  void _showPermitDetails(Permit permit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(permit.permitTypeName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Start Date', permit.formattedStartDate),
              _buildDetailRow('End Date', permit.formattedEndDate),
              _buildDetailRow('Reason', permit.reason),
              _buildDetailRow('Status', permit.statusText),
              if (permit.approvedBy != null)
                _buildDetailRow('Approved By', permit.approvedBy!),
              if (permit.approvedAt != null)
                _buildDetailRow('Approved At', permit.approvedAt!),
              _buildDetailRow('Created At', permit.formattedCreatedAt),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

}
