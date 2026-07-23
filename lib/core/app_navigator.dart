import 'package:flutter/material.dart';

/// Global navigator for notification taps and deep links.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static BuildContext? get context => key.currentContext;
}
