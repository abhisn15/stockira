import 'package:flutter/material.dart';
import '../../services/photo_example_service.dart';
import '../../widgets/photo_example_widget.dart';

class FieldPhotoExamplesScreen extends StatelessWidget {
  final String fieldName;
  final String fieldTitle;

  const FieldPhotoExamplesScreen({
    super.key,
    required this.fieldName,
    required this.fieldTitle,
  });

  @override
  Widget build(BuildContext context) {
    final examples = PhotoExampleService.getPhotoExamples(fieldName);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          fieldTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Field description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_camera,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Deskripsi Field',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      PhotoExampleService.getFieldDescription(fieldName),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Photo examples
              if (examples.isNotEmpty)
                PhotoExampleList(
                  examples: examples,
                  title: 'Contoh Foto yang Benar',
                )
              else
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Contoh foto belum tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan ambil foto dengan pencahayaan yang baik dan sudut yang tepat',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Tips section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips untuk Field Ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._getFieldSpecificTips(fieldName).map((tip) => _buildTipItem(tip, [Colors.green])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getFieldSpecificTips(String fieldName) {
    switch (fieldName) {
      case 'photo_idn_freezer_1':
      case 'photo_idn_freezer_2':
        return [
          'Ambil foto dari depan freezer dengan jarak yang cukup',
          'Pastikan seluruh body freezer terlihat dalam frame',
          'Hindari bayangan yang menutupi freezer',
          'Pastikan pencahayaan merata di seluruh area freezer',
        ];
      
      case 'freezer_position_image':
        return [
          'Foto harus menunjukkan posisi freezer yang strategis',
          'Pastikan freezer mudah dijangkau oleh customer',
          'Tunjukkan area sekitarnya untuk konteks posisi',
        ];
      
      case 'photo_sticker_crispy_ball':
      case 'photo_sticker_mochi':
      case 'photo_sticker_sharing_olympic':
        return [
          'Foto harus menunjukkan sticker yang terpasang dengan rapi',
          'Pastikan teks pada sticker terbaca dengan jelas',
          'Hindari refleksi cahaya pada sticker',
          'Ambil foto dari jarak yang tepat agar sticker terlihat detail',
        ];
      
      case 'photo_price_board_olympic':
      case 'photo_price_board_led':
        return [
          'Foto harus menunjukkan papan harga yang terpasang dengan baik',
          'Pastikan harga dan informasi produk terbaca dengan jelas',
          'Untuk LED, pastikan lampu menyala dengan baik',
          'Hindari sudut yang membuat teks terdistorsi',
        ];
      
      case 'photo_wobler_promo':
      case 'photo_pop_promo':
        return [
          'Foto harus menunjukkan promo yang menarik perhatian',
          'Pastikan informasi promo terbaca dengan jelas',
          'Tunjukkan posisi promo yang strategis',
          'Hindari promo yang terlipat atau rusak',
        ];
      
      case 'photo_freezer_backup':
        return [
          'Foto harus menunjukkan freezer cadangan dengan jelas',
          'Pastikan kondisi freezer cadangan terlihat baik',
          'Tunjukkan posisi freezer cadangan relatif terhadap freezer utama',
        ];
      
      case 'photo_drum_freezer':
        return [
          'Foto harus menunjukkan drum freezer dalam kondisi baik',
          'Pastikan tidak ada kerusakan yang terlihat',
          'Tunjukkan posisi drum yang tepat',
        ];
      
      case 'photo_crispy_balls_tier':
        return [
          'Foto harus menunjukkan produk fokus dengan jelas',
          'Pastikan produk terlihat menarik dan rapi',
          'Tunjukkan tier/tingkat pajangan dengan baik',
        ];
      
      case 'photo_promo_running':
        return [
          'Foto harus diambil saat promo sedang berjalan',
          'Pastikan informasi promo terlihat jelas',
          'Tunjukkan aktivitas promo yang sedang berlangsung',
        ];
      
      default:
        return [
          'Ambil foto dengan pencahayaan yang baik',
          'Pastikan objek terlihat jelas dan tidak blur',
          'Gunakan sudut yang tepat untuk menunjukkan detail',
          'Hindari bayangan yang mengganggu',
        ];
    }
  }

  Widget _buildTipItem(String text, List<Color> colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: colors[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colors[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
