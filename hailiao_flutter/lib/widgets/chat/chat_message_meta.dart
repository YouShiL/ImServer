import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

class ChatMessageMeta extends StatelessWidget {
  const ChatMessageMeta({
    super.key,
    required this.text,
    required this.isCurrentUser,
  });

  final String text;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: ChatUiTokens.messageMetaTextStyle.copyWith(
          color: isCurrentUser
              ? ChatUiTokens.outgoingMetaText
              : ChatUiTokens.incomingMetaText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
