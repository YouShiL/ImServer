import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

enum ChatStatusBannerTone {
  neutral,
  info,
  warning,
  success,
}

class ChatStatusBanner extends StatelessWidget {
  const ChatStatusBanner({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.tone = ChatStatusBannerTone.neutral,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final ChatStatusBannerTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final _ToneSpec spec = _resolveTone(tone);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ChatUiTokens.statusBannerMaxWidth,
        ),
        child: Container(
          margin: EdgeInsets.fromLTRB(
            CommonTokens.sm,
            compact ? CommonTokens.xxs : CommonTokens.xs,
            CommonTokens.sm,
            0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? CommonTokens.xs : CommonTokens.sm,
            vertical: compact ? CommonTokens.xxs : CommonTokens.sm,
          ),
          decoration: BoxDecoration(
            color: spec.background,
            borderRadius: BorderRadius.circular(ChatUiTokens.radiusMd),
            border: Border.all(color: spec.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: compact ? 28 : 30,
                height: compact ? 28 : 30,
                decoration: BoxDecoration(
                  color: spec.iconBackground,
                  borderRadius: BorderRadius.circular(ChatUiTokens.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: compact ? 16 : 17,
                  color: spec.iconColor,
                ),
              ),
              const SizedBox(width: CommonTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChatUiTokens.statusBannerTitleTextStyle.copyWith(
                        color: ChatUiTokens.statusBannerTitle,
                        fontWeight:
                            compact ? FontWeight.w500 : FontWeight.w600,
                        fontSize: compact ? 12.5 : null,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: ChatUiTokens.statusBannerSubtitleTextStyle
                            .copyWith(
                          color: ChatUiTokens.statusBannerSubtitle
                              .withValues(alpha: compact ? 0.82 : 1),
                          height: 1.3,
                          fontSize: compact ? 11.5 : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: CommonTokens.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  _ToneSpec _resolveTone(ChatStatusBannerTone tone) {
    switch (tone) {
      case ChatStatusBannerTone.info:
        return const _ToneSpec(
          background: ChatUiTokens.statusBannerInfoBackground,
          border: ChatUiTokens.statusBannerInfoBorder,
          iconBackground: Colors.white,
          iconColor: ChatUiTokens.statusBannerInfoIcon,
        );
      case ChatStatusBannerTone.warning:
        return const _ToneSpec(
          background: ChatUiTokens.statusBannerWarningBackground,
          border: ChatUiTokens.statusBannerWarningBorder,
          iconBackground: Colors.white,
          iconColor: ChatUiTokens.statusBannerWarningIcon,
        );
      case ChatStatusBannerTone.success:
        return const _ToneSpec(
          background: ChatUiTokens.statusBannerSuccessBackground,
          border: ChatUiTokens.statusBannerSuccessBorder,
          iconBackground: Colors.white,
          iconColor: ChatUiTokens.statusBannerSuccessIcon,
        );
      case ChatStatusBannerTone.neutral:
        return const _ToneSpec(
          background: ChatUiTokens.statusBannerBackground,
          border: ChatUiTokens.statusBannerBorder,
          iconBackground: Colors.white,
          iconColor: ChatUiTokens.statusBannerIcon,
        );
    }
  }
}

class _ToneSpec {
  const _ToneSpec({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
  });

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
}
