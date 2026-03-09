import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Body text widgets for displaying content text
class AppBodyText extends StatelessWidget {
  const AppBodyText(
    this.text, {
    super.key,
    this.size = AppBodySize.medium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    this.decoration,
    this.height,
    this.letterSpacing,
  });

  final String text;
  final AppBodySize size;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final TextDecoration? decoration;
  final double? height;
  final double? letterSpacing;

  TextStyle get _textStyle {
    switch (size) {
      case AppBodySize.large:
        return AppTextStyles.bodyLarge;
      case AppBodySize.medium:
        return AppTextStyles.bodyMedium;
      case AppBodySize.small:
        return AppTextStyles.bodySmall;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _textStyle.copyWith(
        color: color,
        fontWeight: fontWeight,
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

enum AppBodySize { large, medium, small }
