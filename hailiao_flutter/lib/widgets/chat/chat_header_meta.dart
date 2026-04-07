import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 聊天顶栏标题区：主标题 + 弱副标题行（状态小圆点 + 文案），无条带状背景。
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
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              contextLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChatUiTokens.chatHeaderSubtitleText.copyWith(
                fontSize: 11,
                color: ChatUiTokens.subtleText.withValues(alpha: 0.85),
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
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: statusColor ?? ChatUiTokens.headerStatusIdle,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '· ${subtitle!}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatUiTokens.chatHeaderSubtitleText.copyWith(
                      color: ChatUiTokens.subtleText.withValues(alpha: 0.92),
                      fontSize: 12,
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
