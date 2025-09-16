# 📱 Stockira - Aplikasi Manajemen Stok dan Laporan Penjualan

**Stockira** adalah aplikasi mobile yang dirancang khusus untuk membantu tim sales dan merchandising dalam mengelola stok produk, melacak penjualan, dan membuat laporan harian yang komprehensif. Aplikasi ini dibangun menggunakan Flutter dan mendukung platform Android dan iOS.

## 🎯 **Tentang Aplikasi**

Stockira adalah solusi digital yang memudahkan tim lapangan untuk:
- **Mengelola kehadiran** dengan sistem check-in/check-out berbasis GPS
- **Melacak ketersediaan produk** di berbagai toko
- **Membuat laporan penjualan** yang detail dan akurat
- **Memantau aktivitas kompetitor** dan harga pasar
- **Mengelola display produk** dan promosi

## 🚀 **Fitur Utama**

### 1. **Dashboard & Kehadiran**
- **Dashboard Interaktif**: Tampilan utama dengan informasi kehadiran, itinerary, dan aktivitas harian
- **Sistem Check-in/Check-out**: 
  - Validasi GPS untuk memastikan kehadiran di lokasi yang benar
  - Upload foto sebagai bukti kehadiran
  - Catatan dan keterangan untuk setiap check-in
  - Tracking jarak dan waktu kehadiran
- **Manajemen Itinerary**: 
  - Daftar toko yang harus dikunjungi
  - Tracking progress kunjungan
  - Statistik pencapaian harian

### 2. **Laporan Penjualan & Stok**
- **Sales Report**: Laporan penjualan dengan detail produk, harga, dan nilai transaksi
- **Out of Stock (OOS)**: Pelaporan produk yang kehabisan stok
- **Expired Date**: Tracking produk yang mendekati atau sudah expired
- **Product Focus**: Fokus pada produk tertentu dengan target penjualan
- **Product Belgian Berry**: Laporan khusus untuk produk Belgian Berry

### 3. **Manajemen Harga & Promosi**
- **Price Principal**: Pelaporan harga produk principal
- **Price Competitor**: Monitoring harga kompetitor
- **Promo Tracking**: Pelacakan promosi dan diskon yang sedang berjalan
- **Competitor Activity**: Monitoring aktivitas dan strategi kompetitor

### 4. **Display & Survey**
- **Regular Display**: Laporan kondisi display produk di toko
- **Survey**: Kuesioner komprehensif tentang kondisi toko dan produk
- **Display Reports**: Evaluasi efektivitas display produk

### 5. **Ketersediaan Produk (Availability)**
- **Product Availability**: Manajemen ketersediaan produk di setiap toko
- **Store Coverage**: Monitoring cakupan produk di berbagai outlet
- **Product Listing**: Tracking produk yang terdaftar di setiap toko

### 6. **Sistem Multi-Role**
- **SPG (Sales Promotion Girl)**: Akses ke laporan penjualan, stok, dan survey
- **MD CVS (Merchandiser CVS)**: Akses ke laporan produk, display, dan analisis mendalam
- **Role-based Access**: Setiap role memiliki fitur dan laporan yang sesuai

## 🛠 **Teknologi yang Digunakan**

### **Frontend**
- **Flutter**: Framework cross-platform untuk mobile development
- **Dart**: Bahasa pemrograman utama
- **Material Design**: UI/UX yang konsisten dan modern

### **Backend Integration**
- **REST API**: Komunikasi dengan server backend
- **JWT Authentication**: Sistem autentikasi yang aman
- **HTTP Client**: Untuk request dan response data

### **Libraries & Dependencies**
- **Google Maps**: Integrasi peta dan GPS tracking
- **Image Picker**: Upload foto untuk bukti kehadiran
- **Geolocator**: Tracking lokasi dan jarak
- **Shared Preferences**: Penyimpanan data lokal
- **Flutter Secure Storage**: Penyimpanan data sensitif
- **Table Calendar**: Komponen kalender untuk tracking kehadiran
- **Mobile Scanner**: QR/Barcode scanning
- **Flutter Translate**: Dukungan multi-bahasa (Indonesia & English)

## 📱 **Cara Kerja Aplikasi**

### **1. Login & Autentikasi**
- User login dengan kredensial yang diberikan
- Sistem otomatis mendeteksi role (SPG/MD CVS)
- Token JWT disimpan untuk akses API

### **2. Dashboard & Itinerary**
- Tampilan utama menampilkan status kehadiran
- Daftar toko yang harus dikunjungi hari ini
- Progress tracking dan statistik harian

### **3. Check-in Process**
- Pilih toko dari itinerary
- Validasi GPS (maksimal 100 meter dari toko)
- Upload foto sebagai bukti kehadiran
- Tambahkan catatan jika diperlukan
- Konfirmasi check-in

