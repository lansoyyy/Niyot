import 'package:flutter/material.dart';

/// Icon button widget with consistent styling
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = AppIconButtonSize.medium,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final bool disabled;

  double get _iconSize {
    switch (size) {
      case AppIconButtonSize.small:
        return 16;
      case AppIconButtonSize.medium:
        return 24;
      case AppIconButtonSize.large:
        return 32;
    }
  }

  double get _buttonSize {
    switch (size) {
      case AppIconButtonSize.small:
        return 32;
      case AppIconButtonSize.medium:
        return 40;
      case AppIconButtonSize.large:
        return 48;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.iconTheme.color;
    final effectiveBackgroundColor = backgroundColor ?? Colors.transparent;

    final button = Container(
      width: _buttonSize,
      height: _buttonSize,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: _iconSize),
        color: effectiveColor,
        onPressed: disabled ? null : onPressed,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: _buttonSize,
          minHeight: _buttonSize,
        ),
        tooltip: tooltip,
      ),
    );

    return button;
  }
}

enum AppIconButtonSize { small, medium, large }
