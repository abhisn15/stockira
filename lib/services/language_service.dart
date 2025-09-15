import 'settings_service.dart';

class LanguageService {
  static String _currentLanguage = 'en';

  static Future<void> initialize() async {
    _currentLanguage = await SettingsService.getLanguage();
  }

  static String get currentLanguage => _currentLanguage;

  static Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await SettingsService.setLanguage(language);
  }

  // Dashboard translations
  static String get dashboard => _currentLanguage == 'id' ? 'Dashboard' : 'Dashboard';
  static String get home => _currentLanguage == 'id' ? 'Beranda' : 'Home';
  static String get payslip => _currentLanguage == 'id' ? 'Slip Gaji' : 'Payslip';
  static String get activity => _currentLanguage == 'id' ? 'Aktivitas' : 'Activity';
  static String get checkIn => _currentLanguage == 'id' ? 'Check In' : 'Check In';
  static String get checkOut => _currentLanguage == 'id' ? 'Check Out' : 'Check Out';
  static String get reports => _currentLanguage == 'id' ? 'Laporan' : 'Reports';
  static String get permit => _currentLanguage == 'id' ? 'Izin' : 'Permit';
  static String get profile => _currentLanguage == 'id' ? 'Profil' : 'Profile';
  static String get settings => _currentLanguage == 'id' ? 'Pengaturan' : 'Settings';
  static String get help => _currentLanguage == 'id' ? 'Bantuan' : 'Help';
  static String get logout => _currentLanguage == 'id' ? 'Keluar' : 'Logout';
  static String get close => _currentLanguage == 'id' ? 'Tutup' : 'Close';
  static String get cancel => _currentLanguage == 'id' ? 'Batal' : 'Cancel';
  static String get save => _currentLanguage == 'id' ? 'Simpan' : 'Save';
  static String get submit => _currentLanguage == 'id' ? 'Kirim' : 'Submit';
  static String get loading => _currentLanguage == 'id' ? 'Memuat...' : 'Loading...';
  static String get error => _currentLanguage == 'id' ? 'Error' : 'Error';
  static String get success => _currentLanguage == 'id' ? 'Berhasil' : 'Success';
  static String get warning => _currentLanguage == 'id' ? 'Peringatan' : 'Warning';
  static String get info => _currentLanguage == 'id' ? 'Informasi' : 'Info';

  // Activity translations
  static String get storeVisits => _currentLanguage == 'id' ? 'Kunjungan Toko' : 'Store Visits';
  static String get duration => _currentLanguage == 'id' ? 'Durasi' : 'Duration';
  static String get progress => _currentLanguage == 'id' ? 'Progress' : 'Progress';
  static String get completed => _currentLanguage == 'id' ? 'Selesai' : 'Completed';
  static String get pending => _currentLanguage == 'id' ? 'Menunggu' : 'Pending';
  static String get notCheckedIn => _currentLanguage == 'id' ? 'Belum Check In' : 'Not Checked In';
  static String get attendance => _currentLanguage == 'id' ? 'Kehadiran' : 'Attendance';
  static String get attendanceComplete => _currentLanguage == 'id' ? 'Kehadiran Selesai' : 'Attendance Complete';
  static String get belumCheckOut => _currentLanguage == 'id' ? 'Belum Check Out' : 'Not Checked Out';

  // Reports translations
  static String get dailyReports => _currentLanguage == 'id' ? 'Laporan Harian' : 'Daily Reports';
  static String get displayReports => _currentLanguage == 'id' ? 'Laporan Display' : 'Display Reports';
  static String get surveyReports => _currentLanguage == 'id' ? 'Laporan Survey' : 'Survey Reports';
  static String get sales => _currentLanguage == 'id' ? 'Penjualan' : 'Sales';
  static String get oos => _currentLanguage == 'id' ? 'Stok Habis' : 'OOS';
  static String get expiredDate => _currentLanguage == 'id' ? 'Tanggal Kedaluwarsa' : 'Expired Date';
  static String get survey => _currentLanguage == 'id' ? 'Survey' : 'Survey';
  static String get regularDisplay => _currentLanguage == 'id' ? 'Display Reguler' : 'Regular Display';
  static String get pricePrincipal => _currentLanguage == 'id' ? 'Harga Principal' : 'Price Principal';
  static String get priceCompetitor => _currentLanguage == 'id' ? 'Harga Kompetitor' : 'Price Competitor';
  static String get promoTracking => _currentLanguage == 'id' ? 'Pelacakan Promo' : 'Promo Tracking';
  static String get competitorActivity => _currentLanguage == 'id' ? 'Aktivitas Kompetitor' : 'Competitor Activity';
  static String get productFocus => _currentLanguage == 'id' ? 'Fokus Produk' : 'Product Focus';
  static String get display => _currentLanguage == 'id' ? 'Display' : 'Display';
  static String get productBelgianBerry => _currentLanguage == 'id' ? 'Produk Belgian Berry' : 'Product Belgian Berry';

  // Permit translations
  static String get permits => _currentLanguage == 'id' ? 'Izin' : 'Permits';
  static String get createPermit => _currentLanguage == 'id' ? 'Buat Izin' : 'Create Permit';
  static String get permitType => _currentLanguage == 'id' ? 'Tipe Izin' : 'Permit Type';
  static String get fullDay => _currentLanguage == 'id' ? 'Sehari Penuh' : 'Full Day';
  static String get halfDay => _currentLanguage == 'id' ? 'Setengah Hari' : 'Half Day';
  static String get startDate => _currentLanguage == 'id' ? 'Tanggal Mulai' : 'Start Date';
  static String get endDate => _currentLanguage == 'id' ? 'Tanggal Akhir' : 'End Date';
  static String get reason => _currentLanguage == 'id' ? 'Alasan' : 'Reason';
  static String get photo => _currentLanguage == 'id' ? 'Foto' : 'Photo';
  static String get takePhoto => _currentLanguage == 'id' ? 'Ambil Foto dari Camera' : 'Take Photo from Camera';
  static String get all => _currentLanguage == 'id' ? 'Semua' : 'All';
  static String get notChecked => _currentLanguage == 'id' ? 'Belum Dicek' : 'Not Checked';
  static String get approved => _currentLanguage == 'id' ? 'Disetujui' : 'Approved';
  static String get rejected => _currentLanguage == 'id' ? 'Ditolak' : 'Rejected';
  static String get noPermitsFound => _currentLanguage == 'id' ? 'Tidak ada izin ditemukan' : 'No permits found';
  static String get selectLanguage => _currentLanguage == 'id' ? 'Pilih Bahasa' : 'Select Language';
  static String get english => _currentLanguage == 'id' ? 'Bahasa Inggris' : 'English';
  static String get indonesian => _currentLanguage == 'id' ? 'Bahasa Indonesia' : 'Indonesian';

  // Permit specific translations
  static String get sick => _currentLanguage == 'id' ? 'Sakit' : 'Sick';
  static String get leave => _currentLanguage == 'id' ? 'Izin' : 'Leave';
  static String get vacation => _currentLanguage == 'id' ? 'Cuti' : 'Vacation';
  static String get off => _currentLanguage == 'id' ? 'Off' : 'Off';
  static String get storeClosed => _currentLanguage == 'id' ? 'Toko Tutup' : 'Store Closed';
  static String get specialLeave => _currentLanguage == 'id' ? 'Izin Khusus' : 'Special Leave';
  static String get extraOff => _currentLanguage == 'id' ? 'Extra Off' : 'Extra Off';

  // Settings translations
  static String get notifications => _currentLanguage == 'id' ? 'Notifikasi' : 'Notifications';
  static String get darkMode => _currentLanguage == 'id' ? 'Mode Gelap' : 'Dark Mode';
  static String get language => _currentLanguage == 'id' ? 'Bahasa' : 'Language';
  static String get urlSettings => _currentLanguage == 'id' ? 'Pengaturan URL' : 'URL Settings';

  // Common translations
  static String get yes => _currentLanguage == 'id' ? 'Ya' : 'Yes';
  static String get no => _currentLanguage == 'id' ? 'Tidak' : 'No';
  static String get ok => _currentLanguage == 'id' ? 'OK' : 'OK';
  static String get back => _currentLanguage == 'id' ? 'Kembali' : 'Back';
  static String get next => _currentLanguage == 'id' ? 'Selanjutnya' : 'Next';
  static String get previous => _currentLanguage == 'id' ? 'Sebelumnya' : 'Previous';
  static String get refresh => _currentLanguage == 'id' ? 'Refresh' : 'Refresh';
  static String get search => _currentLanguage == 'id' ? 'Cari' : 'Search';
  static String get filter => _currentLanguage == 'id' ? 'Filter' : 'Filter';
  static String get sort => _currentLanguage == 'id' ? 'Urutkan' : 'Sort';
  static String get edit => _currentLanguage == 'id' ? 'Edit' : 'Edit';
  static String get delete => _currentLanguage == 'id' ? 'Hapus' : 'Delete';
  static String get add => _currentLanguage == 'id' ? 'Tambah' : 'Add';
  static String get remove => _currentLanguage == 'id' ? 'Hapus' : 'Remove';
  static String get view => _currentLanguage == 'id' ? 'Lihat' : 'View';
  static String get details => _currentLanguage == 'id' ? 'Detail' : 'Details';
  static String get status => _currentLanguage == 'id' ? 'Status' : 'Status';
  static String get date => _currentLanguage == 'id' ? 'Tanggal' : 'Date';
  static String get time => _currentLanguage == 'id' ? 'Waktu' : 'Time';
  static String get name => _currentLanguage == 'id' ? 'Nama' : 'Name';
  static String get email => _currentLanguage == 'id' ? 'Email' : 'Email';
  static String get phone => _currentLanguage == 'id' ? 'Telepon' : 'Phone';
  static String get address => _currentLanguage == 'id' ? 'Alamat' : 'Address';
  static String get description => _currentLanguage == 'id' ? 'Deskripsi' : 'Description';
  static String get notes => _currentLanguage == 'id' ? 'Catatan' : 'Notes';
  static String get required => _currentLanguage == 'id' ? 'Wajib' : 'Required';
  static String get optional => _currentLanguage == 'id' ? 'Opsional' : 'Optional';

  // Auth translations
  static String get login => _currentLanguage == 'id' ? 'Masuk' : 'Login';
  static String get password => _currentLanguage == 'id' ? 'Kata Sandi' : 'Password';
  static String get forgotPassword => _currentLanguage == 'id' ? 'Lupa Kata Sandi' : 'Forgot Password';
  static String get passwordResetSuccess => _currentLanguage == 'id' ? 'Reset kata sandi berhasil' : 'Password reset successful';
  static String get backToLogin => _currentLanguage == 'id' ? 'Kembali ke Login' : 'Back to Login';
  static String get areYouSureLogout => _currentLanguage == 'id' ? 'Apakah Anda yakin ingin keluar?' : 'Are you sure you want to logout?';
  static String get loggingOut => _currentLanguage == 'id' ? 'Sedang keluar...' : 'Logging out...';
  static String get successfullyLoggedOut => _currentLanguage == 'id' ? 'Berhasil keluar' : 'Successfully logged out';
  static String get logoutFailed => _currentLanguage == 'id' ? 'Gagal keluar' : 'Logout failed';
  static String get updatingDashboard => _currentLanguage == 'id' ? 'Memperbarui dashboard...' : 'Updating dashboard...';

  // Common UI translations
  static String get confirm => _currentLanguage == 'id' ? 'Konfirmasi' : 'Confirm';
  static String get retry => _currentLanguage == 'id' ? 'Coba Lagi' : 'Retry';
  static String get continue_ => _currentLanguage == 'id' ? 'Lanjutkan' : 'Continue';
  static String get finish => _currentLanguage == 'id' ? 'Selesai' : 'Finish';
  static String get skip => _currentLanguage == 'id' ? 'Lewati' : 'Skip';
  static String get done => _currentLanguage == 'id' ? 'Selesai' : 'Done';
  static String get apply => _currentLanguage == 'id' ? 'Terapkan' : 'Apply';
  static String get reset => _currentLanguage == 'id' ? 'Reset' : 'Reset';
  static String get clear => _currentLanguage == 'id' ? 'Hapus' : 'Clear';
  static String get select => _currentLanguage == 'id' ? 'Pilih' : 'Select';
  static String get choose => _currentLanguage == 'id' ? 'Pilih' : 'Choose';
  static String get browse => _currentLanguage == 'id' ? 'Jelajahi' : 'Browse';
  static String get upload => _currentLanguage == 'id' ? 'Unggah' : 'Upload';
  static String get download => _currentLanguage == 'id' ? 'Unduh' : 'Download';
  static String get share => _currentLanguage == 'id' ? 'Bagikan' : 'Share';
  static String get copy => _currentLanguage == 'id' ? 'Salin' : 'Copy';
  static String get paste => _currentLanguage == 'id' ? 'Tempel' : 'Paste';
  static String get cut => _currentLanguage == 'id' ? 'Potong' : 'Cut';
  static String get undo => _currentLanguage == 'id' ? 'Batal' : 'Undo';
  static String get redo => _currentLanguage == 'id' ? 'Ulang' : 'Redo';

  // Additional missing translations
  static String get editProfile => _currentLanguage == 'id' ? 'Edit Profil' : 'Edit Profile';
  static String get helpSupport => _currentLanguage == 'id' ? 'Bantuan & Dukungan' : 'Help & Support';
  static String get needHelp => _currentLanguage == 'id' ? 'Butuh bantuan? Kami siap membantu!' : 'Need help? We\'re here for you!';
  static String get contactSupport => _currentLanguage == 'id' ? 'Hubungi Dukungan' : 'Contact Support';
  static String get callUs => _currentLanguage == 'id' ? 'Hubungi kami di +1 (555) 123-4567' : 'Call us at +1 (555) 123-4567';
  static String get emailSupport => _currentLanguage == 'id' ? 'Email Dukungan' : 'Email Support';
  static String get liveChat => _currentLanguage == 'id' ? 'Chat Langsung' : 'Live Chat';
  static String get employeeId => _currentLanguage == 'id' ? 'ID Karyawan' : 'Employee ID';
  static String get employee => _currentLanguage == 'id' ? 'Karyawan' : 'Employee';
  static String get johnDoe => _currentLanguage == 'id' ? 'John Doe' : 'John Doe';
  static String get emp001 => _currentLanguage == 'id' ? 'EMP001' : 'EMP001';
  
  // Attendance translations
  static String get filterAttendance => _currentLanguage == 'id' ? 'Filter Kehadiran' : 'Filter Attendance';
  static String get checkedIn => _currentLanguage == 'id' ? 'Sudah Check In' : 'Checked In';
  static String get refreshingData => _currentLanguage == 'id' ? 'Memperbarui data...' : 'Refreshing data...';
  static String get notCurrentlyCheckedIn => _currentLanguage == 'id' ? 'Anda belum check in' : 'You are not currently checked in';
  static String get successfullyCheckedOut => _currentLanguage == 'id' ? 'Berhasil check out' : 'Successfully checked out';
  static String get errorCheckingOut => _currentLanguage == 'id' ? 'Error saat check out' : 'Error checking out';
  static String get errorDuringCheckIn => _currentLanguage == 'id' ? 'Error saat check in' : 'Error during check-in';
  
  // Maps and Location translations
  static String get locationRefreshedSuccessfully => _currentLanguage == 'id' ? 'Lokasi berhasil diperbarui' : 'Location refreshed successfully';
  static String get failedToRefreshLocation => _currentLanguage == 'id' ? 'Gagal memperbarui lokasi' : 'Failed to refresh location';
  static String get usingDefaultLocation => _currentLanguage == 'id' ? 'Menggunakan lokasi default' : 'Using default location';
  static String get pleaseEnableLocationPermissions => _currentLanguage == 'id' ? 'Silakan aktifkan izin lokasi di pengaturan perangkat' : 'Please enable location permissions in device settings';
  static String get errorTakingPicture => _currentLanguage == 'id' ? 'Error mengambil foto' : 'Error taking picture';
  static String get chooseFromGallery => _currentLanguage == 'id' ? 'Pilih dari Galeri' : 'Choose from Gallery';
  static String get errorSelectingImage => _currentLanguage == 'id' ? 'Error memilih gambar' : 'Error selecting image';
  static String get pleaseCompleteAllRequirements => _currentLanguage == 'id' ? 'Silakan lengkapi semua persyaratan sebelum check in' : 'Please complete all requirements before checking in';
  static String get confirmCheckIn => _currentLanguage == 'id' ? 'Konfirmasi Check In' : 'Confirm Check-in';
  static String get areYouSureCheckIn => _currentLanguage == 'id' ? 'Apakah Anda yakin ingin check in?' : 'Are you sure you want to check in?';
  static String get store => _currentLanguage == 'id' ? 'Toko' : 'Store';
  static String get distance => _currentLanguage == 'id' ? 'Jarak' : 'Distance';
}
