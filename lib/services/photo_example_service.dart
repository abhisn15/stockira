import '../widgets/photo_example_widget.dart';

class PhotoExampleService {
  static const String _basePath = 'assets/survey/';

  /// Get photo examples for survey fields
  static List<PhotoExample> getPhotoExamples(String fieldName) {
    switch (fieldName) {
      // Freezer related
      case 'photo_idn_freezer_1':
      case 'photo_idn_freezer_2':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_freezer_umum.png',
            title: 'Contoh Foto Freezer',
            description: 'Ambil foto freezer dari depan dengan pencahayaan yang baik dan posisi yang tepat',
          ),
          PhotoExample(
            imagePath: '${_basePath}atribut_freezer.png',
            title: 'Atribut Freezer',
            description: 'Pastikan semua atribut freezer terlihat jelas dalam foto',
          ),
        ];

      case 'freezer_position_image':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_posisi_baik_firstposition_freezer.png',
            title: 'Posisi Freezer yang Baik',
            description: 'Freezer harus berada di posisi yang mudah dijangkau dan terlihat jelas',
          ),
        ];

      // Sticker related
      case 'photo_sticker_crispy_ball':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_sticker_crispy_ball_detail.png',
            title: 'Sticker Crispy Ball - Detail',
            description: 'Sticker Crispy Ball harus terpasang dengan rapi di body freezer',
          ),
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_sticker_body_freezer_crispy_ball_olympic.png',
            title: 'Sticker Crispy Ball - Olympic',
            description: 'Contoh sticker Crispy Ball Olympic di body freezer',
          ),
        ];

      case 'photo_sticker_mochi':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_sticker_mochi_detail.png',
            title: 'Sticker Mochi - Detail',
            description: 'Sticker Mochi harus terpasang dengan rapi di body freezer',
          ),
          PhotoExample(
            imagePath: '${_basePath}contoh_scticker_body_freezer_mochi_olympic.png',
            title: 'Sticker Mochi - Olympic',
            description: 'Contoh sticker Mochi Olympic di body freezer',
          ),
        ];

      case 'photo_sticker_sharing_olympic':
        return [
          PhotoExample(
            imagePath: '${_basePath}sticker_kaca.png',
            title: 'Sticker Sharing Olympic',
            description: 'Sticker sharing harus terpasang di kaca freezer',
          ),
        ];

      case 'photo_sticker_glass_mochi':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_kaca_mochi_olympic.png',
            title: 'Sticker Kaca Mochi',
            description: 'Sticker Mochi di kaca freezer harus terlihat jelas',
          ),
        ];

      case 'photo_sticker_frame_crispy_balls':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_sticker_frame_detail.png',
            title: 'Sticker Frame - Detail',
            description: 'Sticker frame Crispy Balls harus terpasang dengan rapi di kaca freezer',
          ),
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_kaca_frame_crispy_balls.png',
            title: 'Sticker Frame - Crispy Balls',
            description: 'Contoh sticker frame Crispy Balls di kaca freezer',
          ),
        ];

      // Price board related
      case 'photo_price_board_olympic':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_papan_harga_olympic.png',
            title: 'Papan Harga Olympic',
            description: 'Papan harga Olympic harus terpasang dengan rapi dan mudah dibaca',
          ),
          PhotoExample(
            imagePath: '${_basePath}price_board_alfamidi_dan_indomaret.png',
            title: 'Papan Harga Alfamidi & Indomaret',
            description: 'Contoh papan harga untuk toko Alfamidi dan Indomaret',
          ),
        ];

      case 'photo_price_board_led':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_price_board_led.png',
            title: 'Price Board LED',
            description: 'Price board LED harus menyala dan terlihat jelas',
          ),
        ];

      // Promo related
      case 'photo_wobler_promo':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_wobler_promo_umum.png',
            title: 'Wobler Promo',
            description: 'Wobler promo harus terpasang dengan menarik dan mudah terlihat',
          ),
        ];

      case 'photo_pop_promo':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_pop_promo_umum.png',
            title: 'Pop Promo',
            description: 'Pop promo harus terpasang dengan baik dan menarik perhatian',
          ),
        ];

      case 'photo_promo_running':
        return [
          PhotoExample(
            imagePath: '${_basePath}cara_ambil_foto_promo_berjalan.png',
            title: 'Foto Promo Berjalan',
            description: 'Ambil foto saat promo sedang berjalan dengan jelas',
          ),
        ];

      // Freezer backup and drum
      case 'photo_freezer_backup':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_cara_ambil_foto_freezer_second_cabinet_freezercadangan.png',
            title: 'Freezer Cadangan',
            description: 'Foto freezer cadangan/second cabinet harus terlihat jelas',
          ),
        ];

      case 'photo_drum_freezer':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_drum_freezer.png',
            title: 'Drum Freezer',
            description: 'Foto drum freezer harus menunjukkan kondisi yang baik',
          ),
        ];

      // Product focus
      case 'photo_crispy_balls_tier':
        return [
          PhotoExample(
            imagePath: '${_basePath}contoh_foto_produk_fokus_crispy_balls_pajangan_1_tier.png',
            title: 'Produk Fokus Crispy Balls',
            description: 'Foto produk fokus Crispy Balls di pajangan 1 tier',
          ),
        ];

      default:
        return [
          PhotoExample(
            imagePath: '${_basePath}freezer.png',
            title: 'Contoh Foto',
            description: 'Ambil foto dengan pencahayaan yang baik dan sudut yang tepat',
          ),
        ];
    }
  }

  /// Get all available photo examples
  static Map<String, List<PhotoExample>> getAllPhotoExamples() {
    return {
      'photo_idn_freezer_1': getPhotoExamples('photo_idn_freezer_1'),
      'photo_idn_freezer_2': getPhotoExamples('photo_idn_freezer_2'),
      'freezer_position_image': getPhotoExamples('freezer_position_image'),
      'photo_sticker_crispy_ball': getPhotoExamples('photo_sticker_crispy_ball'),
      'photo_sticker_mochi': getPhotoExamples('photo_sticker_mochi'),
      'photo_sticker_sharing_olympic': getPhotoExamples('photo_sticker_sharing_olympic'),
      'photo_price_board_olympic': getPhotoExamples('photo_price_board_olympic'),
      'photo_wobler_promo': getPhotoExamples('photo_wobler_promo'),
      'photo_pop_promo': getPhotoExamples('photo_pop_promo'),
      'photo_price_board_led': getPhotoExamples('photo_price_board_led'),
      'photo_sticker_glass_mochi': getPhotoExamples('photo_sticker_glass_mochi'),
      'photo_sticker_frame_crispy_balls': getPhotoExamples('photo_sticker_frame_crispy_balls'),
      'photo_freezer_backup': getPhotoExamples('photo_freezer_backup'),
      'photo_drum_freezer': getPhotoExamples('photo_drum_freezer'),
      'photo_crispy_balls_tier': getPhotoExamples('photo_crispy_balls_tier'),
      'photo_promo_running': getPhotoExamples('photo_promo_running'),
    };
  }

  /// Get field description
  static String getFieldDescription(String fieldName) {
    switch (fieldName) {
      case 'photo_idn_freezer_1':
      case 'photo_idn_freezer_2':
        return 'Foto freezer dari depan dengan pencahayaan yang baik';
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

  /// Get field title
  static String getFieldTitle(String fieldName) {
    switch (fieldName) {
      case 'photo_idn_freezer_1':
        return 'Foto Freezer 1';
      case 'photo_idn_freezer_2':
        return 'Foto Freezer 2';
      case 'freezer_position_image':
        return 'Foto Posisi Freezer';
      case 'photo_sticker_crispy_ball':
        return 'Foto Sticker Crispy Ball';
      case 'photo_sticker_mochi':
        return 'Foto Sticker Mochi';
      case 'photo_sticker_sharing_olympic':
        return 'Foto Sticker Sharing Olympic';
      case 'photo_price_board_olympic':
        return 'Foto Papan Harga Olympic';
      case 'photo_wobler_promo':
        return 'Foto Wobler Promo';
      case 'photo_pop_promo':
        return 'Foto Pop Promo';
      case 'photo_price_board_led':
        return 'Foto Price Board LED';
      case 'photo_sticker_glass_mochi':
        return 'Foto Sticker Kaca Mochi';
      case 'photo_sticker_frame_crispy_balls':
        return 'Foto Sticker Frame Crispy Balls';
      case 'photo_freezer_backup':
        return 'Foto Freezer Cadangan';
      case 'photo_drum_freezer':
        return 'Foto Drum Freezer';
      case 'photo_crispy_balls_tier':
        return 'Foto Produk Fokus Crispy Balls';
      case 'photo_promo_running':
        return 'Foto Promo Berjalan';
      default:
        return 'Foto';
    }
  }
}
