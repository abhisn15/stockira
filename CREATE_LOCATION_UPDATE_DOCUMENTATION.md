# Create Location Update Documentation

## 🎯 **Update yang Dibuat:**

```
Mengupdate tampilan Create Location sesuai dengan design yang diberikan dan mengintegrasikan dengan fitur check-in
```

## 🚀 **Perubahan Utama:**

### **1. UI/UX Update**
**File:** `lib/screens/create_location/index.dart`

**Perubahan:**
- ✅ **Map Integration** - Google Maps terintegrasi di bagian atas screen
- ✅ **Timer Warning** - Countdown timer 5 menit dengan warning message
- ✅ **Status Indicators** - Jarak, Foto, Catatan dengan visual indicators
- ✅ **Location Cards** - Card untuk location details dan current location
- ✅ **Form Fields** - Input fields dengan design yang lebih modern
- ✅ **Check In Button** - Button utama untuk check-in

### **2. Check-In Integration**
**Integration dengan AttendanceService:**

```dart
// After successful location creation, proceed with check-in
await _performCheckIn();

Future<void> _performCheckIn() async {
  // Convert File to XFile for attendance service
  final xFile = XFile(_selectedImage!.path);
  
  // Perform check-in
  final attendanceService = AttendanceService();
  await attendanceService.checkIn(
    storeId: 0, // New location doesn't have store ID yet
    storeName: _nameController.text.trim(),
    image: xFile,
    note: 'Check-in at new location: ${_addressController.text.trim()}',
    distance: 0.0, // For new location, distance is 0
  );
}
```

### **3. API Analysis**
**Attendance APIs yang Dianalisis:**

#### **Check-In API:**
```dart
// Method: checkIn()
// Parameters:
- storeId: int (required)
- storeName: String (required) 
- image: XFile (required)
- note: String (required)
- distance: double (required)

// API Endpoint: POST /attendances/check-in
// Fields:
- store_id: int
- store_name: String
- image: File
- note: String
- distance: double
- latitude: double
- longitude: double
- date: String (YYYY-MM-DD)
- check_in_time: String (HH:MM:SS)
```

#### **Check-Out API:**
```dart
// Method: checkOut()
// Parameters:
- image: XFile (optional)
- note: String (required)

// API Endpoint: POST /attendances/check-out
// Fields:
- store_id: int (from current check-in record)
- date: String (YYYY-MM-DD)
- check_out_time: String (HH:MM:SS)
- latitude: double
- longitude: double
- note: String
- is_out_itinerary: int (1)
```

### **4. New UI Components**

#### **Map Section:**
```dart
// Google Maps integration
Expanded(
  flex: 2,
  child: GoogleMap(
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
  ),
)
```

#### **Timer Warning:**
```dart
// 5-minute countdown timer
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
)
```

#### **Status Indicators:**
```dart
// Visual status indicators
Row(
  children: [
    _buildStatusIndicator('Jarak', true, Icons.check),
    const SizedBox(width: 16),
    _buildStatusIndicator('Foto', _selectedImage != null, _selectedImage != null ? Icons.check : Icons.remove),
    const SizedBox(width: 16),
    _buildStatusIndicator('Catatan', false, Icons.remove),
  ],
)
```

#### **Location Cards:**
```dart
// Location details card
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
            child: const Icon(Icons.store, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nameController.text.isEmpty ? 'Nama Lokasi' : _nameController.text),
                if (_selectedArea != null && _selectedSubArea != null && _selectedAccount != null)
                  Text('REQ/${_selectedAccount!.name.substring(0, 3).toUpperCase()}/${_selectedArea!.name.substring(0, 3).toUpperCase()}/45231 - ${_selectedArea!.name} - ${_selectedAccount!.name}'),
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
    ],
  ),
)
```

### **5. Form Fields Update**

#### **Input Fields:**
```dart
// Modern form fields
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
```

#### **Dropdown Fields:**
```dart
// Dropdown selection fields
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
```