### **4. Laporan & Data Entry**
- Pilih jenis laporan sesuai role
- Isi form dengan data yang diperlukan
- Upload foto pendukung jika ada
- Submit laporan ke server

### **5. Check-out Process**
- Konfirmasi selesai kunjungan
- Upload foto check-out
- Sistem otomatis menghitung durasi kehadiran

## 🎨 **User Interface**

### **Design System**
- **Primary Color**: `#29BDCE` (Teal)
- **Secondary Colors**: 
  - Red untuk error dan warning
  - Green untuk success
  - Orange untuk expired date
  - Blue untuk price reports
  - Purple untuk competitor activity

### **Responsive Design**
- Optimized untuk berbagai ukuran layar
- Layout yang adaptif untuk mobile dan tablet
- Touch-friendly interface

### **Multi-language Support**
- Bahasa Indonesia (default)
- Bahasa Inggris
- Switch bahasa real-time

## 📊 **Fitur Laporan**

### **Daily Reports**
1. **Sales Report**
   - Input produk yang dijual
   - Harga dan nilai transaksi
   - Format mata uang Rupiah otomatis
   - Auto-calculation total nilai

2. **Out of Stock (OOS)**
   - Pelaporan produk kosong
   - Upload foto bukti
   - Kategori dan prioritas

3. **Expired Date**
   - Tracking produk expired
   - Tanggal kedaluwarsa
   - Status dan tindakan

### **Price Reports**
1. **Price Principal**
   - Harga produk principal
   - Perbandingan dengan target
   - Tracking perubahan harga

2. **Price Competitor**
   - Monitoring harga kompetitor
   - Analisis perbandingan
   - Strategi pricing

### **Display & Survey**
1. **Regular Display**
   - Kondisi display produk
   - Foto before/after
   - Evaluasi efektivitas

2. **Survey**
   - Kuesioner komprehensif
   - 50+ field data
   - Multiple store support
   - Dynamic form generation

## 🔧 **Installation & Setup**

### **Prerequisites**
- Flutter SDK (3.9.2 atau lebih baru)
- Dart SDK
- Android Studio / Xcode
- Git

### **Installation Steps**
```bash
# Clone repository
git clone [repository-url]
cd stockira

# Install dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons:main

# Run on device/emulator
flutter run
```

### **Environment Configuration**
1. Copy `.env.example` ke `.env`
2. Isi konfigurasi API dan Google Maps
3. Update `assets/i18n/` untuk customisasi bahasa

## 📱 **Platform Support**

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Responsive**: Support tablet dan phone

## 🔐 **Security Features**

- **JWT Authentication**: Token-based authentication
- **Secure Storage**: Data sensitif disimpan dengan enkripsi
- **GPS Validation**: Validasi lokasi untuk mencegah fraud
- **Image Upload**: Secure file upload dengan validation
- **API Security**: HTTPS dan secure headers

## 📈 **Performance**

- **Offline Support**: Data tersimpan lokal untuk akses offline
- **Caching**: Smart caching untuk performa optimal
- **Lazy Loading**: Load data sesuai kebutuhan
- **Memory Management**: Optimized untuk penggunaan memory

## 🎯 **Target Users**

### **SPG (Sales Promotion Girl)**
- Tim sales lapangan
- Fokus pada penjualan dan survey
- Tracking stok dan harga

### **MD CVS (Merchandiser CVS)**
- Tim merchandising
- Analisis produk dan display
- Monitoring kompetitor

## 📞 **Support & Maintenance**

- **Bug Reports**: Melalui issue tracker
- **Feature Requests**: Via feedback system
- **Documentation**: Comprehensive API docs
- **Updates**: Regular updates dan improvements

## 🚀 **Future Roadmap**

- [ ] **Analytics Dashboard**: Real-time analytics dan insights
- [ ] **Push Notifications**: Notifikasi real-time
- [ ] **Offline Sync**: Sinkronisasi data offline
- [ ] **Advanced Reporting**: Laporan yang lebih detail
- [ ] **Integration**: Integrasi dengan sistem ERP
- [ ] **AI Features**: Predictive analytics dan recommendations

## 📄 **License**

Aplikasi ini dikembangkan untuk keperluan internal perusahaan. Semua hak cipta dilindungi.

## 👥 **Contributors**

- **Development Team**: Flutter Development
- **UI/UX Design**: Material Design Implementation
- **Backend Integration**: API Development
- **Testing**: Quality Assurance

---

**Stockira** - Solusi Digital untuk Manajemen Stok dan Laporan Penjualan yang Efisien dan Akurat! 🚀