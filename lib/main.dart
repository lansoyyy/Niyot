import 'package:flutter/material.dart';
import 'core/app_export.dart';
import 'core/app_config.dart';

void main() {
  // Initialize app configuration
  AppConfig.init(debugMode: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppHeading(AppStrings.appName, size: AppHeadingSize.h3),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppAssetImage(assetPath: AppAssets.logo, width: 120, height: 120),
            AppSpacing.xlH,
            AppHeading('Welcome to Niyot', size: AppHeadingSize.h2),
            AppSpacing.mdH,
            AppBodyText(
              'Your Flutter app architecture is ready!',
              size: AppBodySize.medium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.xxlH,
            AppButton(text: 'Get Started', onPressed: () {}, isFullWidth: true),
          ],
        ),
      ),
    );
  }
}
