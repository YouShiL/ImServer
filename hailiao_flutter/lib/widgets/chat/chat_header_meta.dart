import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatHeaderMeta extends StatelessWidget {
  const ChatHeaderMeta({
    super.key,
    required this.title,
    this.subtitle,
    this.contextLabel,
    this.statusColor,
  });

  final String title;
  final String? subtitle;
  final String? contextLabel;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (contextLabel != null && contextLabel!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: CommonTokens.xxs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CommonTokens.xs,
                vertical: CommonTokens.xxs,
              ),
              decoration: BoxDecoration(
                color: ChatUiTokens.headerContextChipBackground,
                borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
              ),
              child: Text(
                contextLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChatUiTokens.headerContextTextStyle.copyWith(
                  color: ChatUiTokens.headerContextChipText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ChatUiTokens.chatHeaderTitleText,
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: CommonTokens.xxs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor ?? ChatUiTokens.headerStatusIdle,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: CommonTokens.xs),
                Flexible(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatUiTokens.chatHeaderSubtitleText.copyWith(
                      color: ChatUiTokens.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
