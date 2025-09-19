# Create Location Feature Documentation

## 🎯 **Fitur yang Dibuat:**

```
Menambahkan fitur "Create Location" di menu dashboard untuk membuat request lokasi toko baru
```

## 🚀 **Komponen yang Dibuat:**

### **1. CreateLocationService**
**File:** `lib/services/create_location_service.dart`

**Fungsi:**
- ✅ **createLocationRequest()** - POST request ke `/stores/new-request`
- ✅ **getAreas()** - GET request ke `/areas?search`
- ✅ **getSubAreas()** - GET request ke `/sub-areas?area_id`

**API Endpoints:**
```dart
// Create new location request
POST {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/stores/new-request
Content-Type: multipart/form-data

Fields:
- name: String (required)
- sub_area_id: int (required)
- account_id: int (required)
- latitude: double (required)
- longitude: double (required)
- address: String (required)
- image: File (optional)

// Get areas for filtering
GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/areas?search

// Get sub-areas by area ID
GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/sub-areas?area_id=1
```

### **2. Create Location Models**
**File:** `lib/models/create_location.dart`

**Models:**
- ✅ **Area** - Model untuk area data
- ✅ **SubArea** - Model untuk sub area data
- ✅ **Account** - Model untuk account data
- ✅ **CreateLocationRequest** - Model untuk request data
- ✅ **CreateLocationResponse** - Model untuk response data

### **3. CreateLocationScreen**
**File:** `lib/screens/create_location/index.dart`

**Features:**
- ✅ **Form Fields** - Nama toko, area, sub area, account, alamat
- ✅ **GPS Location** - Automatic current location detection
- ✅ **Image Capture** - Optional photo capture
- ✅ **Validation** - Form validation dengan error messages
- ✅ **Loading States** - Loading indicators untuk async operations
- ✅ **Responsive UI** - Modern UI dengan indigo theme

### **4. Dashboard Menu Integration**
**File:** `lib/screens/dashboard/index.dart`

**Integration:**
- ✅ **Menu Icon** - `Icons.add_location` dengan warna hijau
- ✅ **Navigation** - Direct navigation ke CreateLocationScreen
- ✅ **Theme Consistency** - Mengikuti design pattern dashboard

## 🎨 **UI/UX Design:**

### **1. Form Layout**
```dart
// Modern card-based layout
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        spreadRadius: 1,
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    children: [
      // Form fields
    ],
  ),
)
```

### **2. Form Fields**
- ✅ **Store Name** - Text input dengan icon store
- ✅ **Area Dropdown** - Dynamic dropdown dengan API data
- ✅ **Sub Area Dropdown** - Dependent dropdown berdasarkan area
- ✅ **Account Dropdown** - Static dropdown dengan predefined accounts
- ✅ **Address** - Multi-line text input dengan icon home
- ✅ **GPS Location** - Auto-detected dengan refresh button
- ✅ **Image Capture** - Optional camera capture

### **3. Theme Colors**
```dart
// Consistent indigo theme
Colors.indigo          // Primary color
Colors.indigo[50]      // Light backgrounds
Colors.indigo[600]     // Icons and accents
Colors.green           // Success states
Colors.red             // Error states
```

## 🔧 **Technical Implementation:**

### **1. Form Validation**
```dart
// Comprehensive validation
if (_nameController.text.trim().isEmpty) {
  _showSnackBar('Nama toko harus diisi', Colors.red);
  return;
}

if (_selectedArea == null) {
  _showSnackBar('Area harus dipilih', Colors.red);
  return;
}

if (_currentLatitude == null || _currentLongitude == null) {
  _showSnackBar('Lokasi GPS tidak tersedia', Colors.red);
  return;
}
```

### **2. GPS Location Handling**
```dart
// Location permission and detection
Future<void> _getCurrentLocation() async {
  // Check location services
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  
  // Check permissions
  LocationPermission permission = await Geolocator.checkPermission();
  
  // Get current position
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  
  setState(() {
    _currentLatitude = position.latitude;
    _currentLongitude = position.longitude;
  });
}
```

