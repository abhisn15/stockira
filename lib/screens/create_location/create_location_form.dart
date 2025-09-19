import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/create_location_service.dart';
import '../../services/store_mapping_service.dart';
import '../../models/store_mapping.dart';

class CreateLocationFormScreen extends StatefulWidget {
  const CreateLocationFormScreen({super.key});

  @override
  State<CreateLocationFormScreen> createState() => _CreateLocationFormScreenState();
}

class _CreateLocationFormScreenState extends State<CreateLocationFormScreen> {
  // Form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Location data
  double? _currentLatitude;
  double? _currentLongitude;
  
  // Dropdown data
  List<Area> _areas = [];
  List<SubArea> _subAreas = [];
  List<Account> _accounts = [];
  
  // Selected values
  Area? _selectedArea;
  SubArea? _selectedSubArea;
  Account? _selectedAccount;
  
  // Loading states
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Map controller
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      });

      // Add marker for current location
      _updateMarkers();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load areas and accounts
      final areasResponse = await StoreMappingService.getAreas();
      final accountsResponse = await StoreMappingService.getAccounts();

      setState(() {
        _areas = areasResponse.data;
        _accounts = accountsResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubAreas(int areaId) async {
    try {
      final subAreasResponse = await StoreMappingService.getSubAreas(areaId);
      setState(() {
        _subAreas = subAreasResponse.data;
        _selectedSubArea = null;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    if (_currentLatitude != null && _currentLongitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentLatitude!, _currentLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Lokasi Saat Ini',
            snippet: 'Posisi yang akan digunakan untuk store',
          ),
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await CreateLocationService.createLocationRequest(
        name: _nameController.text.trim(),
        subAreaId: _selectedSubArea?.id ?? _selectedArea!.id,
        accountId: _selectedAccount!.id,
        address: _addressController.text.trim(),
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membuat lokasi. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lokasi harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Area harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tipe lokasi harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_currentLatitude == null || _currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi GPS tidak tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
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
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map Section
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _currentLatitude != null && _currentLongitude != null
                          ? GoogleMap(
                              onMapCreated: (GoogleMapController controller) {
                                // Map controller created
                              },
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_currentLatitude!, _currentLongitude!),
                                zoom: 15.0,
                              ),
                              markers: _markers,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapType: MapType.normal,
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_off, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Loading location...',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Form Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add_location_alt,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Informasi Lokasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Form Fields
                        _buildFormField(
                          label: 'Nama Lokasi',
                          icon: Icons.store,
                          controller: _nameController,
                          hint: 'Masukkan nama lokasi',
                        ),
                        const SizedBox(height: 16),
                        
                        _buildDropdownField(
                          label: 'Area',
                          icon: Icons.location_on,
                          value: _selectedArea?.name,
                          onTap: () => _showAreaSelection(),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildDropdownField(
                          label: 'Sub Area',
                          icon: Icons.location_city,
                          value: _selectedSubArea?.name,
                          onTap: _selectedArea == null ? null : () => _showSubAreaSelection(),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildDropdownField(
                          label: 'Tipe Lokasi',
                          icon: Icons.info,
                          value: _selectedAccount?.name,
                          onTap: () => _showAccountSelection(),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildFormField(
                          label: 'Alamat',
                          icon: Icons.home,
                          controller: _addressController,
                          hint: 'Masukkan alamat lengkap lokasi',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
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
                                      Text('Membuat lokasi...'),
                                    ],
                                  )
                                : const Text(
                                    'BUAT LOKASI',
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
                ],
              ),
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
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? Colors.grey[300]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isEnabled ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: isEnabled 
                      ? (value != null ? Colors.black : Colors.grey[600])
                      : Colors.grey[400],
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down, 
              color: isEnabled ? Colors.grey : Colors.grey[400],
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Pilih Area',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _areas.length,
                itemBuilder: (context, index) {
                  final area = _areas[index];
                  return ListTile(
                    title: Text('${area.id} - ${area.name}'),
                    onTap: () {
                      setState(() {
                        _selectedArea = area;
                        _selectedSubArea = null;
                        _subAreas.clear();
                      });
                      _loadSubAreas(area.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Pilih Sub Area',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _subAreas.length,
                itemBuilder: (context, index) {
                  final subArea = _subAreas[index];
                  return ListTile(
                    title: Text('${subArea.id} - ${subArea.name}'),
                    onTap: () {
                      setState(() {
                        _selectedSubArea = subArea;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Pilih Tipe Lokasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  return ListTile(
                    title: Text(account.name),
                    onTap: () {
                      setState(() {
                        _selectedAccount = account;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
