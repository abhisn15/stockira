import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../models/user.dart';
import 'http_client_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login method
  static Future<LoginResponse> login(String emailOrUsername, String password, {bool rememberMe = false, String? appVersion, String? appDevice}) async {
    try {
      final response = await HttpClientService.post(
        Uri.parse(Env.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: {
          'email_or_username': emailOrUsername,
          'password': password,
          'remember_me': rememberMe ? 1 : 0,
          'app_version': appVersion ?? 'DEVICE 1',
          'app_device': appDevice ?? 'VERSION 1',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(responseData);
        
        if (loginResponse.success) {
          // Store token and user data
          await _storeAuthData(loginResponse.data);
        }
        
        return loginResponse;
      } else {
        // Handle error response
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return LoginResponse(
          success: false,
          message: errorData['message'] ?? 'Login failed',
          data: LoginData(
            token: '',
            type: '',
            expiresAt: '',
            user: User(
              id: 0,
              name: '',
              email: '',
              isActive: 0,
              createdAt: '',
              updatedAt: '',
              roles: [],
            ),
          ),
        );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: LoginData(
          token: '',
          type: '',
          expiresAt: '',
          user: User(
            id: 0,
            name: '',
            email: '',
            isActive: 0,
            createdAt: '',
            updatedAt: '',
            roles: [],
          ),
        ),
      );
    }
  }

  // Store authentication data
  static Future<void> _storeAuthData(LoginData loginData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, loginData.token);
    await prefs.setString(_userKey, jsonEncode(loginData.user.toJson()));
    print('Token stored: ${loginData.token}'); // Debug log
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Token retrieved: $token'); // Debug log
    return token;
  }

  // Get stored user data
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      return User.fromJson(userData);
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Logout method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Logout API call
  static Future<bool> logoutApi() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        print('No token available for logout API');
        return false;
      }

      final response = await HttpClientService.post(
        Uri.parse('${Env.apiBaseUrl}/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error calling logout API: $e');
      return false;
    }
  }

  // Get user profile from API
  static Future<LoginResponse> getProfile(String emailOrUsername, String password, {bool rememberMe = false}) async {
    try {
      // Get the token from login response
      final token = await getToken();
      
      final response = await HttpClientService.post(
        Uri.parse(Env.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: {
          'email_or_username': emailOrUsername,
          'password': password,
          'remember_me': rememberMe ? 1 : 0,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(responseData);
        
        if (loginResponse.success) {
          // Update stored user data with fresh profile data
          await _storeAuthData(loginResponse.data);
        }
        
        return loginResponse;
      } else {
        // Handle error response
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return LoginResponse(
          success: false,
          message: errorData['message'] ?? 'Profile fetch failed',
          data: LoginData(
            token: '',
            type: '',
            expiresAt: '',
            user: User(
              id: 0,
              name: '',
              email: '',
              isActive: 0,
              createdAt: '',
              updatedAt: '',
              roles: [],
            ),
          ),
        );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: LoginData(
          token: '',
          type: '',
          expiresAt: '',
          user: User(
            id: 0,
            name: '',
            email: '',
            isActive: 0,
            createdAt: '',
            updatedAt: '',
            roles: [],
          ),
        ),
      );
    }
  }

  // Get authorization header
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
