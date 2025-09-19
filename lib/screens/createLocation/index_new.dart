import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'dart:async';
import '../../models/create_location.dart';
import '../../services/create_location_service.dart';
import '../../services/attendance_service.dart';

class CreateLocationScreen extends StatefulWidget {
  const CreateLocationScreen({super.key});

  @override
  State<CreateLocationScreen> createState() => _CreateLocationScreenState();
}

class _CreateLocationScreenState extends State<CreateLocationScreen> {
  // Form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  bool _isCheckingIn = false;
  
  // Data
  List<Area> _areas = [];
  List<SubArea> _subAreas = [];
  List<Account> _accounts = [];
  
  // Selected values
  Area? _selectedArea;
  SubArea? _selectedSubArea;
  Account? _selectedAccount;
  
  // Location
  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentAddress;
  
  // Map
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // Image
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Timer for auto-close warning
  int _remainingTime = 300; // 5 minutes in seconds
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startTimer();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime--;
        });
        
        if (_remainingTime <= 0) {
          timer.cancel();
          Navigator.of(context).pop();
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load areas
      await _loadAreas();
      
      // Load accounts (hardcoded for now, you might want to create an API for this)
      _accounts = [
        Account(id: 1, name: 'ALFAMART'),
        Account(id: 2, name: 'INDOMARET'),
        Account(id: 3, name: 'NAGA'),
        Account(id: 4, name: 'MTI'),
        Account(id: 5, name: 'TIMEZONE'),
        Account(id: 6, name: 'FAMILY MART'),
        Account(id: 7, name: 'CIRCLE K'),
      ];
      
      // Get current location
      await _getCurrentLocation();
    } catch (e) {
      _showSnackBar('Error loading initial data: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAreas() async {
    try {
      final response = await CreateLocationService.getAreas();
      if (response['success']) {
        setState(() {
          _areas = (response['data'] as List)
              .map((area) => Area.fromJson(area))
              .toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load areas');
      }
    } catch (e) {
      print('Error loading areas: $e');
      rethrow;
    }
  }

  Future<void> _loadSubAreas(int areaId) async {
    try {
      final response = await CreateLocationService.getSubAreas(areaId);
      if (response['success']) {
        setState(() {
          _subAreas = (response['data'] as List)
              .map((subArea) => SubArea.fromJson(subArea))
              .toList();
          _selectedSubArea = null; // Reset selected sub area
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load sub areas');
      }
    } catch (e) {
      print('Error loading sub areas: $e');
      rethrow;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _isLoadingLocation = false;
      });
      
      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      
      // Update map markers
      _updateMapMarkers();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showSnackBar('Error getting location: $e', Colors.red);
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _updateMapMarkers() {
    if (_currentLatitude != null && _currentLongitude != null) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(_currentLatitude!, _currentLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(
              title: 'Current Location',
              snippet: 'Your current position',
            ),
          ),
        );
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  Future<void> _submitForm() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Nama toko harus diisi', Colors.red);
      return;
    }
    
    if (_selectedArea == null) {
      _showSnackBar('Area harus dipilih', Colors.red);
      return;
    }
    
    if (_selectedSubArea == null) {
      _showSnackBar('Sub area harus dipilih', Colors.red);
      return;
    }
    
    if (_selectedAccount == null) {
      _showSnackBar('Account harus dipilih', Colors.red);
      return;
    }
    
    if (_currentLatitude == null || _currentLongitude == null) {
      _showSnackBar('Lokasi GPS tidak tersedia', Colors.red);
      return;
    }
    
    if (_addressController.text.trim().isEmpty) {
      _showSnackBar('Alamat harus diisi', Colors.red);
      return;
    }

    if (_selectedImage == null) {
      _showSnackBar('Foto harus diambil untuk check-in', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // First, create location request
      final response = await CreateLocationService.createLocationRequest(
        name: _nameController.text.trim(),
        subAreaId: _selectedSubArea!.id,
        accountId: _selectedAccount!.id,
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        address: _addressController.text.trim(),
        image: _selectedImage,
      );

      if (response['success']) {
        _showSnackBar('Request lokasi berhasil dibuat!', Colors.green);
        
        // After successful location creation, proceed with check-in
        await _performCheckIn();
        
      } else {
        _showSnackBar(response['message'] ?? 'Gagal membuat request lokasi', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _performCheckIn() async {
    setState(() => _isCheckingIn = true);

    try {
      // Convert File to XFile for attendance service
      final xFile = XFile(_selectedImage!.path);
      
      // Calculate distance (simplified - you might want to implement proper distance calculation)
      final distance = 0.0; // For new location, distance is 0
      
      // Perform check-in
      final attendanceService = AttendanceService();
      final attendanceRecord = await attendanceService.checkIn(
        storeId: 0, // New location doesn't have store ID yet
        storeName: _nameController.text.trim(),
        image: xFile,
        note: 'Check-in at new location: ${_addressController.text.trim()}',
        distance: distance,
      );

      _showSnackBar('Check-in berhasil!', Colors.green);
      
      // Reset form and go back
      _resetForm();
      Navigator.of(context).pop();
      
    } catch (e) {
      _showSnackBar('Error during check-in: $e', Colors.red);
    } finally {
      setState(() => _isCheckingIn = false);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _addressController.clear();
    _selectedArea = null;
    _selectedSubArea = null;
    _selectedAccount = null;
    _selectedImage = null;
    _subAreas.clear();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildStatusIndicator(String label, bool isCompleted, IconData icon) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 12,
            color: isCompleted ? Colors.white : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? Colors.green[700] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Location',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map Section
                Expanded(
                  flex: 2,
                  child: _currentLatitude != null && _currentLongitude != null
                      ? GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target: LatLng(_currentLatitude!, _currentLongitude!),
                            zoom: 15.0,
                          ),
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          mapType: MapType.normal,
                          zoomControlsEnabled: true,
                          compassEnabled: true,
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Loading location...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                
                // Form Section
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${DateTime.now().day}, ${_getMonthName(DateTime.now().month)} ${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}.${(_remainingTime % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Warning Message
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aplikasi Akan Tertutup Setelah 5 Menit belum submit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status Indicators
                        Row(
                          children: [
                            _buildStatusIndicator('Jarak', true, Icons.check),
                            const SizedBox(width: 16),
                            _buildStatusIndicator('Foto', _selectedImage != null, _selectedImage != null ? Icons.check : Icons.remove),
                            const SizedBox(width: 16),
                            _buildStatusIndicator('Catatan', false, Icons.remove),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Form Fields
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Location Details Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.store,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _nameController.text.isEmpty ? 'Nama Lokasi' : _nameController.text,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (_selectedArea != null && _selectedSubArea != null && _selectedAccount != null)
                                                  Text(
                                                    'REQ/${_selectedAccount!.name.substring(0, 3).toUpperCase()}/${_selectedArea!.name.substring(0, 3).toUpperCase()}/45231 - ${_selectedArea!.name} - ${_selectedAccount!.name}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              // Add note functionality
                                            },
                                            icon: const Icon(Icons.message, color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _addressController.text.isEmpty ? 'Alamat lokasi' : _addressController.text,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Your Location Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Lokasi Anda:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _currentAddress ?? 'Lokasi belum di atur.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Form Input Fields
                                _buildFormField(
                                  label: 'Nama Lokasi',
                                  icon: Icons.store,
                                  controller: _nameController,
                                  hint: 'Masukkan nama lokasi',
                                ),
                                const SizedBox(height: 12),

                                _buildDropdownField(
                                  label: 'Area',
                                  icon: Icons.location_on,
                                  value: _selectedArea?.name,
                                  onTap: () => _showAreaSelection(),
                                ),
                                const SizedBox(height: 12),

                                _buildDropdownField(
                                  label: 'Tipe Lokasi',
                                  icon: Icons.info,
                                  value: _selectedAccount?.name,
                                  onTap: () => _showAccountSelection(),
                                ),
                                const SizedBox(height: 20),

                                // Check In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting || _isCheckingIn ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isSubmitting || _isCheckingIn
                                        ? const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text('Processing...'),
                                            ],
                                          )
                                        : const Text(
                                            'CHECK IN',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                ),
              ],
            ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: value != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAreaSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Pilih Area',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setModalState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari area...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Areas List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _areas.length,
                    itemBuilder: (context, index) {
                      final area = _areas[index];
                      final isSelected = _selectedArea?.id == area.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            '${area.id} - ${area.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.blue[700] : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.blue[600])
                              : Icon(Icons.add_circle_outline, color: Colors.grey[400]),
                          onTap: () {
                            setModalState(() {
                              _selectedArea = area;
                              _selectedSubArea = null;
                              _subAreas.clear();
                            });
                            _loadSubAreas(area.id);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Tipe Lokasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Accounts List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      final isSelected = _selectedAccount?.id == account.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            account.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.blue[700] : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.blue[600])
                              : Icon(Icons.add_circle_outline, color: Colors.grey[400]),
                          onTap: () {
                            setModalState(() {
                              _selectedAccount = account;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
