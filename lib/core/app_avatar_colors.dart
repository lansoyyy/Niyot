import 'package:flutter/material.dart';

/// Unified profile / header colors (replaces per-user gradient backgrounds).
class AppAvatarColors {
  AppAvatarColors._();

  /// Banners, card headers, and large profile areas (solid maroon from app red family).
  static const Color profileHeaderBackground = Color(0xFF6B0000);

  /// Placeholder disc behind initials when no photo (light pink from app palette).
  static const Color placeholderFill = Color(0xFFFFEBEE);

  /// Initials on the placeholder disc.
  static const Color placeholderText = Color(0xFF6B0000);
}
