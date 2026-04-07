import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 群聊对方发送者昵称（是否显示由 [MessageBubblePresenter.shouldShowGroupSenderName]；
/// 文案见 [MessageDTOChatDisplay.displaySenderFallbackName]）。
class ChatSenderNameLabel extends StatelessWidget {
  const ChatSenderNameLabel({
    super.key,
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: ChatUiTokens.groupSenderNameLeftInset,
        bottom: ChatUiTokens.groupSenderNameToBubbleGap,
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ChatUiTokens.groupSenderNameTextStyle,
      ),
    );
  }
}
