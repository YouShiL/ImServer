import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 消息行两侧头像占位（单聊 / 群聊共用尺寸与色板）。
class ChatMessageAvatar extends StatelessWidget {
  const ChatMessageAvatar({
    super.key,
    required this.isCurrentUser,
  });

  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ChatUiTokens.messageAvatarSize,
      height: ChatUiTokens.messageAvatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrentUser
            ? ChatUiTokens.currentUserAvatarBackground
            : ChatUiTokens.peerAvatarBackground,
        border: Border.all(
          color: isCurrentUser
              ? ChatUiTokens.currentUserAvatarBorder
              : ChatUiTokens.peerAvatarBorder,
        ),
      ),
      child: Icon(
        isCurrentUser ? Icons.person : Icons.person_outline,
        size: 20,
        color: isCurrentUser
            ? ChatUiTokens.currentUserAvatarIcon
            : ChatUiTokens.peerAvatarIcon,
      ),
    );
  }
}
