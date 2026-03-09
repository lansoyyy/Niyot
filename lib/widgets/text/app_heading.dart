import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Heading text widgets for displaying titles and headings
class AppHeading extends StatelessWidget {
  const AppHeading(
    this.text, {
    super.key,
    this.size = AppHeadingSize.medium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.decoration,
    this.height,
    this.letterSpacing,
  });

  final String text;
  final AppHeadingSize size;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;
  final double? height;
  final double? letterSpacing;

  TextStyle get _textStyle {
    switch (size) {
      case AppHeadingSize.displayLarge:
        return AppTextStyles.displayLarge;
      case AppHeadingSize.displayMedium:
        return AppTextStyles.displayMedium;
      case AppHeadingSize.displaySmall:
        return AppTextStyles.displaySmall;
      case AppHeadingSize.h1:
        return AppTextStyles.headlineLarge;
      case AppHeadingSize.h2:
        return AppTextStyles.headlineMedium;
      case AppHeadingSize.h3:
        return AppTextStyles.headlineSmall;
      case AppHeadingSize.large:
        return AppTextStyles.titleLarge;
      case AppHeadingSize.medium:
        return AppTextStyles.titleMedium;
      case AppHeadingSize.small:
        return AppTextStyles.titleSmall;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _textStyle.copyWith(
        color: color,
        decoration: decoration,
        height: height,
        letterSpacing: letterSpacing,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

enum AppHeadingSize {
  displayLarge,
  displayMedium,
  displaySmall,
  h1,
  h2,
  h3,
  large,
  medium,
  small,
}
