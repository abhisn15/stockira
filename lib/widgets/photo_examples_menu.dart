import 'package:flutter/material.dart';
import '../screens/photo_examples/index.dart';
import '../screens/photo_examples/all_examples.dart';

class PhotoExamplesMenu extends StatelessWidget {
  const PhotoExamplesMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Header
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Contoh Foto Survey',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Lihat contoh-contoh foto yang benar untuk setiap field survey',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Menu buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PhotoExamplesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Semua Contoh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllPhotoExamplesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Cari Contoh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PhotoExamplesFloatingMenu extends StatelessWidget {
  const PhotoExamplesFloatingMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PhotoExamplesScreen(),
          ),
        );
      },
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      icon: const Icon(Icons.photo_library),
      label: const Text('Contoh Foto'),
    );
  }
}

class PhotoExamplesBottomSheet extends StatelessWidget {
  const PhotoExamplesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Header
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Contoh Foto Survey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Menu options
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.blue),
            title: const Text('Semua Contoh Foto'),
            subtitle: const Text('Lihat semua contoh foto survey'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PhotoExamplesScreen(),
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.search, color: Colors.green),
            title: const Text('Cari Contoh Foto'),
            subtitle: const Text('Cari contoh foto berdasarkan field'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllPhotoExamplesScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class PhotoExamplesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenuButton;

  const PhotoExamplesAppBar({
    super.key,
    required this.title,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
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
      actions: showMenuButton
          ? [
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => const PhotoExamplesBottomSheet(),
                  );
                },
                icon: const Icon(Icons.more_vert),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
