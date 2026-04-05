import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class BadgeTag extends StatelessWidget {
  const BadgeTag({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CommonTokens.space8,
        vertical: CommonTokens.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? CommonTokens.badgeBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: CommonTokens.caption.copyWith(
          color: textColor ?? CommonTokens.badgeText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
