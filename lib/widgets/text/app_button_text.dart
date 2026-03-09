import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Button text widgets for displaying button labels
class AppButtonText extends StatelessWidget {
  const AppButtonText(
    this.text, {
    super.key,
    this.size = AppButtonSize.medium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.decoration,
    this.height,
    this.letterSpacing,
  });

  final String text;
  final AppButtonSize size;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;
  final double? height;
  final double? letterSpacing;

  TextStyle get _textStyle {
    switch (size) {
      case AppButtonSize.large:
        return AppTextStyles.buttonText;
      case AppButtonSize.medium:
        return AppTextStyles.buttonTextSmall;
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

enum AppButtonSize { large, medium }
