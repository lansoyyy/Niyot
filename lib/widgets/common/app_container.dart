import 'package:flutter/material.dart';

/// Container widget with common properties
class AppContainer extends StatelessWidget {
  const AppContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.alignment,
    this.constraints,
    this.decoration,
    this.transform,
    this.clipBehavior,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final double? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final Decoration? decoration;
  final Matrix4? transform;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      color: decoration != null ? null : color,
      decoration:
          decoration ??
          BoxDecoration(
            color: color,
            borderRadius: borderRadius != null
                ? BorderRadius.circular(borderRadius!)
                : null,
            border: border,
            boxShadow: boxShadow,
          ),
      alignment: alignment,
      constraints: constraints,
      transform: transform,
      clipBehavior: clipBehavior ?? Clip.none,
      child: child,
    );
  }
}
