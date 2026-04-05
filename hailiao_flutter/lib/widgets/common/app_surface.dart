import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.showBorder = false,
    this.boxShadow = CommonTokens.shadowNone,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool showBorder;
  final List<BoxShadow> boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? CommonTokens.cardBackground,
        borderRadius: BorderRadius.circular(
          borderRadius ?? CommonTokens.radiusLg,
        ),
        border: showBorder
            ? Border.all(color: CommonTokens.dividerColor)
            : null,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
