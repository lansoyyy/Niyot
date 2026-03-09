import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// App Config - Application configuration settings
class AppConfig {
  AppConfig._();

  static const String appName = AppConstants.appName;
  static const String appVersion = AppConstants.appVersion;

  static bool isDebugMode = false;

  static void init({bool debugMode = false}) {
    isDebugMode = debugMode;
  }

  static void log(String message) {
    if (isDebugMode) {
      debugPrint('[Niyot] $message');
    }
  }
}
