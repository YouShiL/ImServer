import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/settings_ui_tokens.dart';

/// 灰底页分组标题（上间距 + 弱色小字），可选副标题与右侧控件（如设置区块标题栏）。
class WxSectionTitle extends StatelessWidget {
  const WxSectionTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// 默认与资料页分段一致；首段在列表顶部时可传入更小 top。
  final EdgeInsetsGeometry? padding;

  static EdgeInsetsGeometry get defaultPadding => const EdgeInsets.only(
        top: ImDesignTokens.spaceXl,
        left: ImDesignTokens.spaceXs,
        bottom: ImDesignTokens.spaceSm,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? defaultPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: CommonTokens.caption.copyWith(
                    color: CommonTokens.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!.trim(),
                      style: SettingsUiTokens.sectionSubtitleText.copyWith(
                        color: CommonTokens.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing case final Widget w) w,
        ],
      ),
    );
  }
}
