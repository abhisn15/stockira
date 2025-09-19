import 'package:flutter/material.dart';
import '../services/photo_example_service.dart';
import '../screens/photo_examples/field_examples.dart';

class PhotoExamplePreview extends StatelessWidget {
  final String fieldName;
  final String? customTitle;
  final bool showTitle;
  final bool showDescription;
  final int maxExamples;

  const PhotoExamplePreview({
    super.key,
    required this.fieldName,
    this.customTitle,
    this.showTitle = true,
    this.showDescription = true,
    this.maxExamples = 3,
  });

  @override
  Widget build(BuildContext context) {
    final examples = PhotoExampleService.getPhotoExamples(fieldName);
    
    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayExamples = examples.take(maxExamples).toList();
    final title = customTitle ?? PhotoExampleService.getFieldTitle(fieldName);
    final description = PhotoExampleService.getFieldDescription(fieldName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.photo_library,
                size: 16,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  showTitle ? title : 'Contoh Foto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FieldPhotoExamplesScreen(
                        fieldName: fieldName,
                        fieldTitle: title,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
          
          // Description
          if (showDescription && description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                height: 1.3,
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Example images
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayExamples.length,
              itemBuilder: (context, index) {
                final example = displayExamples[index];
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FieldPhotoExamplesScreen(
                            fieldName: fieldName,
                            fieldTitle: title,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        example.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoExampleInline extends StatelessWidget {
  final String fieldName;
  final String? customTitle;
  final bool showDescription;

  const PhotoExampleInline({
    super.key,
    required this.fieldName,
    this.customTitle,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    final examples = PhotoExampleService.getPhotoExamples(fieldName);
    
    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = customTitle ?? PhotoExampleService.getFieldTitle(fieldName);
    final description = PhotoExampleService.getFieldDescription(fieldName);
    final firstExample = examples.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Example image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                firstExample.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showDescription && description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // View button
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FieldPhotoExamplesScreen(
                    fieldName: fieldName,
                    fieldTitle: title,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lihat',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
