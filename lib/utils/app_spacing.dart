import 'package:flutter/material.dart';

/// App Spacing - Centralized spacing constants for consistent padding and margins
class AppSpacing {
  AppSpacing._();

  // Extra Small Spacing
  static const double xs = 4.0;
  static const SizedBox xsH = SizedBox(height: xs);
  static const SizedBox xsW = SizedBox(width: xs);

  // Small Spacing
  static const double sm = 8.0;
  static const SizedBox smH = SizedBox(height: sm);
  static const SizedBox smW = SizedBox(width: sm);

  // Medium Spacing
  static const double md = 16.0;
  static const SizedBox mdH = SizedBox(height: md);
  static const SizedBox mdW = SizedBox(width: md);

  // Large Spacing
  static const double lg = 24.0;
  static const SizedBox lgH = SizedBox(height: lg);
  static const SizedBox lgW = SizedBox(width: lg);

  // Extra Large Spacing
  static const double xl = 32.0;
  static const SizedBox xlH = SizedBox(height: xl);
  static const SizedBox xlW = SizedBox(width: xl);

  // 2X Extra Large Spacing
  static const double xxl = 48.0;
  static const SizedBox xxlH = SizedBox(height: xxl);
  static const SizedBox xxlW = SizedBox(width: xxl);

  // 3X Extra Large Spacing
  static const double xxxl = 64.0;
  static const SizedBox xxxlH = SizedBox(height: xxxl);
  static const SizedBox xxxlW = SizedBox(width: xxxl);

  // Edge Insets
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  // Horizontal Padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical Padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);

  // Symmetric Padding
  static const EdgeInsets symmetricSm = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: sm,
  );
  static const EdgeInsets symmetricMd = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );
  static const EdgeInsets symmetricLg = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );
  static const EdgeInsets symmetricXl = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: xl,
  );

  // Edge Insets Only
  static const EdgeInsets onlyTopSm = EdgeInsets.only(top: sm);
  static const EdgeInsets onlyTopMd = EdgeInsets.only(top: md);
  static const EdgeInsets onlyTopLg = EdgeInsets.only(top: lg);
  static const EdgeInsets onlyBottomSm = EdgeInsets.only(bottom: sm);
  static const EdgeInsets onlyBottomMd = EdgeInsets.only(bottom: md);
  static const EdgeInsets onlyBottomLg = EdgeInsets.only(bottom: lg);
  static const EdgeInsets onlyLeftSm = EdgeInsets.only(left: sm);
  static const EdgeInsets onlyLeftMd = EdgeInsets.only(left: md);
  static const EdgeInsets onlyRightSm = EdgeInsets.only(right: sm);
  static const EdgeInsets onlyRightMd = EdgeInsets.only(right: md);

  // Border Radius
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(xxl));
}
