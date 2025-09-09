import 'package:flutter/material.dart';
import 'package:stockira/screens/dashboard/index.dart';
import 'package:stockira/screens/url_setting/index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockira/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Remember me
  bool _rememberMe = false;

  // URL status
  String? _apiUrl;
  bool _isUrlLoading = true;

  // Device info
  String? _appVersion;
  String? _platform;

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
    _loadRememberMe();
    _loadDeviceInfo();
  }

  Future<void> _loadApiUrl() async {
    setState(() {
      _isUrlLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('api_url') ?? 'https://';
    setState(() {
      _apiUrl = url;
      _isUrlLoading = false;
    });
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    final savedEmail = prefs.getString('remembered_email') ?? '';
    setState(() {
      _rememberMe = remember;
      if (remember && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    });
  }

  Future<void> _loadDeviceInfo() async {
    String? version;
    String? platform;
    
    // Get app version
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      print('App version loaded: $version');
    } catch (e) {
      print('Error loading app version: $e');
      version = '1.0.0';
    }
    
    // Get platform info
    if (Platform.isAndroid) {
      platform = 'Android';
    } else if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = Platform.operatingSystem;
    }
    
    print('Platform: $platform'); // Debug log
    
    setState(() {
      _appVersion = version;
      _platform = platform;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Get app version and device info
      String appVersion = _appVersion ?? '';
      String appDevice = _platform ?? '';
      
      // If app version is still empty, try to get it again
      if (appVersion.isEmpty) {
        try {
          final info = await PackageInfo.fromPlatform();
          appVersion = info.version;
        } catch (_) {
          appVersion = '1.0.0'; // Fallback version
        }
      }
      
      // If app device is still empty, get platform info
      if (appDevice.isEmpty) {
        if (Platform.isAndroid) {
          appDevice = 'Android';
        } else if (Platform.isIOS) {
          appDevice = 'iOS';
        } else {
          appDevice = Platform.operatingSystem;
        }
      }

      // Debug log for login request
      print('Login request - App Version: $appVersion, App Device: $appDevice');

      // Save remember me state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
      } else {
        await prefs.remove('remembered_email');
      }

      // Kirim data login sesuai permintaan
      final response = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
        appVersion: appVersion,
        appDevice: appDevice,
      );

      if (response.success) {
        // Login successful
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await Future.delayed(const Duration(seconds: 1));
    // Dummy: always success
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text(
          'Fitur lupa password belum tersedia pada versi demo ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _goToUrlSetting() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UrlSettingScreen()));
    // Refresh URL status after returning
    _loadApiUrl();
  }

  @override
  Widget build(BuildContext context) {
    final theme = const Color.fromARGB(255, 41, 189, 206);
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade100.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.transparent,
                      child: Image.asset('assets/logo/logo.png'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome to Stockira',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: theme,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login to continue',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error,
                              color: Color.fromARGB(255, 41, 189, 206),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 41, 189, 206),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email or Username',
                              prefixIcon: const Icon(Icons.email_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email/Username wajib diisi';
                              }
                              // Email or username, so allow non-email
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: _isLoading
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _rememberMe = val ?? false;
                                        });
                                      },
                                activeColor: theme,
                              ),
                              const Expanded(
                                child: Text(
                                  'Remember me',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _forgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: theme,
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 17),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.red.shade200,
                                  thickness: 1,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.red.shade200,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _loginWithGoogle,
                              icon: const Icon(
                                Icons.account_circle,
                                color: Color.fromARGB(255, 41, 189, 206),
                              ),
                              label: const Text(
                                'Login with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 41, 189, 206),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                foregroundColor: theme,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // URL status and setting button
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.black, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _isUrlLoading
                          ? const Text(
                              'Memuat URL...',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            )
                          : Text(
                              '${_apiUrl ?? "-"}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _goToUrlSetting,
                      icon: const Icon(
                        Icons.settings,
                        size: 18,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Setting URL',
                        style: TextStyle(
                          color: Color.fromARGB(255, 41, 172, 187),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Color.fromARGB(255, 41, 189, 206),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
