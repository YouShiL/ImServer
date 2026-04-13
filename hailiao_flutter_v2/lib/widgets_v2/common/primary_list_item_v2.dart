import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class PrimaryListItemV2 extends StatelessWidget {
  const PrimaryListItemV2({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.dividerInset = 72,
    this.minHeight = 72,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final double dividerInset;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChatV2Tokens.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: ChatV2Tokens.divider,
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: leading),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ChatV2Tokens.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.25,
                          color: ChatV2Tokens.textSecondary,
                        ),
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
        ),
      ),
    );
  }
}
