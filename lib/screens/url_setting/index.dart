import 'package:flutter/material.dart';
import 'package:sadata_app/screens/auth/index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class UrlSettingScreen extends StatefulWidget {
  const UrlSettingScreen({super.key});

  @override
  State<UrlSettingScreen> createState() => _UrlSettingScreenState();
}

class _UrlSettingScreenState extends State<UrlSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  MobileScannerController? _scannerController;
  bool _isScanning = true;

  // Dummy validation data
  final List<String> _validUrls = [
    'https://api.example.com',
    'https://api.sadata.com',
    'https://api.company.com',
    'https://api.test.com',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
    _scannerController = MobileScannerController();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_url') ?? 'https://';
    setState(() {
      _urlController.text = savedUrl;
    });
  }

  Future<void> _saveUrl() async {
    if (_formKey.currentState!.validate()) {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi URL'),
          content: Text('Gunakan URL berikut?\n\n${_urlController.text}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Gunakan'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          _isLoading = true;
        });

        await Future.delayed(const Duration(seconds: 1));

        if (_validateUrl(_urlController.text)) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('api_url', _urlController.text);

          if (mounted) {
            // Show success dialog
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Berhasil'),
                content: const Text('URL berhasil disimpan!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            // Show error dialog
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('URL Tidak Valid'),
                content: const Text('URL tidak valid. Silakan cek dan coba lagi.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateUrl(String url) {
    if (!url.startsWith('https://') && !url.startsWith('http://')) {
      return false;
    }
    // Bisa diubah ke _validUrls.contains(url) jika ingin validasi ketat
    return true;
  }

  String? _validateUrlField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Masukkan URL';
    }
    if (!value.startsWith('https://') && !value.startsWith('http://')) {
      return 'URL harus diawali dengan https:// atau http://';
    }
    if (value.length < 10) {
      return 'URL terlalu pendek';
    }
    return null;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  // QR code scan result handler
  void _onQRViewResult(String? scannedUrl) {
    if (scannedUrl != null && scannedUrl.isNotEmpty && _isScanning) {
      setState(() {
        _isScanning = false;
        _urlController.text = scannedUrl;
      });

      // Validate the scanned URL
      if (_isValidUrl(scannedUrl)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL terdeteksi: $scannedUrl'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Format URL tidak valid: $scannedUrl'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Reset scanning after showing error
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isScanning = true;
            });
          }
        });
      }
    }
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // No AppBar, only camera scan and form
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera background
          MobileScanner(
            controller: _scannerController,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty && _isScanning) {
                  _onQRViewResult(barcode.rawValue);
                  break; // Only process the first valid barcode
                }
              }
            },
          ),

          // Scanning area overlay
          if (_isScanning)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Column(
                children: [
                  const Spacer(),
                  // Top overlay
                  Container(height: 100, color: Colors.black.withOpacity(0.5)),
                  // Middle section with scanning area
                  Expanded(
                    child: Row(
                      children: [
                        // Left overlay
                        Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
                        // Scanning area
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              // Corner indicators
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.blue, width: 4),
                                      left: BorderSide(color: Colors.blue, width: 4),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.blue, width: 4),
                                      right: BorderSide(color: Colors.blue, width: 4),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.blue, width: 4),
                                      left: BorderSide(color: Colors.blue, width: 4),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.blue, width: 4),
                                      right: BorderSide(color: Colors.blue, width: 4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right overlay
                        Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  // Bottom overlay
                  Container(height: 100, color: Colors.black.withOpacity(0.5)),
                  const Spacer(),
                ],
              ),
            ),

          // Instructions
          if (_isScanning)
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'Arahkan QR code ke dalam kotak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Overlay for form
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      // URL input field
                      Expanded(
                        child: TextFormField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'API URL',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintText: 'https://api.example.com',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.link, color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          keyboardType: TextInputType.url,
                          validator: _validateUrlField,
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Submit button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Gunakan URL'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}