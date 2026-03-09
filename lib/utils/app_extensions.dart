import 'package:flutter/material.dart';

/// App Extensions - Extension methods for commonly used types
class AppExtensions {
  AppExtensions._();
}

// Extension on BuildContext for easy access to theme and media query
extension BuildContextExtensions on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Media Query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get paddingTop => MediaQuery.paddingOf(this).top;
  double get paddingBottom => MediaQuery.paddingOf(this).bottom;
  double get paddingLeft => MediaQuery.paddingOf(this).left;
  double get paddingRight => MediaQuery.paddingOf(this).right;
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  // Responsive
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;

  // Focus Scope
  void unfocus() => FocusScope.of(this).unfocus();

  // Navigator
  Future<T?> push<T>(Route<T> route) => Navigator.push(this, route);
  void pop<T>([T? result]) => Navigator.pop(this, result);
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.pushNamed(this, routeName, arguments: arguments);
  Future<T?> pushReplacementNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.pushReplacementNamed(this, routeName, arguments: arguments);
  void popUntil(String routeName) =>
      Navigator.popUntil(this, ModalRoute.withName(routeName));
}

// Extension on double for responsive sizing
extension DoubleExtensions on double {
  double responsive(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return this * (screenWidth / 375); // 375 is the base width (iPhone SE)
  }

  SizedBox get height => SizedBox(height: this);
  SizedBox get width => SizedBox(width: this);
}

// Extension on int for responsive sizing
extension IntExtensions on int {
  double responsive(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return toDouble() * (screenWidth / 375);
  }

  SizedBox get height => SizedBox(height: toDouble());
  SizedBox get width => SizedBox(width: toDouble());
}

// Extension on String for validation
extension StringExtensions on String {
  bool get isEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  bool get isPhone => RegExp(r'^[0-9]{10,15}$').hasMatch(this);
  bool get isUrl => RegExp(r'^https?:\/\/').hasMatch(this);
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);
  bool get isAlphabetic => RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String capitalizeAllWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

// Extension on Color for lightening and darkening
extension ColorExtensions on Color {
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color withOpacity(double opacity) {
    return withValues(alpha: opacity);
  }
}

// Extension on List for safe operations
extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
