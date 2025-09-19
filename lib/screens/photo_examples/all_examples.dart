import 'package:flutter/material.dart';
import '../../services/photo_example_service.dart';
import '../../widgets/photo_example_widget.dart';

class AllPhotoExamplesScreen extends StatelessWidget {
  const AllPhotoExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allExamples = PhotoExampleService.getAllPhotoExamples();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Semua Contoh Foto',
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
        actions: [
          IconButton(
            onPressed: () {
              _showSearchDialog(context);
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allExamples.length,
          itemBuilder: (context, index) {
            final entry = allExamples.entries.elementAt(index);
            final fieldName = entry.key;
            final examples = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: PhotoExampleList(
                examples: examples,
                title: PhotoExampleService.getFieldTitle(fieldName),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cari Contoh Foto'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Masukkan nama field...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.of(context).pop();
            _searchExamples(context, query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _searchExamples(BuildContext context, String query) {
    final allExamples = PhotoExampleService.getAllPhotoExamples();
    final filteredExamples = allExamples.entries.where((entry) {
      final fieldName = entry.key.toLowerCase();
      final fieldTitle = PhotoExampleService.getFieldTitle(entry.key).toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return fieldName.contains(searchQuery) || fieldTitle.contains(searchQuery);
    }).toList();

    if (filteredExamples.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak ditemukan contoh foto untuk "$query"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: query,
          results: filteredExamples,
        ),
      ),
    );
  }
}

class SearchResultsScreen extends StatelessWidget {
  final String query;
  final List<MapEntry<String, List<PhotoExample>>> results;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hasil Pencarian: "$query"',
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final entry = results[index];
            final fieldName = entry.key;
            final examples = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: PhotoExampleList(
                examples: examples,
                title: PhotoExampleService.getFieldTitle(fieldName),
              ),
            );
          },
        ),
      ),
    );
  }
}
