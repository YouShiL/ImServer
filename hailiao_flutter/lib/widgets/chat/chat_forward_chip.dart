import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatForwardChip extends StatelessWidget {
  const ChatForwardChip({
    super.key,
    required this.isCurrentUser,
    this.label = '转发消息',
  });

  final bool isCurrentUser;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ChatUiTokens.forwardChipBottomGap),
      padding: const EdgeInsets.symmetric(
        horizontal: CommonTokens.xs,
        vertical: CommonTokens.xxs,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? ChatUiTokens.bubbleFlagOutgoing
            : ChatUiTokens.bubbleFlagIncoming,
        borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
      ),
      child: Text(
        label,
        style: ChatUiTokens.forwardChipTextStyle.copyWith(
          color: isCurrentUser
              ? ChatUiTokens.outgoingMetaText
              : ChatUiTokens.incomingMetaText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
