import 'package:flutter/material.dart';
import '../../services/photo_example_service.dart';
import '../../widgets/photo_example_widget.dart';

class PhotoExamplesScreen extends StatelessWidget {
  const PhotoExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allExamples = PhotoExampleService.getAllPhotoExamples();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contoh Foto Survey',
          style: TextStyle(
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
              // Header info
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
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Panduan Foto Survey',
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
                      'Berikut adalah contoh-contoh foto yang benar untuk setiap field survey. Pastikan foto yang diambil sesuai dengan contoh yang ditampilkan.',
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
              
              // Photo examples by category
              ...allExamples.entries.map((entry) {
                final fieldName = entry.key;
                final examples = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: PhotoExampleList(
                    examples: examples,
                    title: PhotoExampleService.getFieldTitle(fieldName),
                  ),
                );
              }),
              
              const SizedBox(height: 20),
              
              // Tips section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips Mengambil Foto yang Baik',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTipItem('Pastikan pencahayaan cukup dan tidak terlalu gelap atau terang'),
                    _buildTipItem('Ambil foto dari sudut yang tepat agar objek terlihat jelas'),
                    _buildTipItem('Pastikan objek yang difoto tidak terhalang atau terpotong'),
                    _buildTipItem('Gunakan resolusi yang cukup tinggi untuk kualitas foto yang baik'),
                    _buildTipItem('Pastikan foto tidak blur atau goyang'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
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
              color: Colors.orange[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
