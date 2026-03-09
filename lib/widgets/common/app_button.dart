import 'package:flutter/material.dart';
import '../text/app_button_text.dart' as text_widgets;

/// Primary button widget
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.variant = AppButtonVariant.primary,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
    this.disabled = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final AppButtonVariant variant;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? icon;
  final AppButtonIconPosition iconPosition;
  final bool disabled;

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }

  double get _borderRadius {
    switch (size) {
      case AppButtonSize.small:
        return 8;
      case AppButtonSize.medium:
      case AppButtonSize.large:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = variant == AppButtonVariant.primary
        ? theme.colorScheme.primary
        : variant == AppButtonVariant.secondary
        ? Colors.white
        : Colors.transparent;
    final effectiveTextColor = variant == AppButtonVariant.primary
        ? Colors.white
        : theme.colorScheme.primary;
    final effectiveBorderColor = variant == AppButtonVariant.secondary
        ? theme.colorScheme.primary
        : Colors.transparent;

    final button = SizedBox(
      height: _height,
      child: ElevatedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            side: BorderSide(color: effectiveBorderColor, width: 1.5),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    variant == AppButtonVariant.primary
                        ? Colors.white
                        : theme.colorScheme.primary,
                  ),
                ),
              )
            : _buildContent(),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildContent() {
    final buttonTextSize = size == AppButtonSize.small
        ? text_widgets.AppButtonSize.medium
        : text_widgets.AppButtonSize.large;

    final textWidget = text_widgets.AppButtonText(
      text,
      size: buttonTextSize,
      color: null, // Use button's foreground color
    );

    if (icon == null) return textWidget;

    final iconWidget = Icon(icon, size: size == AppButtonSize.small ? 16 : 20);

    if (iconPosition == AppButtonIconPosition.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [iconWidget, const SizedBox(width: 8), textWidget],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [textWidget, const SizedBox(width: 8), iconWidget],
      );
    }
  }
}

enum AppButtonSize { small, medium, large }

enum AppButtonVariant { primary, secondary, tertiary }

enum AppButtonIconPosition { left, right }
