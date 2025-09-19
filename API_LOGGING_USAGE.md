# API Logging Usage Guide

Sistem logging API telah diimplementasikan untuk membantu debugging dan monitoring request/response API dalam mode development.

## Fitur Logging

### 🌐 ApiLogger
- **Request Logging**: Log semua detail HTTP request termasuk URL, method, headers, dan body
- **Response Logging**: Log response dengan status code, headers, dan body
- **Error Logging**: Log error dengan stack trace untuk debugging
- **Multipart Logging**: Log khusus untuk upload file dan multipart request
- **Network Status**: Log status koneksi internet dan API
- **Endpoint Testing**: Log hasil test koneksi ke endpoint tertentu

### 🔧 HttpClientService
- Wrapper untuk semua HTTP request dengan logging otomatis
- Mendukung GET, POST, PUT, DELETE, dan multipart request
- Progress tracking untuk upload/download file
- Error handling terintegrasi

## Cara Penggunaan

### 1. Menggunakan HttpClientService (Recommended)

```dart
import 'package:stockira/services/http_client_service.dart';

// GET request
final response = await HttpClientService.get(
  Uri.parse('${Env.apiBaseUrl}/users'),
  headers: {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  },
);

// POST request
final response = await HttpClientService.post(
  Uri.parse('${Env.apiBaseUrl}/users'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: {
    'name': 'John Doe',
    'email': 'john@example.com',
  },
);

// Multipart request (file upload)
final response = await HttpClientService.multipartRequest(
  'POST',
  Uri.parse('${Env.apiBaseUrl}/upload'),
  headers: {'Authorization': 'Bearer $token'},
  fields: {'description': 'File upload'},
  files: [multipartFile],
);
```

### 2. Menggunakan ApiLogger secara Manual

```dart
import 'package:stockira/services/api_logger.dart';

// Log request manual
ApiLogger.logRequest(request);

// Log response manual
ApiLogger.logResponse(response, duration: Duration(milliseconds: 500));

// Log error manual
ApiLogger.logError(error, stackTrace, context: 'User login');

// Log network status
ApiLogger.logNetworkStatus(true, details: 'Connected to WiFi');

// Log endpoint test
ApiLogger.logEndpointTest('/api/users', true, statusCode: 200);
```

### 3. Enable/Disable Logging

```dart
import 'package:stockira/services/api_logger.dart';

// Enable logging (default: enabled in debug mode)
ApiLogger.setEnabled(true);

// Disable logging
ApiLogger.setEnabled(false);

// Check if logging is enabled
bool isEnabled = ApiLogger.isEnabled;
```

## Format Log Output

### Request Log
```
🌐 API 📤 REQUEST
GET https://api.example.com/users
Headers:
  Authorization: Bearer abcd...xyz
  Accept: application/json
Body:
  {
    "name": "John Doe"
  }
```

### Response Log
```
🌐 API 📥 RESPONSE
GET https://api.example.com/users
Status: 200 OK
Duration: 250ms
Headers:
  Content-Type: application/json
Body:
  {
    "success": true,
    "data": [...]
  }
```

### Error Log
```
🌐 API ❌ ERROR
Context: User login
Error: SocketException: Failed to connect
Stack Trace:
  ...
```

### Network Status Log
```
🌐 API 🌍 NETWORK STATUS
Connected: ✅
Details: Connected to WiFi
```

### Endpoint Test Log
```
🌐 API 🔍 ENDPOINT TEST
Endpoint: https://api.example.com/health
Status: ✅ SUCCESS
HTTP Status: 200
```

## Keamanan

- **Token Masking**: Authorization token akan di-mask secara otomatis (hanya menampilkan 4 karakter awal dan akhir)
- **Debug Mode Only**: Logging hanya aktif dalam mode debug (kDebugMode = true)
- **No Production Logs**: Logging tidak akan muncul di production build

## Services yang Sudah Diupdate

Berikut adalah services yang sudah diupdate untuk menggunakan sistem logging baru:

1. **AuthService** - Login, logout, profile
2. **ReportsApiService** - Report types, data, summary
3. **ItineraryService** - Itinerary data
4. **PermitService** - Permit submission dengan file upload
5. **NetworkService** - Connection testing

## Tips Debugging

1. **Cek Console**: Semua log akan muncul di debug console dengan format yang mudah dibaca
2. **Filter Logs**: Gunakan tag "API" untuk filter log di IDE
3. **Request Duration**: Monitor durasi request untuk identifikasi performa
4. **Error Context**: Setiap error akan memiliki context untuk membantu debugging
5. **Network Status**: Monitor status koneksi sebelum melakukan API call

## Contoh Troubleshooting

### Problem: API Request Gagal
```
🌐 API ❌ ERROR
Context: GET https://api.example.com/users
Error: SocketException: Failed to connect
```
**Solusi**: Cek koneksi internet dan URL API

### Problem: Response Timeout
```
🌐 API 📥 RESPONSE
GET https://api.example.com/users
Status: 200 OK
Duration: 30000ms
```
**Solusi**: Response terlalu lama, cek performa server atau network

### Problem: Invalid Token
```
🌐 API 📥 RESPONSE
GET https://api.example.com/users
Status: 401 Unauthorized
```
**Solusi**: Token expired atau invalid, perlu login ulang

## Development Mode

Logging hanya aktif dalam development mode. Untuk memastikan logging berfungsi:

1. Pastikan menjalankan app dalam debug mode (`flutter run`)
2. Cek bahwa `kDebugMode` bernilai `true`
3. Logging akan otomatis disable dalam release build

## Performance

- Logging menggunakan `developer.log()` untuk performa optimal
- Tidak ada overhead signifikan dalam development
- Logging otomatis disable dalam production build
