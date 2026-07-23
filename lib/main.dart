import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:niyot/firebase_options.dart';
import 'core/app_config.dart';
import 'core/app_navigator.dart';
import 'screens/splash_screen.dart';
import 'services/local_notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be initialized before any Firebase services.
  await Firebase.initializeApp(
    name: 'niyot-17d88',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppConfig.init(debugMode: true);
  await LocalNotificationHelper.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niyot',
      navigatorKey: AppNavigator.key,
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
