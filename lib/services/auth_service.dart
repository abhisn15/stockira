import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login method
  static Future<LoginResponse> login(String emailOrUsername, String password, {bool rememberMe = false, String? appVersion, String? appDevice}) async {
    try {
      final response = await http.post(
        Uri.parse(Env.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email_or_username': emailOrUsername,
          'password': password,
          'remember_me': rememberMe ? 1 : 0,
          'app_version': appVersion ?? 'DEVICE 1',
          'app_device': appDevice ?? 'VERSION 1',
        }),
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
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
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
