import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Label text widgets for displaying labels, captions, and small text
class AppLabelText extends StatelessWidget {
  const AppLabelText(
    this.text, {
    super.key,
    this.size = AppLabelSize.medium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.decoration,
    this.height,
    this.letterSpacing,
  });

  final String text;
  final AppLabelSize size;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;
  final double? height;
  final double? letterSpacing;

  TextStyle get _textStyle {
    switch (size) {
      case AppLabelSize.large:
        return AppTextStyles.labelLarge;
      case AppLabelSize.medium:
        return AppTextStyles.labelMedium;
      case AppLabelSize.small:
        return AppTextStyles.labelSmall;
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

enum AppLabelSize { large, medium, small }