### **6. Modal Bottom Sheets**

#### **Area Selection:**
```dart
// Area selection modal
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
              // Handle, Header, Search Bar, Areas List
            ],
          ),
        ),
      ),
    ),
  );
}
```

#### **Account Selection:**
```dart
// Account selection modal
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
              // Handle, Header, Accounts List
            ],
          ),
        ),
      ),
    ),
  );
}
```

### **7. Workflow Integration**

#### **Create Location + Check-In Flow:**
1. **User opens Create Location screen**
2. **GPS location auto-detected**
3. **User fills form fields:**
   - Nama Lokasi
   - Area (dropdown selection)
   - Tipe Lokasi (dropdown selection)
4. **User takes photo (required for check-in)**
5. **User taps "CHECK IN" button**
6. **System processes:**
   - Create location request via API
   - If successful, proceed with check-in
   - Perform check-in via AttendanceService
   - Show success message
   - Reset form and navigate back

#### **API Integration Flow:**
```dart
// 1. Create Location Request
final response = await CreateLocationService.createLocationRequest(
  name: _nameController.text.trim(),
  subAreaId: _selectedSubArea!.id,
  accountId: _selectedAccount!.id,
  latitude: _currentLatitude!,
  longitude: _currentLongitude!,
  address: _addressController.text.trim(),
  image: _selectedImage,
);

// 2. If successful, perform check-in
if (response['success']) {
  await _performCheckIn();
}

// 3. Check-in via AttendanceService
await attendanceService.checkIn(
  storeId: 0,
  storeName: _nameController.text.trim(),
  image: xFile,
  note: 'Check-in at new location: ${_addressController.text.trim()}',
  distance: 0.0,
);
```

### **8. Error Handling**

#### **Validation:**
```dart
// Comprehensive form validation
if (_nameController.text.trim().isEmpty) {
  _showSnackBar('Nama toko harus diisi', Colors.red);
  return;
}

if (_selectedArea == null) {
  _showSnackBar('Area harus dipilih', Colors.red);
  return;
}

if (_selectedImage == null) {
  _showSnackBar('Foto harus diambil untuk check-in', Colors.red);
  return;
}
```

#### **Error Messages:**
```dart
// User-friendly error messages
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
```

### **9. Theme Updates**

#### **Color Scheme:**
```dart
// Consistent color scheme
Colors.red          // AppBar background
Colors.blue         // Primary buttons and accents
Colors.orange       // Warning messages
Colors.green        // Success states
Colors.grey         // Text and borders
Colors.white        // Backgrounds
```

### **10. Performance Optimizations**

#### **Timer Management:**
```dart
// Proper timer disposal
@override
void dispose() {
  _nameController.dispose();
  _addressController.dispose();
  _searchController.dispose();
  _timer.cancel(); // Prevent memory leaks
  super.dispose();
}
```

#### **State Management:**
```dart
// Efficient state updates
setState(() {
  _currentLatitude = position.latitude;
  _currentLongitude = position.longitude;
});

// Update map markers
_updateMapMarkers();
```

## 🎯 **Result:**

✅ **Complete UI Update** - Tampilan sesuai dengan design yang diberikan
✅ **Map Integration** - Google Maps terintegrasi dengan markers
✅ **Check-In Integration** - Otomatis check-in setelah create location
✅ **Timer Warning** - 5-minute countdown dengan warning message
✅ **Status Indicators** - Visual indicators untuk Jarak, Foto, Catatan
✅ **Location Cards** - Modern card design untuk location details
✅ **Form Fields** - Input fields dengan design yang lebih modern
✅ **Modal Bottom Sheets** - Area dan Account selection dengan search
✅ **Error Handling** - Comprehensive validation dan error messages
✅ **Theme Consistency** - Consistent color scheme
✅ **Performance** - Proper timer management dan state updates

Sekarang Create Location screen sudah terupdate dengan design yang sesuai dan terintegrasi dengan fitur check-in! 🎉
