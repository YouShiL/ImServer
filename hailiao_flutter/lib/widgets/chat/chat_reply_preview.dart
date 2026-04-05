import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

class ChatReplyPreview extends StatelessWidget {
  const ChatReplyPreview({
    super.key,
    required this.isCurrentUser,
    required this.summary,
  });

  final bool isCurrentUser;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ChatUiTokens.messageContentGap),
      padding: const EdgeInsets.all(ChatUiTokens.messageContentGap),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? ChatUiTokens.replyPanelOutgoing
            : ChatUiTokens.replyPanelIncoming,
        borderRadius: BorderRadius.circular(ChatUiTokens.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: ChatUiTokens.replyAccentWidth,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? ChatUiTokens.replyAccentOutgoing
                  : ChatUiTokens.replyAccentIncoming,
              borderRadius: BorderRadius.circular(ChatUiTokens.replyAccentWidth),
            ),
          ),
          const SizedBox(width: ChatUiTokens.messageContentGap),
          Expanded(
            child: Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ChatUiTokens.replyPreviewTextStyle.copyWith(
                color: isCurrentUser
                    ? ChatUiTokens.outgoingMetaText
                    : ChatUiTokens.incomingMetaText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
