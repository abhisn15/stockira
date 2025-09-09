import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get prefixApi => dotenv.env['PREFIX_API'] ?? '';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? '';
  
  static String get apiBaseUrl => '$baseUrl/$prefixApi/$apiVersion';
  
  static String get loginUrl => '$apiBaseUrl/login';
}
