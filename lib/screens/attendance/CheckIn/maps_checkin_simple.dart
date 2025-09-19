import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/itinerary.dart';
import '../../../models/store.dart' as StoreModel;
import '../../../services/attendance_service.dart';
import '../../../services/maps_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/nearest_stores_service.dart';
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
  StoreModel.Store? _selectedStore;
  XFile? _selectedImage;
  String _note = '';
  bool _isLoading = true;
  bool _isCheckingIn = false;
  bool _showStoreSelection = true;
  final TextEditingController _noteController = TextEditingController();
  final AttendanceService _attendanceService = AttendanceService();
  final MapsService _mapsService = MapsService();

  Set<Marker> _markers = {};

  Set<int> _checkedInStoreIds = {};
  bool _isLoadingAttendance = false;

  List<StoreModel.Store> _nearestStores = [];
  bool _isLoadingNearestStores = false;
  String? _errorMessage;
  double _radius = 1.0;

  int _activeTabIndex = 0; // Default to Itinerary tab (index 0)
  final List<double> _radiusOptions = [0.5, 1.0, 2.0, 5.0, 10.0];
  final TextEditingController _searchController = TextEditingController();
  List<StoreModel.Store> _filteredStores = [];

  bool get _isDistanceValid => _selectedStore != null && _currentPosition != null && _getDistanceToStore() <= 100;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
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
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        _updateMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  Future<void> _loadNearestStores() async {
    if (_currentPosition == null) return;
    setState(() {
      _isLoadingNearestStores = true;
      _errorMessage = null;
    });
    try {
      final nearestResponse = await NearestStoresService.getNearestStoresWithRetry(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: _radius,
        limit: 20,
      );
      setState(() {
        _nearestStores = nearestResponse.data;
        _filteredStores = _nearestStores;
        _isLoadingNearestStores = false;
      });
      _updateMarkers();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading nearest stores: $e';
        _isLoadingNearestStores = false;
      });
    }
  }

  void _onRadiusChanged(double newRadius) {
    setState(() {
      _radius = newRadius;
    });
    _loadNearestStores();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStores = _nearestStores;
      } else {
        _filteredStores = _nearestStores.where((store) {
          return store.name.toLowerCase().contains(query.toLowerCase()) ||
              store.code.toLowerCase().contains(query.toLowerCase()) ||
              store.account.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _updateMarkers() {
    if (!mounted || _currentPosition == null) return;
    try {
      final markers = <Marker>{};
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        ),
      );
      if (_activeTabIndex == 1) {
        for (var store in _nearestStores) {
          final isSelected = _selectedStore?.id == store.id;
          markers.add(
            Marker(
              markerId: MarkerId('nearest_${store.id}'),
              position: LatLng(
                double.parse(store.latitude ?? '0'),
                double.parse(store.longitude ?? '0'),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(
                title: store.name,
                snippet: '${store.account.name}',
              ),
              onTap: () => _selectStore(store),
            ),
          );
        }
      }
      if (_activeTabIndex == 0 && _selectedStore != null && !_nearestStores.any((s) => s.id == _selectedStore!.id)) {
        markers.add(
          Marker(
            markerId: MarkerId('store_${_selectedStore!.id}'),
            position: LatLng(
              double.parse(_selectedStore!.latitude ?? '0'),
              double.parse(_selectedStore!.longitude ?? '0'),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: _selectedStore!.name,
              snippet: 'Selected Store',
            ),
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

  void _selectStore(StoreModel.Store store) {
    if (mounted) {
      setState(() {
        _selectedStore = store;
        _showStoreSelection = false;
      });
      _updateMarkers();
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoadingAttendance = true;
    });
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return;
      }
      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/attendances/store/check-in'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> attendanceList = responseData['data'];
          _checkedInStoreIds.clear();
          for (var attendance in attendanceList) {
            final List<dynamic> details = attendance['details'] ?? [];
            for (var detail in details) {
              final storeId = detail['store_id'] as int?;
              if (storeId != null) {
                _checkedInStoreIds.add(storeId);
              }
            }
          }
          setState(() {});
        }
      }
    } catch (e) {
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

  List<Store> _getAvailableStores() {
    final allStores = _getAllStores();
    final availableStores = allStores.where((store) => !_checkedInStoreIds.contains(store.id)).toList();
    return availableStores;
  }

  Future<void> _performSimpleCheckIn() async {
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
        Navigator.pop(context);
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
        Navigator.pop(context);
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
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    return image ?? XFile('');
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
              _getCurrentLocation();
            },
            tooltip: 'Refresh Location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyan),
            onPressed: () {
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
    return DefaultTabController(
      initialIndex: _activeTabIndex,
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              indicatorColor: const Color.fromARGB(255, 41, 189, 206),
              labelColor: const Color.fromARGB(255, 41, 189, 206),
              unselectedLabelColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  _activeTabIndex = index;
                });
                if (index == 1) {
                  _loadNearestStores();
                } else {
                  _updateMarkers();
                }
              },
              tabs: const [
                Tab(text: 'Itinerary'),
                Tab(text: 'Terdekat'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildItineraryStoresTab(),
                _buildNearestStoresTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearestStoresTab() {
    if (_isLoadingNearestStores) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat toko terdekat...'),
          ],
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat toko',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNearestStores,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_nearestStores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada toko ditemukan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada toko dalam radius ${_radius}km',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari toko...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Radius: '),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _radiusOptions.map((radius) {
                          final isSelected = _radius == radius;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('${radius}km'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) _onRadiusChanged(radius);
                              },
                              selectedColor: const Color.fromARGB(255, 41, 189, 206).withOpacity(0.3),
                              checkmarkColor: const Color.fromARGB(255, 41, 189, 206),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredStores.length,
            itemBuilder: (context, index) {
              final store = _filteredStores[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.store, color: Color.fromARGB(255, 41, 189, 206)),
                  title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.address ?? 'Alamat tidak tersedia', maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        'Kode: ${store.code} | Akun: ${store.account.name}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_currentPosition != null)
                        Text(
                          'Jarak: ${_formatDistance(
                            Geolocator.distanceBetween(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                              double.tryParse(store.latitude ?? '0') ?? 0,
                              double.tryParse(store.longitude ?? '0') ?? 0,
                            ),
                          )}',
                          style: const TextStyle(fontSize: 12, color: Colors.teal),
                        ),
                    ],
                  ),
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

  Widget _buildItineraryStoresTab() {
    final stores = _getAvailableStores();
    if (_isLoadingAttendance) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat daftar toko...'),
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
              'Semua toko sudah di check-in',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada toko itinerary yang tersedia hari ini',
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Toko Itinerary (${stores.length} tersedia)',
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
                tooltip: 'Refresh daftar toko',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              final distance = _currentPosition != null
                  ? Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      double.tryParse(store.latitude ?? '0') ?? 0,
                      double.tryParse(store.longitude ?? '0') ?? 0,
                    )
                  : 0.0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.store, color: Color.fromARGB(255, 41, 189, 206)),
                  title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.address ?? 'Alamat tidak tersedia', maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        'Kode: ${store.code}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_currentPosition != null)
                        Text(
                          'Jarak: ${_formatDistance(distance)}',
                          style: const TextStyle(fontSize: 12, color: Colors.teal),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    final storeModel = StoreModel.Store(
                      id: store.id,
                      name: store.name,
                      code: store.code,
                      address: store.address,
                      latitude: store.latitude ?? '0',
                      longitude: store.longitude ?? '0',
                      isDistributor: false,
                      isClose: false,
                      isRequested: false,
                      distance: distance,
                      account: StoreModel.StoreAccount(
                        id: 0,
                        name: 'Unknown Account',
                      ),
                      employees: [],
                    );
                    _selectStore(storeModel);
                  },
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
          'Jarak: ${_formatDistance(distance)}',
          style: TextStyle(
            color: distance <= 100 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Catatan (opsional)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _note = value),
        ),
        const SizedBox(height: 16),
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
                child: const Text('Kembali ke Daftar Toko'),
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
                          Text('Check-in...'),
                        ],
                      )
                    : Text(distance <= 100 ? 'Check In' : 'Terlalu Jauh'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
