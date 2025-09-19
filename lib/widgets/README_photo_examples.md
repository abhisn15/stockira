# Photo Examples untuk Survey Form

## Overview
Sistem ini menyediakan contoh foto untuk setiap field survey agar SPG/MD dapat memahami cara mengambil foto yang benar.

## File yang Dibuat

### 1. `photo_example_helper.dart`
- Helper class yang mengelola mapping field ke contoh foto
- Menyediakan path gambar dan deskripsi untuk setiap field

### 2. `survey_photo_field_enhanced.dart`
- Widget yang menggantikan `_buildPhotoField` yang sudah ada
- Menampilkan contoh foto di bawah setiap field foto
- Memungkinkan user untuk melihat contoh foto dalam dialog

### 3. `photo_field_with_example_simple.dart`
- Widget sederhana untuk field foto dengan contoh
- Alternatif yang lebih ringan

### 4. `survey_form_example.dart`
- Contoh implementasi lengkap
- Menunjukkan cara mengintegrasikan ke form survey yang sudah ada

## Cara Menggunakan

### Integrasi ke Survey Form yang Sudah Ada

1. **Import widget yang diperlukan:**
```dart
import '../widgets/survey_photo_field_enhanced.dart';
```

2. **Ganti method `_buildPhotoField` yang sudah ada:**
```dart
Widget _buildPhotoField(String fieldName, String label) {
  final selectedImage = _photoFields[fieldName];
  final isUploaded = _uploadedImageUrls[fieldName] != null;
  
  return SurveyPhotoFieldEnhanced(
    fieldName: fieldName,
    label: label,
    selectedImage: selectedImage,
    isUploaded: isUploaded,
    onPickImage: () => _pickImage(fieldName),
    onRemoveImage: () => _removeImage(fieldName),
  );
}
```

3. **Tambahkan method `_removeImage` jika belum ada:**
```dart
void _removeImage(String fieldName) {
  setState(() {
    _photoFields[fieldName] = null;
    _uploadedImageUrls.remove(fieldName);
  });
}
```

### Field yang Didukung

Sistem ini mendukung semua field foto yang ada di survey form:

- `photo_idn_freezer_1` - Foto Freezer 1
- `photo_idn_freezer_2` - Foto Freezer 2
- `freezer_position_image` - Foto Posisi Freezer
- `photo_sticker_crispy_ball` - Foto Sticker Crispy Ball
- `photo_sticker_mochi` - Foto Sticker Mochi
- `photo_sticker_sharing_olympic` - Foto Sticker Sharing Olympic
- `photo_price_board_olympic` - Foto Papan Harga Olympic
- `photo_wobler_promo` - Foto Wobler Promo
- `photo_pop_promo` - Foto Pop Promo
- `photo_price_board_led` - Foto Price Board LED
- `photo_sticker_glass_mochi` - Foto Sticker Kaca Mochi
- `photo_sticker_frame_crispy_balls` - Foto Sticker Frame Crispy Balls
- `photo_freezer_backup` - Foto Freezer Cadangan
- `photo_drum_freezer` - Foto Drum Freezer
- `photo_crispy_balls_tier` - Foto Produk Fokus Crispy Balls
- `photo_promo_running` - Foto Promo Berjalan

### Contoh Foto yang Tersedia

Semua contoh foto sudah tersedia di folder `assets/survey/`:

- `contoh_foto_freezer_umum.png` - Contoh foto freezer umum
- `contoh_posisi_baik_firstposition_freezer.png` - Posisi freezer yang baik
- `contoh_foto_sticker_body_freezer_crispy_ball_olympic.png` - Sticker Crispy Ball
- `contoh_scticker_body_freezer_mochi_olympic.png` - Sticker Mochi
- `sticker_kaca.png` - Sticker di kaca
- `contoh_papan_harga_olympic.png` - Papan harga Olympic
- `contoh_foto_wobler_promo_umum.png` - Wobler promo
- `contoh_foto_pop_promo_umum.png` - Pop promo
- `contoh_price_board_led.png` - Price board LED
- `contoh_foto_kaca_mochi_olympic.png` - Sticker kaca Mochi
- `contoh_foto_kaca_frame_crispy_balls.png` - Sticker frame Crispy Balls
- `contoh_cara_ambil_foto_freezer_second_cabinet_freezercadangan.png` - Freezer cadangan
- `contoh_foto_drum_freezer.png` - Drum freezer
- `contoh_foto_produk_fokus_crispy_balls_pajangan_1_tier.png` - Produk fokus
- `cara_ambil_foto_promo_berjalan.png` - Promo berjalan

## Fitur

1. **Contoh Foto Otomatis**: Setiap field foto akan menampilkan contoh yang sesuai
2. **Dialog Preview**: User dapat tap contoh foto untuk melihat dalam ukuran besar
3. **Deskripsi**: Setiap contoh dilengkapi dengan deskripsi cara mengambil foto
4. **Error Handling**: Jika contoh foto tidak tersedia, akan menampilkan placeholder
5. **Responsive**: Widget menyesuaikan dengan ukuran layar

## Keuntungan

1. **Mengurangi Kesalahan**: SPG/MD dapat melihat contoh yang benar sebelum mengambil foto
2. **Konsistensi**: Semua foto akan memiliki standar yang sama
3. **User Experience**: Lebih mudah dipahami dan digunakan
4. **Maintenance**: Mudah untuk menambah atau mengubah contoh foto

## Troubleshooting

### Jika contoh foto tidak muncul:
1. Pastikan file gambar ada di folder `assets/survey/`
2. Pastikan path di `PhotoExampleHelper.getExampleImagePath()` benar
3. Pastikan `pubspec.yaml` sudah include folder `assets/survey/`

### Jika ada error loading gambar:
1. Periksa format file (harus PNG)
2. Periksa ukuran file (tidak terlalu besar)
3. Pastikan file tidak corrupt

## Pengembangan Lebih Lanjut

Untuk menambah field foto baru:
1. Tambahkan case baru di `PhotoExampleHelper.getExampleImagePath()`
2. Tambahkan deskripsi di `PhotoExampleHelper.getFieldDescription()`
3. Siapkan contoh foto dan letakkan di `assets/survey/`
4. Update mapping di survey form
