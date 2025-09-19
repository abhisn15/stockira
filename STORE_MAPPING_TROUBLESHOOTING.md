# Store Mapping Troubleshooting Guide

## 🔧 Masalah: Area dan Sub Area Tidak Muncul

### ✅ **Perbaikan yang Telah Dilakukan:**

#### 1. **Dropdown Fixes**
- ✅ **Fixed `value` vs `initialValue`** - Menggunakan `value` untuk controlled dropdown
- ✅ **Added proper hint text** - Menampilkan pesan yang sesuai
- ✅ **Fixed empty items handling** - Dropdown tidak crash ketika kosong
- ✅ **Added conditional onChanged** - Dropdown disabled ketika tidak ada data

#### 2. **Debug Information**
- ✅ **Console logging** - Print statements untuk tracking API calls
- ✅ **UI debug indicators** - Visual feedback untuk loading states
- ✅ **Refresh button** - Tombol untuk reload areas
- ✅ **Status indicators** - Menampilkan jumlah data yang loaded

#### 3. **API Service Debugging**
- ✅ **Request logging** - Log URL dan parameters
- ✅ **Response logging** - Log status code dan response body
- ✅ **Error handling** - Detailed error messages

### 🔍 **Cara Debug:**

#### 1. **Check Console Logs**
Buka console/debug output dan lihat:
```
StoreMappingService.getAreas() called
Areas API URL: https://your-api.com/api/areas
Areas API response status: 200
Areas API response body: {...}
Areas parsed: X areas
```

#### 2. **Check UI Indicators**
- **Orange box** = Areas sedang loading atau kosong
- **Blue box** = Sub areas sedang loading untuk area yang dipilih
- **Refresh button** = Untuk reload areas

#### 3. **Check Network Requests**
- Pastikan API endpoint benar: `{{BASE_URL}}/{{PREFIX_API}}/{{API_VERSION}}/areas`
- Pastikan token authentication valid
- Pastikan response format sesuai dengan model

### 🚨 **Kemungkinan Penyebab:**

#### 1. **API Endpoint Issues**
- **URL salah** - Cek `Env.apiBaseUrl` dan endpoint path
- **Authentication** - Token tidak valid atau expired
- **Network** - Koneksi internet bermasalah

#### 2. **Response Format Issues**
- **JSON structure** - Response tidak sesuai dengan model
- **Field names** - Field name tidak match dengan model
- **Data types** - Tipe data tidak sesuai

#### 3. **Model Parsing Issues**
- **fromJson method** - Error dalam parsing JSON
- **Null handling** - Null values tidak dihandle dengan benar

### 🛠️ **Langkah Troubleshooting:**

#### Step 1: Check API Response
```dart
// Tambahkan di service untuk debug
print('Areas API response body: ${response.body}');
```

#### Step 2: Check Model Parsing
```dart
// Tambahkan di model untuk debug
factory Area.fromJson(Map<String, dynamic> json) {
  print('Parsing area: $json');
  return Area(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    code: json['code'],
  );
}
```

#### Step 3: Check State Updates
```dart
// Tambahkan di screen untuk debug
setState(() {
  _areas.clear();
  _areas.addAll(response.data);
  print('Areas updated: ${_areas.length}');
});
```

### 📱 **Testing Steps:**

#### 1. **Test Areas Loading**
- Buka screen store mapping
- Lihat console logs
- Check apakah ada orange debug box
- Tap refresh button jika perlu

#### 2. **Test Area Selection**
- Pilih area dari dropdown
- Lihat apakah sub areas loading
- Check console logs untuk sub areas API call

#### 3. **Test Sub Area Selection**
- Pilih sub area dari dropdown
- Lihat apakah stores loading
- Check apakah toko muncul di list

### 🔧 **Quick Fixes:**

#### Fix 1: Force Refresh
```dart
// Tambahkan method untuk force refresh
Future<void> _forceRefreshAreas() async {
  setState(() {
    _areas.clear();
    _selectedArea = null;
    _selectedSubArea = null;
    _subAreas.clear();
    _availableStores.clear();
  });
  await _loadAreas();
}
```

#### Fix 2: Add Loading State
```dart
bool _isLoadingAreas = false;

Future<void> _loadAreas() async {
  setState(() {
    _isLoadingAreas = true;
  });
  try {
    // API call
  } finally {
    setState(() {
      _isLoadingAreas = false;
    });
  }
}
```

#### Fix 3: Add Error Recovery
```dart
Future<void> _loadAreas() async {
  try {
    // API call
  } catch (e) {
    // Show error dialog with retry option
    _showErrorDialog(e.toString());
  }
}

void _showErrorDialog(String error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Error'),
      content: Text(error),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _loadAreas();
          },
          child: Text('Retry'),
        ),
      ],
    ),
  );
}
```

### 📊 **Expected Behavior:**

#### Normal Flow:
1. **Screen opens** → Areas loading (orange box visible)
2. **Areas loaded** → Orange box disappears, dropdown enabled
3. **Area selected** → Sub areas loading (blue box visible)
4. **Sub areas loaded** → Blue box disappears, sub area dropdown enabled
5. **Sub area selected** → Stores loading, stores appear in list

#### Error Scenarios:
1. **No areas** → Orange box with refresh button
2. **No sub areas** → Blue box with loading message
3. **API error** → SnackBar with error message
4. **Network error** → Retry option available

### 🎯 **Next Steps:**

1. **Run the app** dan check console logs
2. **Check API responses** di network tab
3. **Verify model parsing** dengan debug prints
4. **Test dropdown behavior** step by step
5. **Report specific errors** jika masih ada masalah

### 📝 **Debug Checklist:**

- [ ] Console logs muncul untuk API calls
- [ ] API URL benar dan accessible
- [ ] Response status 200
- [ ] Response body format sesuai model
- [ ] Model parsing tidak error
- [ ] State update berhasil
- [ ] UI refresh setelah state update
- [ ] Dropdown items populated
- [ ] onChanged callback berfungsi

Dengan perbaikan ini, area dan sub area seharusnya bisa muncul dengan benar. Jika masih ada masalah, check console logs untuk detail error yang spesifik.
