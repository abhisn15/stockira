import 'package:flutter/material.dart';

class PhotoExampleHelper {
  static const String _basePath = 'assets/survey/';

  /// Get example image path for a specific field
  static String? getExampleImagePath(String fieldName) {
    switch (fieldName) {
      case 'photo_idn_freezer_1':
      case 'photo_idn_freezer_2':
        return '${_basePath}contoh_foto_freezer_umum.png';
      
      case 'freezer_position_image':
        return '${_basePath}contoh_posisi_baik_firstposition_freezer.png';
      
      case 'photo_sticker_crispy_ball':
        return '${_basePath}contoh_foto_sticker_body_freezer_crispy_ball_olympic.png';
      
      case 'photo_sticker_mochi':
        return '${_basePath}contoh_scticker_body_freezer_mochi_olympic.png';
      
      case 'photo_sticker_sharing_olympic':
        return '${_basePath}sticker_kaca.png';
      
      case 'photo_price_board_olympic':
        return '${_basePath}contoh_papan_harga_olympic.png';
      
      case 'photo_wobler_promo':
        return '${_basePath}contoh_foto_wobler_promo_umum.png';
      
      case 'photo_pop_promo':
        return '${_basePath}contoh_foto_pop_promo_umum.png';
      
      case 'photo_price_board_led':
        return '${_basePath}contoh_price_board_led.png';
      
      case 'photo_sticker_glass_mochi':
        return '${_basePath}contoh_foto_kaca_mochi_olympic.png';
      
      case 'photo_sticker_frame_crispy_balls':
        return '${_basePath}contoh_foto_kaca_frame_crispy_balls.png';
      
      case 'photo_freezer_backup':
        return '${_basePath}contoh_cara_ambil_foto_freezer_second_cabinet_freezercadangan.png';
      
      case 'photo_drum_freezer':
        return '${_basePath}contoh_foto_drum_freezer.png';
      
      case 'photo_crispy_balls_tier':
        return '${_basePath}contoh_foto_produk_fokus_crispy_balls_pajangan_1_tier.png';
      
      case 'photo_promo_running':
        return '${_basePath}cara_ambil_foto_promo_berjalan.png';
      
      default:
        return null;
    }
  }

  /// Get field description
  static String getFieldDescription(String fieldName) {
    switch (fieldName) {
      case 'photo_idn_freezer_1':
      case 'photo_idn_freezer_2':
        return 'Ambil foto freezer dari depan dengan pencahayaan yang baik';
      case 'freezer_position_image':
        return 'Foto posisi freezer yang baik dan mudah dijangkau';
      case 'photo_sticker_crispy_ball':
        return 'Foto sticker Crispy Ball di body freezer';
      case 'photo_sticker_mochi':
        return 'Foto sticker Mochi Olympic di body freezer';
      case 'photo_sticker_sharing_olympic':
        return 'Foto sticker sharing Olympic di kaca freezer';
      case 'photo_price_board_olympic':
        return 'Foto papan harga Olympic yang terpasang rapi';
      case 'photo_wobler_promo':
        return 'Foto wobler promo yang menarik';
      case 'photo_pop_promo':
        return 'Foto pop promo yang terpasang dengan baik';
      case 'photo_price_board_led':
        return 'Foto price board LED yang menyala';
      case 'photo_sticker_glass_mochi':
        return 'Foto sticker Mochi di kaca freezer';
      case 'photo_sticker_frame_crispy_balls':
        return 'Foto sticker frame Crispy Balls di kaca freezer';
      case 'photo_freezer_backup':
        return 'Foto freezer cadangan/second cabinet';
      case 'photo_drum_freezer':
        return 'Foto drum freezer dalam kondisi baik';
      case 'photo_crispy_balls_tier':
        return 'Foto produk fokus Crispy Balls di pajangan';
      case 'photo_promo_running':
        return 'Foto saat promo sedang berjalan';
      default:
        return 'Ambil foto dengan pencahayaan yang baik';
    }
  }
}

class PhotoExampleWidget extends StatelessWidget {
  final String fieldName;
  final String label;

  const PhotoExampleWidget({
    super.key,
    required this.fieldName,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final exampleImagePath = PhotoExampleHelper.getExampleImagePath(fieldName);
    
    if (exampleImagePath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                size: 16,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Contoh Foto: $label',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            PhotoExampleHelper.getFieldDescription(fieldName),
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[700],
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _showExampleDialog(context, exampleImagePath, label);
            },
            child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  exampleImagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          Text(
                            'Contoh tidak tersedia',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExampleDialog(BuildContext context, String imagePath, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contoh: $title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              
              // Image
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contoh foto tidak tersedia',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
