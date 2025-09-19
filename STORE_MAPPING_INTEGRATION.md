# Store Mapping Integration Guide

Sistem store mapping telah diintegrasikan dengan API backend untuk mengelola toko yang ditugaskan kepada karyawan.

## 🎯 Fitur yang Diintegrasikan

### 1. **Load Mapped Stores**
- **API**: `GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/stores?conditions[employees.id]={employeeId}`
- **Fungsi**: Mengambil daftar toko yang sudah ditugaskan kepada karyawan
- **Implementasi**: `StoreMappingService.getStoresByEmployee(employeeId)`

### 2. **Load Areas & Sub Areas**
- **API Areas**: `GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/areas`
- **API Sub Areas**: `GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/sub-areas?area_id={areaId}`
- **Fungsi**: Mengambil daftar area dan sub area untuk filter
- **Implementasi**: 
  - `StoreMappingService.getAreas()`
  - `StoreMappingService.getSubAreas(areaId)`

### 3. **Load Available Stores**
- **API**: `GET {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/stores?conditions[sub_area_id]={subAreaId}`
- **Fungsi**: Mengambil daftar toko yang tersedia berdasarkan sub area
- **Implementasi**: `StoreMappingService.getStoresBySubArea(subAreaId)`

### 4. **Add Stores to Employee**
- **API**: `POST {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/employees/stores`
- **Body**: `{"store_ids": [6,8]}`
- **Fungsi**: Menambahkan toko ke mapping karyawan
- **Implementasi**: `StoreMappingService.addStoresToEmployee(storeIds)`

### 5. **Update Store Location**
- **API**: `POST {{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/stores/location-update`
- **Body**: Form data dengan file upload
- **Fungsi**: Update lokasi toko dengan foto dan alasan
- **Implementasi**: `StoreMappingService.updateStoreLocation(...)`

## 📁 File yang Dibuat/Diupdate

### Models
- **`lib/models/store_mapping.dart`** - Model untuk Store, Area, SubArea, Employee, dan response classes

### Services
- **`lib/services/store_mapping_service.dart`** - Service untuk semua API calls store mapping

### Screens
- **`lib/screens/store_mapping/index.dart`** - Screen utama store mapping dengan integrasi API

## 🔧 Cara Penggunaan

### 1. Load Mapped Stores (Otomatis)
```dart
// Otomatis dipanggil saat screen dibuka
await _loadMappedStores();
```

### 2. Filter Area dan Sub Area
```dart
// Load areas
final areasResponse = await StoreMappingService.getAreas();

// Load sub areas berdasarkan area yang dipilih
final subAreasResponse = await StoreMappingService.getSubAreas(selectedAreaId);
```

### 3. Load Available Stores
```dart
// Load stores berdasarkan sub area yang dipilih
final storesResponse = await StoreMappingService.getStoresBySubArea(selectedSubAreaId);
```

### 4. Add Stores to Employee
```dart
// Pilih toko dan tambahkan ke mapping
final response = await StoreMappingService.addStoresToEmployee([storeId1, storeId2]);
if (response.success) {
  // Berhasil ditambahkan
}
```

### 5. Update Store Location
```dart
// Update lokasi toko dengan foto
final response = await StoreMappingService.updateStoreLocation(
  storeId: store.id,
  latitudeOld: store.latitude ?? 0.0,
  longitudeOld: store.longitude ?? 0.0,
  latitudeNew: currentPosition.latitude,
  longitudeNew: currentPosition.longitude,
  reason: reasonText,
  imageFile: selectedImageFile,
);
```

## 📊 Response Format

### Stores Response
```json
{
  "success": true,
  "message": "Stores retrieved successfully",
  "data": [
    {
      "id": 6,
      "name": "alfa kepatihan rakh",
      "code": "REQ/ALF/Sur/44163",
      "latitude": "-7.2396729",
      "longitude": "112.5975767",
      "address": "PHF5+FGM, Jl. Raya Gading Watu...",
      "account": {
        "id": 53,
        "name": "ALFAMART"
      },
      "employees": [...]
    }
  ]
}
```

### Areas Response
```json
{
  "success": true,
  "message": "Areas retrieved successfully",
  "data": [
    {
      "id": 1,
      "name": "RIAU",
      "code": null
    }
  ]
}
```

### Sub Areas Response
```json
{
  "success": true,
  "message": "Sub areas retrieved successfully",
  "data": [
    {
      "id": 2,
      "name": "RIAU",
      "code": null,
      "area": {
        "id": 1,
        "name": "RIAU",
        "code": null
      }
    }
  ]
}
```

## 🔐 Authentication

Semua API calls menggunakan Bearer token yang diambil dari `AuthService.getToken()`.

## 🌐 Network Logging

Semua API calls menggunakan `HttpClientService` yang sudah terintegrasi dengan logging system untuk debugging.

## 📱 UI Flow

### 1. Main Screen
- Menampilkan daftar toko yang sudah ditugaskan
- Tombol "+" untuk menambah toko baru

### 2. Add Store Screen
- Filter berdasarkan Area dan Sub Area
- Pilih toko yang tersedia
- Konfirmasi dan tambahkan

### 3. Store Location Screen
- Tampilkan detail toko
- Google Maps dengan marker
- Form update lokasi dengan foto
- Input alasan perubahan

## ⚠️ Error Handling

- Semua API calls memiliki try-catch dengan error handling
- Error ditampilkan dalam SnackBar
- Loading states untuk semua operasi async
- Validasi input sebelum API call

## 🔄 State Management

- Loading states untuk semua operasi
- Real-time update setelah operasi berhasil
- Reset form setelah operasi selesai
- Navigate back ke main screen setelah add stores

## 🚀 Testing

Untuk test integrasi:

1. **Test Load Mapped Stores**: Buka screen dan lihat apakah toko yang sudah ditugaskan muncul
2. **Test Filter**: Pilih area dan sub area, lihat apakah toko tersedia muncul
3. **Test Add Stores**: Pilih toko dan tambahkan, lihat apakah berhasil
4. **Test Location Update**: Buka detail toko, ambil foto, dan update lokasi

## 📝 Notes

- Employee ID diambil dari user yang sedang login
- Semua API calls menggunakan logging untuk debugging
- File upload untuk update lokasi menggunakan multipart request
- Error handling yang komprehensif untuk semua skenario
- UI yang responsif dengan loading states

## 🔧 Troubleshooting

### Problem: Employee ID tidak ditemukan
**Solusi**: Pastikan user sudah login dan memiliki employee ID

### Problem: API call gagal
**Solusi**: Cek koneksi internet dan token authentication

### Problem: File upload gagal
**Solusi**: Pastikan file image valid dan permission camera diberikan

### Problem: Location update gagal
**Solusi**: Pastikan GPS aktif dan permission location diberikan
