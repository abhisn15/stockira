import 'package:flutter/material.dart';
import '../services/photo_example_service.dart';
import '../screens/photo_examples/field_examples.dart';

class PhotoExampleButton extends StatelessWidget {
  final String fieldName;
  final String? customTitle;

  const PhotoExampleButton({
    super.key,
    required this.fieldName,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    final examples = PhotoExampleService.getPhotoExamples(fieldName);
    
    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FieldPhotoExamplesScreen(
              fieldName: fieldName,
              fieldTitle: customTitle ?? PhotoExampleService.getFieldTitle(fieldName),
            ),
          ),
        );
      },
      icon: const Icon(Icons.photo_library, size: 16),
      label: const Text('Lihat Contoh'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: Colors.blue[600],
      ),
    );
  }
}

class PhotoExampleFloatingButton extends StatelessWidget {
  final String fieldName;
  final String? customTitle;

  const PhotoExampleFloatingButton({
    super.key,
    required this.fieldName,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    final examples = PhotoExampleService.getPhotoExamples(fieldName);
    
    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.small(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FieldPhotoExamplesScreen(
              fieldName: fieldName,
              fieldTitle: customTitle ?? PhotoExampleService.getFieldTitle(fieldName),
            ),
          ),
        );
      },
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      child: const Icon(Icons.photo_library, size: 18),
    );
  }
}

class PhotoExampleChip extends StatelessWidget {
  final String fieldName;
  final String? customTitle;

  const PhotoExampleChip({
    super.key,
    required this.fieldName,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    final examples = PhotoExampleService.getPhotoExamples(fieldName);
    
    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FieldPhotoExamplesScreen(
              fieldName: fieldName,
              fieldTitle: customTitle ?? PhotoExampleService.getFieldTitle(fieldName),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library,
              size: 14,
              color: Colors.blue[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Contoh',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoExampleTooltip extends StatelessWidget {
  final String fieldName;
  final Widget child;

  const PhotoExampleTooltip({
    super.key,
    required this.fieldName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final examples = PhotoExampleService.getPhotoExamples(fieldName);
    
    if (examples.isEmpty) {
      return child;
    }

    return Tooltip(
      message: 'Tap untuk melihat contoh foto',
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FieldPhotoExamplesScreen(
                fieldName: fieldName,
                fieldTitle: PhotoExampleService.getFieldTitle(fieldName),
              ),
            ),
          );
        },
        child: child,
      ),
    );
  }
}
