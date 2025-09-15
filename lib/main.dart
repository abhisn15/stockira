import 'package:flutter/material.dart';
import 'package:stockira/screens/url_setting/index.dart';
import 'package:stockira/screens/auth/index.dart';
import 'package:stockira/screens/dashboard/index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockira/services/auth_service.dart';
import 'package:stockira/services/theme_service.dart';
import 'package:stockira/services/language_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _currentTheme = ThemeService.lightTheme;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    await LanguageService.initialize();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getCurrentTheme();
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockira',
      theme: _currentTheme,
      home: AuthWrapper(
        onThemeChanged: _loadTheme,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  
  const AuthWrapper({super.key, this.onThemeChanged});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _apiUrl;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final apiUrl = prefs.getString('api_url');
    
    setState(() {
      _apiUrl = apiUrl;
    });

    // If no API URL is set, go to URL setting
    if (apiUrl == null || apiUrl.isEmpty || apiUrl == 'https://') {
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
      return;
    }

    // Check if user is logged in
    final isLoggedIn = await AuthService.isLoggedIn();
    setState(() {
      _isLoading = false;
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If no API URL is configured, show URL setting screen
    if (_apiUrl == null || _apiUrl!.isEmpty || _apiUrl == 'https://') {
      return const UrlSettingScreen();
    }

    // If logged in, show dashboard, otherwise show login
    return _isLoggedIn 
        ? DashboardScreen(onThemeChanged: widget.onThemeChanged) 
        : const AuthScreen();
  }
}