### **3. Image Capture**
```dart
// Camera image capture
Future<void> _pickImage() async {
  final XFile? image = await _imagePicker.pickImage(
    source: ImageSource.camera,
    imageQuality: 80,
  );
  
  if (image != null) {
    setState(() {
      _selectedImage = File(image.path);
    });
  }
}
```

### **4. API Integration**
```dart
// Multipart request dengan file upload
final request = http.MultipartRequest('POST', uri);

// Add form fields
request.fields['name'] = name;
request.fields['sub_area_id'] = subAreaId.toString();
request.fields['account_id'] = accountId.toString();
request.fields['latitude'] = latitude.toString();
request.fields['longitude'] = longitude.toString();
request.fields['address'] = address;

// Add image file
if (image != null) {
  final imageFile = await http.MultipartFile.fromPath('image', image.path);
  request.files.add(imageFile);
}
```

## 🧪 **Testing Scenarios:**

### **Test 1: Form Validation**
1. Buka Create Location screen
2. Submit form tanpa mengisi field required
3. ✅ **Error messages muncul untuk field yang kosong**

### **Test 2: Area Selection**
1. Pilih area dari dropdown
2. Check apakah sub areas loading
3. ✅ **Sub areas muncul berdasarkan area yang dipilih**

### **Test 3: GPS Location**
1. Buka Create Location screen
2. Check apakah GPS location terdeteksi
3. Tap refresh button untuk update location
4. ✅ **GPS coordinates terdeteksi dan bisa di-refresh**

### **Test 4: Image Capture**
1. Tap "Ambil Foto" button
2. Capture foto atau cancel
3. ✅ **Foto ter-capture dan ditampilkan di UI**

### **Test 5: Form Submission**
1. Isi semua field required
2. Submit form
3. ✅ **Request berhasil dikirim dan form di-reset**

### **Test 6: Dashboard Navigation**
1. Buka dashboard
2. Tap "Create Location" menu
3. ✅ **Navigation ke Create Location screen berhasil**

## 📊 **Form Fields Mapping:**

### **API Fields:**
```dart
{
  "name": "Test",                    // Store name
  "sub_area_id": 42,                 // Selected sub area ID
  "account_id": 2,                   // Selected account ID
  "latitude": -6.2631126,            // GPS latitude
  "longitude": 106.7988186,          // GPS longitude
  "address": "Blok B2 No., Jl...",   // Store address
  "image": File                      // Optional image file
}
```

### **UI Form Fields:**
- ✅ **Nama Toko** → `name`
- ✅ **Area** → Used for filtering sub areas
- ✅ **Sub Area** → `sub_area_id`
- ✅ **Account** → `account_id`
- ✅ **GPS Location** → `latitude`, `longitude`
- ✅ **Alamat** → `address`
- ✅ **Foto Toko** → `image`

## 🎯 **User Flow:**

### **1. Access Create Location**
1. User buka dashboard
2. Tap "Create Location" menu
3. Navigate ke Create Location screen

### **2. Fill Form**
1. User isi nama toko
2. User pilih area (sub areas auto-load)
3. User pilih sub area
4. User pilih account
5. User isi alamat
6. GPS location auto-detected
7. User capture foto (optional)

### **3. Submit Request**
1. User tap "Buat Request Lokasi"
2. Form validation
3. API request dengan multipart data
4. Success message dan form reset
5. Navigate back ke dashboard

## 🚀 **Result:**

✅ **Complete Feature** - Fitur Create Location lengkap dengan semua komponen
✅ **API Integration** - Terintegrasi dengan API endpoints yang diberikan
✅ **Modern UI** - UI yang modern dan responsive dengan indigo theme
✅ **Form Validation** - Comprehensive validation dengan error messages
✅ **GPS Integration** - Automatic location detection dengan permission handling
✅ **Image Capture** - Optional photo capture functionality
✅ **Dashboard Integration** - Terintegrasi dengan dashboard menu
✅ **Error Handling** - Proper error handling dan user feedback
✅ **Loading States** - Loading indicators untuk better UX
✅ **Responsive Design** - Mobile-friendly responsive design

Sekarang fitur Create Location sudah siap digunakan untuk membuat request lokasi toko baru! 🎉
