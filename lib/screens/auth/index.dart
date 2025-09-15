import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import 'package:flutter/services.dart';
import 'package:stockira/screens/dashboard/index.dart';
import 'package:stockira/screens/url_setting/index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockira/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum AuthView { login, forgotEmail, verifyPin, resetPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _pinController = TextEditingController();
  final _resetPasswordController = TextEditingController();
  final _resetPasswordConfirmController = TextEditingController();
  final _pinFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureResetPassword = true;
  bool _obscureResetPasswordConfirm = true;
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

  // Auth flow state
  AuthView _authView = AuthView.login;
  String? _forgotEmail; // for pin/verify/reset
  String? _baseUrl;
  String _prefixApi = "api";
  String _apiVersion = "v1";

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
    _loadApiUrl();
    _loadRememberMe();
    _loadDeviceInfo();
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');
    // You can add more checks here if needed (e.g., token, expiry, etc.)
    if (userEmail != null && userEmail.isNotEmpty) {
      // Already logged in, go to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    }
  }

  Future<void> _loadApiUrl() async {
    setState(() {
      _isUrlLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('api_url') ?? 'https://';
    setState(() {
      _apiUrl = url;
      _baseUrl = url.replaceAll(RegExp(r'/$'), ''); // remove trailing slash
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

  void _toggleResetPasswordVisibility() {
    setState(() {
      _obscureResetPassword = !_obscureResetPassword;
    });
  }

  void _toggleResetPasswordConfirmVisibility() {
    setState(() {
      _obscureResetPasswordConfirm = !_obscureResetPasswordConfirm;
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
        // Try to use secure storage, fallback to SharedPreferences if it fails
        try {
          const storage = FlutterSecureStorage();
          await storage.write(
            key: 'remembered_password',
            value: _passwordController.text,
          );
        } catch (e) {
          print('Secure storage not available, using SharedPreferences: $e');
          // Fallback to SharedPreferences (less secure but functional)
          await prefs.setString(
            'remembered_password',
            _passwordController.text,
          );
        }
      } else {
        await prefs.remove('remembered_email');
        try {
          const storage = FlutterSecureStorage();
          await storage.delete(key: 'remembered_password');
        } catch (e) {
          print(
            'Secure storage not available, removing from SharedPreferences: $e',
          );
          await prefs.remove('remembered_password');
        }
      }

      // Kirim data login sesuai permintaan
      final loginResponse = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
        appVersion: appVersion,
        appDevice: appDevice,
      );

      if (loginResponse.success) {
        print('Login successful, token: ${loginResponse.data.token}');
        
        // Setelah login sukses, panggil API profile untuk mendapatkan data user yang lebih lengkap
        final profileResponse = await AuthService.getProfile(
          _emailController.text.trim(),
          _passwordController.text,
          rememberMe: _rememberMe,
        );

        if (profileResponse.success) {
          // Simpan data user yang lebih lengkap ke SharedPreferences
          final user = profileResponse.data.user;
          print('Profile data: $user');
          await prefs.setString('user_name', user.name);
          await prefs.setString('user_email', user.email);
          await prefs.setString('user_profile', user.photoUrl ?? '');
          await prefs.setString('user_employee_id', user.employee?.code ?? '');
          await prefs.setString(
            'user_position',
            user.employee?.position?.name ?? '',
          );

          print('User data saved: ${user.name}, ${user.email}');
        } else {
          print(
            'Profile API failed, using login data: ${profileResponse.message}',
          );
          // Fallback to login data if profile fails
          final user = loginResponse.data.user;
          await prefs.setString('user_name', user.name);
          await prefs.setString('user_email', user.email);
          await prefs.setString('user_profile', user.photoUrl ?? '');
          await prefs.setString('user_employee_id', user.employee?.code ?? '');
          await prefs.setString(
            'user_position',
            user.employee?.position?.name ?? '',
          );
        }

        // Login successful
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = loginResponse.message;
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

  // --- Forgot Password Flow ---

  Future<void> _submitForgotEmail() async {
    if (_forgotEmailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Email wajib diisi";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = '$_baseUrl/$_prefixApi/$_apiVersion/forgot-password';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _forgotEmailController.text.trim()}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['success'] ?? false)) {
        setState(() {
          _forgotEmail = _forgotEmailController.text.trim();
          _authView = AuthView.verifyPin;
          _isLoading = false;
          _pinController.clear();
        });
      } else {
        setState(() {
          _errorMessage =
              data['message'] ?? 'Gagal mengirim email reset password';
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

  Future<void> _submitVerifyPin() async {
    if (_pinController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "PIN wajib diisi";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = '$_baseUrl/$_prefixApi/$_apiVersion/verify-pin';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _forgotEmail,
          'pin': _pinController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['success'] ?? false)) {
        setState(() {
          _authView = AuthView.resetPassword;
          _isLoading = false;
          _resetPasswordController.clear();
          _resetPasswordConfirmController.clear();
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'PIN salah atau tidak valid';
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

  Future<void> _submitResetPassword() async {
    if (_resetPasswordController.text.isEmpty ||
        _resetPasswordConfirmController.text.isEmpty) {
      setState(() {
        _errorMessage = "Password dan konfirmasi wajib diisi";
      });
      return;
    }
    if (_resetPasswordController.text != _resetPasswordConfirmController.text) {
      setState(() {
        _errorMessage = "Password dan konfirmasi tidak sama";
      });
      return;
    }
    if (_resetPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = "Password minimal 6 karakter";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = '$_baseUrl/$_prefixApi/$_apiVersion/reset-password';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _forgotEmail,
          'password': _resetPasswordController.text,
          'password_confirmation': _resetPasswordConfirmController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['success'] ?? false)) {
        // Success, back to login
        setState(() {
          _authView = AuthView.login;
          _isLoading = false;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageService.passwordResetSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Gagal reset password';
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

  void _goToForgotPassword() {
    setState(() {
      _authView = AuthView.forgotEmail;
      _errorMessage = null;
      _forgotEmailController.clear();
      _pinController.clear();
      _resetPasswordController.clear();
      _resetPasswordConfirmController.clear();
    });
  }

  void _backToLogin() {
    setState(() {
      _authView = AuthView.login;
      _errorMessage = null;
      _forgotEmailController.clear();
      _pinController.clear();
      _resetPasswordController.clear();
      _resetPasswordConfirmController.clear();
    });
  }

  void _goToUrlSetting() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UrlSettingScreen()));
    // Refresh URL status after returning
    _loadApiUrl();
  }

  Widget _buildLoginForm(Color theme) {
    return Form(
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
                child: Text('Remember me', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
          Container(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _goToForgotPassword,
              style: TextButton.styleFrom(foregroundColor: theme),
              child: Text(LanguageService.forgotPassword),
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
                  : const Text('Sign In', style: TextStyle(fontSize: 17)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Divider(color: Colors.red.shade200, thickness: 1),
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
                child: Divider(color: Colors.red.shade200, thickness: 1),
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
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: theme,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotEmailForm(Color theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Lupa Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan email Anda untuk menerima kode verifikasi.',
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _forgotEmailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForgotEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
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
                    'Kirim Kode Verifikasi',
                    style: TextStyle(fontSize: 17),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _isLoading ? null : _backToLogin,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(LanguageService.backToLogin),
          style: TextButton.styleFrom(foregroundColor: theme),
        ),
      ],
    );
  }

  Widget _buildPinInput(Color theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          width: 40,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            _pinController.text.length > i ? _pinController.text[i] : '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyPinForm(Color theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Verifikasi PIN',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan kode verifikasi yang dikirim ke email ${_forgotEmail ?? ""}',
          style: const TextStyle(fontSize: 15, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 40,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _pinController.text.length > i ? _pinController.text[i] : '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                );
              }),
            ),
            // Agar TextField tetap bisa menerima input, gunakan GestureDetector agar tap pada kotak PIN memfokuskan TextField
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusScope.of(context).requestFocus(_pinFocusNode);
                },
                child: IgnorePointer(
                  ignoring: false,
                  child: Opacity(
                    opacity: 0.0,
                    child: SizedBox(
                      width: 280,
                      child: TextField(
                        focusNode: _pinFocusNode,
                        controller: _pinController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 1.0,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (value.length == 6) {
                            _submitVerifyPin();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitVerifyPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
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
                : const Text('Verifikasi', style: TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _isLoading ? null : _backToLogin,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(LanguageService.backToLogin),
          style: TextButton.styleFrom(foregroundColor: theme),
        ),
      ],
    );
  }

  Widget _buildResetPasswordForm(Color theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan password baru untuk email ${_forgotEmail ?? ""}',
          style: const TextStyle(fontSize: 15, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _resetPasswordController,
          enabled: !_isLoading,
          obscureText: _obscureResetPassword,
          decoration: InputDecoration(
            labelText: 'Password Baru',
            prefixIcon: const Icon(Icons.lock_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureResetPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey,
              ),
              onPressed: _toggleResetPasswordVisibility,
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _resetPasswordConfirmController,
          enabled: !_isLoading,
          obscureText: _obscureResetPasswordConfirm,
          decoration: InputDecoration(
            labelText: 'Konfirmasi Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureResetPasswordConfirm
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey,
              ),
              onPressed: _toggleResetPasswordConfirmVisibility,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
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
                : const Text('Reset Password', style: TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _isLoading ? null : _backToLogin,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(LanguageService.backToLogin),
          style: TextButton.styleFrom(foregroundColor: theme),
        ),
      ],
    );
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
                    if (_authView == AuthView.login)
                      Text(
                        'Welcome to Stockira',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: theme,
                        ),
                      ),
                    if (_authView == AuthView.login) const SizedBox(height: 8),
                    if (_authView == AuthView.login)
                      const Text(
                        'Login to continue',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    if (_authView == AuthView.login) const SizedBox(height: 28),
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _authView == AuthView.login
                          ? _buildLoginForm(theme)
                          : _authView == AuthView.forgotEmail
                          ? _buildForgotEmailForm(theme)
                          : _authView == AuthView.verifyPin
                          ? _buildVerifyPinForm(theme)
                          : _buildResetPasswordForm(theme),
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
