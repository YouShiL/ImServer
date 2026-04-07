import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

/// 白底分组容器（灰底页上的微信式列表块），无阴影、细边框、小圆角。
class WxListGroup extends StatelessWidget {
  const WxListGroup({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.clip = true,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool clip;
  final double? radius;

  static double get defaultRadius => ImDesignTokens.radiusSm;

  @override
  Widget build(BuildContext context) {
    final double r = radius ?? defaultRadius;
    return Container(
      decoration: BoxDecoration(
        color: CommonTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: CommonTokens.lineSubtle),
      ),
      clipBehavior: clip ? Clip.hardEdge : Clip.none,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
