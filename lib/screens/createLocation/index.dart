import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/create_location.dart';
import '../../services/create_location_service.dart';

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
  Set<Marker> _markers = {};
  
  

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
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
      });
      
      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      
      // Update map markers
      _updateMapMarkers();
    } catch (e) {
      _showSnackBar('Error getting location: $e', Colors.red);
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Simplified address - you can implement proper geocoding here
      setState(() {
        _currentAddress = 'Lat: $latitude, Lng: $longitude';
      });
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



  Future<void> _submitForm() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Nama lokasi harus diisi', Colors.red);
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
      _showSnackBar('Tipe lokasi harus dipilih', Colors.red);
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

    setState(() => _isSubmitting = true);

    try {
      // Create location request
      final response = await CreateLocationService.createLocationRequest(
        name: _nameController.text.trim(),
        subAreaId: _selectedSubArea!.id,
        accountId: _selectedAccount!.id,
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        address: _addressController.text.trim(),
        image: null,
      );

      if (response['success']) {
        _showSnackBar('Lokasi berhasil dibuat!', Colors.green);
        
        // Reset form and go back
        _resetForm();
        Navigator.of(context).pop();
        
      } else {
        _showSnackBar(response['message'] ?? 'Gagal membuat lokasi', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }


  void _resetForm() {
    _nameController.clear();
    _addressController.clear();
    _selectedArea = null;
    _selectedSubArea = null;
    _selectedAccount = null;
    _subAreas.clear();
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
          'Buat Lokasi Baru',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.red[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[600]!, Colors.red[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[50]!, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Memuat data...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Map Section
                Expanded(
                  flex: 2,
                  child: _currentLatitude != null && _currentLongitude != null
                      ? GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            // Map controller initialized
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
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[100]!, Colors.grey[200]!],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 0,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 16),
                                      Icon(
                                        Icons.location_searching, 
                                        size: 48, 
                                        color: Colors.red[600]
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Mendeteksi lokasi...',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mohon tunggu sebentar',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Form Fields
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Current Location Info
                                if (_currentAddress != null)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.green[50]!, Colors.green[100]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green[200]!, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.1),
                                          spreadRadius: 0,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green[500],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.my_location,
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
                                                'Lokasi Terdeteksi',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green[800],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _currentAddress!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green[700],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green[600],
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_currentAddress != null) const SizedBox(height: 20),

                                // Form Input Fields
                                _buildFormField(
                                  label: 'Nama Lokasi',
                                  icon: Icons.store,
                                  controller: _nameController,
                                  hint: 'Masukkan nama lokasi',
                                ),
                                const SizedBox(height: 20),

                                _buildDropdownField(
                                  label: 'Area',
                                  icon: Icons.location_on,
                                  value: _selectedArea?.name,
                                  onTap: () => _showAreaSelection(),
                                ),
                                const SizedBox(height: 20),

                                _buildDropdownField(
                                  label: 'Sub Area',
                                  icon: Icons.location_city,
                                  value: _selectedSubArea?.name,
                                  onTap: _selectedArea == null ? null : () => _showSubAreaSelection(),
                                ),
                                const SizedBox(height: 20),

                                _buildDropdownField(
                                  label: 'Tipe Lokasi',
                                  icon: Icons.info,
                                  value: _selectedAccount?.name,
                                  onTap: () => _showAccountSelection(),
                                ),
                                const SizedBox(height: 20),

                                _buildFormField(
                                  label: 'Alamat',
                                  icon: Icons.home,
                                  controller: _addressController,
                                  hint: 'Masukkan alamat lengkap lokasi',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 30),

                                // Create Location Button
                                Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isSubmitting 
                                          ? [Colors.grey[400]!, Colors.grey[500]!]
                                          : [Colors.red[600]!, Colors.red[500]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: _isSubmitting ? null : [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        spreadRadius: 0,
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Text(
                                                'Membuat lokasi...',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.add_location_alt,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                'BUAT LOKASI',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
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
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red[600], size: 20),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled 
                ? (value != null ? Colors.red[300]! : Colors.grey[200]!)
                : Colors.grey[200]!, 
            width: 1.5
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled 
                    ? (value != null ? Colors.red[50] : Colors.grey[50])
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon, 
                color: isEnabled 
                    ? (value != null ? Colors.red[600] : Colors.grey[600])
                    : Colors.grey[400],
                size: 20
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Pilih $label',
                    style: TextStyle(
                      fontSize: 16,
                      color: isEnabled 
                          ? (value != null ? Colors.black87 : Colors.grey[600])
                          : Colors.grey[400],
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down, 
              color: isEnabled 
                  ? (value != null ? Colors.red[600] : Colors.grey[400])
                  : Colors.grey[400],
              size: 24,
            ),
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[600]!, Colors.red[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Pilih Area',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setModalState(() {});
                    },
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari area...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.search,
                          color: Colors.red[600],
                          size: 20,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),

                // Areas List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _areas.length,
                    itemBuilder: (context, index) {
                      final area = _areas[index];
                      final isSelected = _selectedArea?.id == area.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red[50] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.red[300]! : Colors.grey[200]!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red[100] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: isSelected ? Colors.red[600] : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '${area.id} - ${area.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isSelected ? Colors.red[700] : Colors.black87,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red[500] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              isSelected ? Icons.check : Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          onTap: () {
                            setModalState(() {
                              _selectedArea = area;
                              _selectedSubArea = null;
                              _subAreas.clear();
                            });
                            _loadSubAreas(area.id);
                            setState(() {
                              _selectedArea = area;
                              _selectedSubArea = null;
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

  void _showSubAreaSelection() {
    if (_selectedArea == null) return;
    
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
                    color: Colors.red,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Pilih Sub Area',
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

                // Sub Areas List
                Expanded(
                  child: _subAreas.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Tidak ada sub area tersedia',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _subAreas.length,
                          itemBuilder: (context, index) {
                            final subArea = _subAreas[index];
                            final isSelected = _selectedSubArea?.id == subArea.id;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.red[50] : Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.red : Colors.grey[300]!,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  '${subArea.id} - ${subArea.name}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.red[700] : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  'Area: ${subArea.area.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: Colors.red[600])
                                    : Icon(Icons.add_circle_outline, color: Colors.grey[400]),
                                onTap: () {
                                  setModalState(() {
                                    _selectedSubArea = subArea;
                                  });
                                  setState(() {
                                    _selectedSubArea = subArea;
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[600]!, Colors.red[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tipe Lokasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),

                // Accounts List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      final isSelected = _selectedAccount?.id == account.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red[50] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.red[300]! : Colors.grey[200]!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red[100] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info,
                              color: isSelected ? Colors.red[600] : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          title: Text(
                            account.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isSelected ? Colors.red[700] : Colors.black87,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red[500] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              isSelected ? Icons.check : Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          onTap: () {
                            setModalState(() {
                              _selectedAccount = account;
                            });
                            setState(() {
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

