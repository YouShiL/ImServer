import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatAudioMessageContent extends StatelessWidget {
  const ChatAudioMessageContent({
    super.key,
    required this.isCurrentUser,
    required this.onTap,
    this.durationLabel,
    this.isHighlighted = false,
  });

  final bool isCurrentUser;
  final VoidCallback onTap;
  final String? durationLabel;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final Color background = isHighlighted
        ? ChatUiTokens.mediaHighlightSurface
        : isCurrentUser
            ? ChatUiTokens.audioCardOutgoing
            : ChatUiTokens.audioCardIncoming;
    final Color primaryText = isCurrentUser
        ? ChatUiTokens.outgoingBubbleText
        : ChatUiTokens.incomingBubbleText;
    final Color secondaryText = isCurrentUser
        ? ChatUiTokens.outgoingMetaText
        : ChatUiTokens.incomingMetaText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: ChatUiTokens.audioCardMinWidth,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: CommonTokens.sm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(ChatUiTokens.mediaRadiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? ChatUiTokens.audioTrackOutgoing
                    : ChatUiTokens.audioTrackIncoming,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: primaryText,
                size: 20,
              ),
            ),
            const SizedBox(width: CommonTokens.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '语音消息',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatUiTokens.audioTitleTextStyle.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    durationLabel ?? '时长待补充',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatUiTokens.audioSubtitleTextStyle.copyWith(
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CommonTokens.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(
                4,
                (int index) => Container(
                  width: 3,
                  height: 8 + (index.isEven ? 8 : 4),
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? ChatUiTokens.audioTrackOutgoing
                        : ChatUiTokens.audioTrackIncoming,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
