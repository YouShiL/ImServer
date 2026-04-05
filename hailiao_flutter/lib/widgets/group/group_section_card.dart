import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/group_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_surface.dart';

class GroupSectionCard extends StatelessWidget {
  const GroupSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: padding ?? const EdgeInsets.all(GroupUiTokens.sectionPadding),
      backgroundColor: GroupUiTokens.sectionBackground,
      borderRadius: 18,
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: GroupUiTokens.sectionTitleText,
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GroupUiTokens.sectionSubtitleText,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
