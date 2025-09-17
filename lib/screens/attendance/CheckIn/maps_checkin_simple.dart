import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/itinerary.dart';
import '../../../services/attendance_service.dart';
import '../../../services/maps_service.dart';
import '../../../services/auth_service.dart';
import '../../../config/env.dart';

class MapsCheckinSimpleScreen extends StatefulWidget {
  final List<Itinerary> itineraryList;

  const MapsCheckinSimpleScreen({
    super.key,
    required this.itineraryList,
  });

  @override
  State<MapsCheckinSimpleScreen> createState() => _MapsCheckinSimpleScreenState();
}

class _MapsCheckinSimpleScreenState extends State<MapsCheckinSimpleScreen> {
  Position? _currentPosition;
  Store? _selectedStore;
  XFile? _selectedImage;
  String _note = '';
  bool _isLoading = true;
  bool _isCheckingIn = false; // New state for check-in process
  bool _showStoreSelection = true;
  final TextEditingController _noteController = TextEditingController();
  final AttendanceService _attendanceService = AttendanceService();
  final MapsService _mapsService = MapsService();
  
  Set<Marker> _markers = {};
  
  // Store attendance data
  Set<int> _checkedInStoreIds = {};
  bool _isLoadingAttendance = false;

  // Validation
  bool get _isDistanceValid => _selectedStore != null && _currentPosition != null && _getDistanceToStore() <= 100;

