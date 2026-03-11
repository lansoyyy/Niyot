import 'package:flutter/material.dart';
import 'core/app_config.dart';
import 'screens/splash_screen.dart';

void main() {
  AppConfig.init(debugMode: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niyot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC62828),
          primary: const Color(0xFFC62828),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
