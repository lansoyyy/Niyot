import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

/// App Text Styles - Centralized text styles using Urbanist font family
class AppTextStyles {
  AppTextStyles._();

  // Font Family
  static const String fontFamily = AppAssets.fontUrbanist;

  // ==================== HEADING STYLES ====================

  // Display Styles - For large, impactful text
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 57,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 45,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 36,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Headline Styles - For section headers and page titles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Title Styles - For card titles and important labels
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // ==================== BODY STYLES ====================

  // Body Styles - For general text content
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  // ==================== LABEL STYLES ====================

  // Label Styles - For buttons, tags, and small labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // ==================== CUSTOM STYLES ====================

  // Button Text
  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  static const TextStyle buttonTextSmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.4,
    color: AppColors.textTertiary,
  );

  // Overline
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );

  // ==================== COLOR VARIANTS ====================

  // Primary Color Variants
  static TextStyle displayLargePrimary({Color color = AppColors.primary}) =>
      displayLarge.copyWith(color: color);

  static TextStyle headlineMediumPrimary({Color color = AppColors.primary}) =>
      headlineMedium.copyWith(color: color);

  static TextStyle bodyMediumPrimary({Color color = AppColors.primary}) =>
      bodyMedium.copyWith(color: color);

  // Secondary Color Variants
  static TextStyle displayLargeSecondary({Color color = AppColors.secondary}) =>
      displayLarge.copyWith(color: color);

  static TextStyle headlineMediumSecondary({
    Color color = AppColors.secondary,
  }) => headlineMedium.copyWith(color: color);

  static TextStyle bodyMediumSecondary({Color color = AppColors.secondary}) =>
      bodyMedium.copyWith(color: color);

  // Inverse Color Variants
  static TextStyle displayLargeInverse({Color color = AppColors.textInverse}) =>
      displayLarge.copyWith(color: color);

  static TextStyle headlineMediumInverse({
    Color color = AppColors.textInverse,
  }) => headlineMedium.copyWith(color: color);

  static TextStyle bodyMediumInverse({Color color = AppColors.textInverse}) =>
      bodyMedium.copyWith(color: color);

  // ==================== WEIGHT VARIANTS ====================

  // Bold Variants
  static TextStyle bodyBold() =>
      bodyLarge.copyWith(fontWeight: FontWeight.w700);
  static TextStyle bodyMediumBold() =>
      bodyMedium.copyWith(fontWeight: FontWeight.w700);
  static TextStyle bodySmallBold() =>
      bodySmall.copyWith(fontWeight: FontWeight.w700);

  // Medium Variants
  static TextStyle bodyMediumWeight() =>
      bodyLarge.copyWith(fontWeight: FontWeight.w500);
  static TextStyle bodyMediumMediumWeight() =>
      bodyMedium.copyWith(fontWeight: FontWeight.w500);
  static TextStyle bodySmallMediumWeight() =>
      bodySmall.copyWith(fontWeight: FontWeight.w500);
}
