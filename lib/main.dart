import 'package:flutter/material.dart';
import 'package:sadata_app/screens/auth/index.dart';
import 'package:sadata_app/screens/url_setting/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aice App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UrlSettingScreen(),
    );
  }
}