  @override
  void initState() {
    super.initState();
    
    // Load attendance data to filter already checked-in stores
    _loadAttendanceData();
    
    // Initialize maps safely
    try {
      _mapsService.debugSecurity();
    } catch (e) {
      print('❌ Maps service error: $e');
    }
    
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Getting location...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('✅ Got location: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Location error: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Use default location
          _currentPosition = Position(
            latitude: -6.200000,
            longitude: 106.816666,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        });
      }
    }
  }

  void _updateMarkers() {
    if (!mounted || _currentPosition == null) return;
    
    try {
      final markers = <Marker>{};
      
      // Current position marker
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      
      // Store marker if selected
      if (_selectedStore != null) {
        markers.add(
          Marker(
            markerId: MarkerId('store_${_selectedStore!.id}'),
            position: LatLng(
              double.parse(_selectedStore!.latitude ?? '0'),
              double.parse(_selectedStore!.longitude ?? '0'),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
      
      setState(() {
        _markers = markers;
      });
    } catch (e) {
      print('❌ Marker error: $e');
    }
  }

  double _getDistanceToStore() {
    if (_currentPosition == null || _selectedStore == null) return double.infinity;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      double.parse(_selectedStore!.latitude ?? '0'),
      double.parse(_selectedStore!.longitude ?? '0'),
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  void _selectStore(Store store) {
    print('🏪 Store selected: ${store.name}');
    
    if (mounted) {
      setState(() {
        _selectedStore = store;
        _showStoreSelection = false;
      });
      _updateMarkers();
    }
  }

  // Load attendance data to get checked-in store IDs
  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ [Check-in] No auth token available');
        return;
      }

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/attendances/store/check-in'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [Check-in] Attendance API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> attendanceList = responseData['data'];
          
          // Clear previous data
          _checkedInStoreIds.clear();
          
          // Process attendance data to get checked-in store IDs
          for (var attendance in attendanceList) {
            final List<dynamic> details = attendance['details'] ?? [];
            
            for (var detail in details) {
              final storeId = detail['store_id'] as int?;
              if (storeId != null) {
                _checkedInStoreIds.add(storeId);
                print('✅ [Check-in] Store $storeId already checked-in');
              }
            }
          }
          
          print('📊 [Check-in] Found ${_checkedInStoreIds.length} already checked-in stores');
          
          // Update UI
          setState(() {});
        } else {
          print('❌ [Check-in] Invalid attendance response format');
        }
      } else {
        print('❌ [Check-in] Failed to load attendance data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Check-in] Error loading attendance data: $e');
    } finally {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  List<Store> _getAllStores() {
    final stores = <Store>[];
    for (var itinerary in widget.itineraryList) {
      stores.addAll(itinerary.stores);
    }
    return stores;
  }

  // Get available stores (excluding already checked-in stores)
  List<Store> _getAvailableStores() {
    final allStores = _getAllStores();
    final availableStores = allStores.where((store) => !_checkedInStoreIds.contains(store.id)).toList();
    
    print('📊 [Check-in] Available stores: ${availableStores.length}/${allStores.length}');
    return availableStores;
  }

  Future<void> _performSimpleCheckIn() async {
    // Prevent multiple check-in attempts
    if (_isCheckingIn) {
      return;
    }

    if (!_isDistanceValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please move closer to the store'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingIn = true;
    });

    try {
      // Show loading dialog
      final screenSize = MediaQuery.of(context).size;
      final isSmallScreen = screenSize.width < 360;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Checking in...',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  'Please wait, do not close the app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await _attendanceService.checkIn(
        storeId: _selectedStore!.id,
        storeName: _selectedStore!.name,
        image: _selectedImage ?? await _getDefaultImage(),
        note: _note.isNotEmpty ? _note : 'Simple check-in',
        distance: _getDistanceToStore(),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Checked in at ${_selectedStore!.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Check-in failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  Future<XFile> _getDefaultImage() async {
    // Create a simple placeholder image if none selected
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    return image ?? XFile(''); // This should not happen in real scenario
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Check In'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.cyan),
            onPressed: () {
              print('🔄 [Check-in] Refreshing location...');
              _getCurrentLocation();
            },
            tooltip: 'Refresh Location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyan),
            onPressed: () {
              print('🔄 [Check-in] Reloading data...');
              _loadAttendanceData();
            },
            tooltip: 'Reload Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting location...'),
                ],
              ),
            )
          : Column(
              children: [
                // Simple map container
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _currentPosition != null
                          ? GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                zoom: 14.0,
                              ),
                              onMapCreated: (GoogleMapController controller) {
                                print('✅ Simple map created');
                                _updateMarkers();
                              },
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                  ),
                ),
                
                // Simple store selection or check-in panel
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: _showStoreSelection
                        ? _buildSimpleStoreList()
                        : _buildSimpleCheckInPanel(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSimpleStoreList() {
    final stores = _getAvailableStores();
    
    if (_isLoadingAttendance) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading available stores...'),
          ],
        ),
      );
    }
    
    if (stores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No available stores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All stores have been checked-in today',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Select Store (${stores.length} available)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: _isLoadingAttendance 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoadingAttendance ? null : () {
                _loadAttendanceData();
              },
              tooltip: 'Refresh available stores',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              final distance = _currentPosition != null
                  ? Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      double.parse(store.latitude ?? '0'),
                      double.parse(store.longitude ?? '0'),
                    )
                  : 0.0;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.store, color: Color.fromARGB(255, 41, 189, 206)),
                  title: Text(store.name),
                  subtitle: Text('${store.address}\nDistance: ${_formatDistance(distance)}'),
                  isThreeLine: true,
                  onTap: () => _selectStore(store),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleCheckInPanel() {
    if (_selectedStore == null) return const SizedBox();
    
    final distance = _getDistanceToStore();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedStore!.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Distance: ${_formatDistance(distance)}',
          style: TextStyle(
            color: distance <= 100 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        // Simple note field
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _note = value),
        ),
        
        const SizedBox(height: 16),
        
        // Simple check-in button
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStore = null;
                    _showStoreSelection = true;
                  });
                },
                child: const Text('Back to Stores'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (distance <= 100 && !_isCheckingIn) ? _performSimpleCheckIn : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 41, 189, 206),
                  foregroundColor: Colors.white,
                ),
                child: _isCheckingIn
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Checking in...'),
                        ],
                      )
                    : Text(distance <= 100 ? 'Check In' : 'Too Far'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
