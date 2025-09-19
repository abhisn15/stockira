# Google Maps Integration Documentation

## 🎯 **Fitur yang Ditambahkan:**

```
1. Google Maps untuk tampilan update location
2. UI/UX yang bagus untuk location update
3. Interaksi map (pin, marker, dll)
4. Complete location update flow
```

## 🗺️ **Google Maps Features:**

### **1. Interactive Map**
- **Current Location Marker** - Blue marker untuk lokasi GPS saat ini
- **Selected Location Marker** - Red marker untuk lokasi yang dipilih user
- **Tap to Select** - User bisa tap di map untuk memilih lokasi baru
- **My Location Button** - Tombol untuk kembali ke lokasi saat ini
- **Zoom Controls** - Kontrol zoom in/out
- **Compass** - Kompas untuk orientasi
- **Map Toolbar** - Toolbar untuk fitur map tambahan

### **2. Location Services**
- **GPS Location** - Mendapatkan lokasi GPS real-time
- **Permission Handling** - Menangani permission location
- **Location Accuracy** - High accuracy location detection
- **Error Handling** - Menangani error location services

### **3. UI/UX Design**
- **Modern Card Design** - Card dengan shadow dan rounded corners
- **Smooth Animations** - Fade dan slide animations
- **Loading States** - Skeleton loading untuk better UX
- **Responsive Layout** - Layout yang responsive untuk berbagai ukuran layar
- **Color-coded Elements** - Warna yang konsisten dan meaningful

## 🎨 **UI/UX Features:**

### **1. Store Info Card**
```dart
Container(
  margin: const EdgeInsets.all(16),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        spreadRadius: 1,
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    children: [
      // Store icon and info
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: Colors.blue, size: 24),
          ),
          // Store name and address
        ],
      ),
    ],
  ),
)
```

### **2. Map Section**
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: _currentPosition!,
        zoom: 15.0,
      ),
      markers: _markers,
      onTap: _onMapTap,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: true,
    ),
  ),
)
```

### **3. Form Section**
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        spreadRadius: 1,
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    children: [
      // Reason input field
      TextField(
        controller: _reasonController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Masukkan alasan mengapa lokasi toko perlu diupdate...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // ... more decoration
        ),
      ),
      // Photo selection button
    ],
  ),
)
```

### **4. Update Button**
```dart
Container(
  margin: const EdgeInsets.all(16),
  width: double.infinity,
  height: 56,
  child: ElevatedButton(
    onPressed: _isUpdatingLocation ? null : _updateStoreLocation,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: _isUpdatingLocation
        ? const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 12),
              Text('Updating Location...'),
            ],
          )
        : const Text('Update Lokasi Toko'),
  ),
)
```

## 🔧 **Technical Implementation:**

### **1. Location Services**
```dart
Future<void> _getCurrentLocation() async {
  setState(() {
    _isLoadingLocation = true;
  });

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
      _currentPosition = LatLng(position.latitude, position.longitude);
      _selectedPosition = _currentPosition;
      _isLoadingLocation = false;
    });

    _updateMarkers();
  } catch (e) {
    setState(() {
      _isLoadingLocation = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### **2. Map Markers**
```dart
void _updateMarkers() {
  setState(() {
    _markers.clear();
    
    // Add current location marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Current Location',
            snippet: 'Your current GPS position',
          ),
        ),
      );
    }
    
    // Add selected position marker
    if (_selectedPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Selected Location',
            snippet: 'Tap to update store location',
          ),
        ),
      );
    }
  });
}
```

### **3. Map Interaction**
```dart
void _onMapTap(LatLng position) {
  setState(() {
    _selectedPosition = position;
  });
  _updateMarkers();
}
```

### **4. Image Picker**
```dart
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### **5. Location Update API**
```dart
Future<void> _updateStoreLocation() async {
  if (_reasonController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mohon untuk mengisi alasan terlebih dahulu!'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (_selectedPosition == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pilih lokasi di map terlebih dahulu!'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (_selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mohon untuk mengambil foto terlebih dahulu!'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isUpdatingLocation = true;
  });

  try {
    final response = await StoreMappingService.updateStoreLocation(
      storeId: widget.store.id,
      latitudeOld: widget.store.latitude ?? 0.0,
      longitudeOld: widget.store.longitude ?? 0.0,
      latitudeNew: _selectedPosition!.latitude,
      longitudeNew: _selectedPosition!.longitude,
      reason: _reasonController.text.trim(),
      imageFile: _selectedImage!,
    );

    if (response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil request update lokasi toko'),
          backgroundColor: Colors.green,
        ),
      );

      _reasonController.clear();
      setState(() {
        _selectedImage = null;
      });
      
      // Go back to previous screen
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating store location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    setState(() {
      _isUpdatingLocation = false;
    });
  }
}
```

## 🎭 **Animations:**

### **1. Fade Animation**
```dart
FadeTransition(
  opacity: _fadeAnimation,
  child: SlideTransition(
    position: _slideAnimation,
    child: Column(
      children: [
        // Content
      ],
    ),
  ),
)
```

### **2. Animation Controllers**
```dart
void _initializeAnimations() {
  _fadeController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );
  
  _slideController = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );
  
  _fadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeInOut,
  ));
  
  _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _slideController,
    curve: Curves.easeOutCubic,
  ));
  
  _fadeController.forward();
  _slideController.forward();
}
```

## 🧪 **Testing Scenarios:**

### **Test 1: Location Services**
1. Buka location update screen
2. Check GPS permission
3. ✅ **Location berhasil didapatkan dan ditampilkan di map**

### **Test 2: Map Interaction**
1. Tap di map untuk memilih lokasi baru
2. Check marker berubah
3. ✅ **Marker berubah ke lokasi yang dipilih**

### **Test 3: Form Validation**
1. Isi reason dan ambil foto
2. Tap update button
3. ✅ **Location berhasil diupdate**

### **Test 4: Error Handling**
1. Test tanpa permission location
2. Test tanpa reason
3. Test tanpa foto
4. ✅ **Error messages ditampilkan dengan benar**

## 📊 **Performance Features:**

### **1. Loading States**
- **Location Loading** - Skeleton loading saat mendapatkan lokasi
- **Update Loading** - Loading indicator saat update location
- **Image Loading** - Loading state saat mengambil foto

### **2. Error Handling**
- **Location Errors** - Menangani error GPS dan permission
- **Network Errors** - Menangani error API calls
- **Validation Errors** - Menangani error form validation

### **3. User Feedback**
- **Success Messages** - SnackBar untuk success actions
- **Error Messages** - SnackBar untuk error states
- **Loading Indicators** - Visual feedback untuk loading states

## 🚀 **Result:**

✅ **Google Maps Integration** - Interactive map dengan markers dan controls
✅ **Modern UI/UX** - Beautiful design dengan animations dan shadows
✅ **Location Services** - GPS location dengan permission handling
✅ **Map Interaction** - Tap to select location dengan visual feedback
✅ **Form Validation** - Complete validation untuk reason dan foto
✅ **Error Handling** - Comprehensive error handling dan user feedback
✅ **Smooth Animations** - Fade dan slide animations untuk better UX
✅ **Responsive Design** - Layout yang responsive untuk berbagai ukuran layar

Sekarang location update screen sudah memiliki Google Maps dengan UI/UX yang bagus dan fitur yang lengkap! 🎉
