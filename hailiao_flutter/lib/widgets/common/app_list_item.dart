import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class AppListItem extends StatelessWidget {
  const AppListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.padding,
    this.dividerIndent = 0,
    this.dividerEndIndent = 0,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;
  final double dividerIndent;
  final double dividerEndIndent;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
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
                title,
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: CommonTokens.space4),
                  subtitle!,
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

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? null
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            content,
            if (showDivider)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: dividerIndent,
                  end: dividerEndIndent,
                ),
                child: const Divider(
                  height: 1,
                  thickness: 1,
                  color: CommonTokens.dividerColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
