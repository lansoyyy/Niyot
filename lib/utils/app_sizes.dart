import 'package:flutter/material.dart';

/// App Sizes - Centralized size constants for consistent dimensions
class AppSizes {
  AppSizes._();

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusXxxl = 32.0;
  static const double radiusFull = 999.0;

  // Icon Sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 48.0;

  // Button Heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;

  // Input Field Heights
  static const double inputHeightSm = 40.0;
  static const double inputHeightMd = 48.0;
  static const double inputHeightLg = 56.0;

  // Avatar Sizes
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 64.0;
  static const double avatarXxl = 80.0;

  // Card Elevation
  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;
  static const double elevationXxl = 16.0;

  // Stroke Width
  static const double strokeWidthThin = 1.0;
  static const double strokeWidthNormal = 1.5;
  static const double strokeWidthThick = 2.0;
  static const double strokeWidthExtraThick = 3.0;

  // Divider Height
  static const double dividerHeight = 1.0;

  // Screen Breakpoints (for responsive design)
  static const double breakpointSm = 576.0;
  static const double breakpointMd = 768.0;
  static const double breakpointLg = 992.0;
  static const double breakpointXl = 1200.0;
  static const double breakpointXxl = 1400.0;

  // Animation Durations
  static const int animationDurationFast = 150;
  static const int animationDurationNormal = 300;
  static const int animationDurationSlow = 500;

  // Border Radius Objects
  static BorderRadius get borderRadiusXs => BorderRadius.circular(radiusXs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);
  static BorderRadius get borderRadiusXxxl => BorderRadius.circular(radiusXxxl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // Circle Border Radius
  static BorderRadius get circleBorderRadius =>
      BorderRadius.circular(radiusFull);
}
