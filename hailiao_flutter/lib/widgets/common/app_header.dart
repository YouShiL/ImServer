import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

enum AppHeaderVariant { standard, home, chat }

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.variant = AppHeaderVariant.standard,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final AppHeaderVariant variant;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final titleStyle = switch (variant) {
      AppHeaderVariant.home => CommonTokens.section,
      AppHeaderVariant.standard => CommonTokens.section,
      AppHeaderVariant.chat => CommonTokens.section,
    };

    return Container(
      color: CommonTokens.headerBackground,
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: CommonTokens.space16,
            vertical: CommonTokens.space12,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: CommonTokens.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: CommonTokens.space4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CommonTokens.caption,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: CommonTokens.space12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
