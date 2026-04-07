import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/profile_ui_tokens.dart';

/// 微信式列表行：圆底图标 + 主副文案 + trailing / 箭头；分割线由行自身控制（与资料页一致）。
class WxListItem extends StatelessWidget {
  const WxListItem({
    super.key,
    this.leading,
    this.icon,
    this.iconColor,
    this.iconWellColor,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailing,
    this.showChevron = true,
    this.danger = false,
    this.dense = false,
    this.onTap,
    this.showDivider = true,
    this.dividerIndent,
  });

  /// 与 [icon] 二选一；若两者皆空则无 leading。
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  /// 圆底图标配色；默认使用资料页浅色。
  final Color? iconWellColor;

  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailing;
  final bool showChevron;
  final bool danger;
  final bool dense;
  final VoidCallback? onTap;
  final bool showDivider;
  final double? dividerIndent;

  static double get defaultDividerIndent =>
      ImDesignTokens.spaceLg +
      ImDesignTokens.leadingIconSize +
      ImDesignTokens.spaceMd;

  static Widget circleIcon(
    IconData icon, {
    Color? color,
    Color? wellColor,
  }) {
    return Container(
      width: ImDesignTokens.leadingIconSize,
      height: ImDesignTokens.leadingIconSize,
      decoration: BoxDecoration(
        color: wellColor ?? ProfileUiTokens.actionSoftBackground,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: ImDesignTokens.iconSm,
        color: color ?? ProfileUiTokens.actionSoftIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        danger ? CommonTokens.danger : ImDesignTokens.textPrimary;
    final Color? tint = danger ? CommonTokens.danger : iconColor;
    final Widget? lead = leading ??
        (icon != null
            ? circleIcon(icon!, color: tint, wellColor: iconWellColor)
            : null);
    final double rowHeight = dense ? 48.0 : ImDesignTokens.heightItem;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ImDesignTokens.spaceLg,
                ),
                child: Row(
                  children: <Widget>[
                    if (lead != null) ...<Widget>[
                      lead,
                      SizedBox(width: ImDesignTokens.spaceMd),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: CommonTokens.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...<Widget>[
                            SizedBox(height: ImDesignTokens.spaceXs),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CommonTokens.bodySmall.copyWith(
                                color: ImDesignTokens.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailingText != null &&
                        trailingText!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        trailingText!,
                        style: CommonTokens.bodySmall.copyWith(
                          color: CommonTokens.textTertiary,
                        ),
                      ),
                    ],
                    if (trailing != null) trailing!,
                    if (showChevron)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: ImDesignTokens.iconSm,
                        color: ImDesignTokens.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: CommonTokens.lineSubtle,
            indent: dividerIndent ?? defaultDividerIndent,
          ),
      ],
    );
  }
}
