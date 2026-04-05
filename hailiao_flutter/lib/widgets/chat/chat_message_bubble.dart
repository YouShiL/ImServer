import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/chat/chat_forward_chip.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_meta.dart';
import 'package:hailiao_flutter/widgets/chat/chat_reply_preview.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.isCurrentUser,
    required this.child,
    required this.footerText,
    this.replySummary,
    this.isForwarded = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.selectionMode = false,
    this.selectionValue = false,
    this.onTap,
    this.onLongPress,
    this.onSelectionToggle,
  });

  final bool isCurrentUser;
  final Widget child;
  final String footerText;
  final String? replySummary;
  final bool isForwarded;
  final bool isSelected;
  final bool isHighlighted;
  final bool selectionMode;
  final bool selectionValue;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final bool outgoing = isCurrentUser;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxWidth = math.min(
      screenWidth * ChatUiTokens.bubbleMaxWidthFactor,
      ChatUiTokens.bubbleMaxWidth,
    );

    final Color bubbleColor = isHighlighted
        ? ChatUiTokens.highlight
        : isSelected
            ? ChatUiTokens.selected
            : (outgoing
                ? ChatUiTokens.outgoingBubble
                : ChatUiTokens.incomingBubble);
    final Color bodyTextColor = outgoing
        ? ChatUiTokens.outgoingBubbleText
        : ChatUiTokens.incomingBubbleText;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ChatUiTokens.bubbleHorizontalPadding,
          vertical: ChatUiTokens.bubbleVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(ChatUiTokens.radiusLg),
            topRight: const Radius.circular(ChatUiTokens.radiusLg),
            bottomLeft: Radius.circular(
              outgoing ? ChatUiTokens.radiusLg : ChatUiTokens.radiusXs,
            ),
            bottomRight: Radius.circular(
              outgoing ? ChatUiTokens.radiusXs : ChatUiTokens.radiusLg,
            ),
          ),
          border: Border.all(
            color: isHighlighted
                ? ChatUiTokens.warning
                : isSelected
                    ? ChatUiTokens.info
                    : (outgoing
                        ? Colors.transparent
                        : ChatUiTokens.incomingBubbleBorder),
            width: (isHighlighted || isSelected || !outgoing) ? 1 : 0,
          ),
          boxShadow: outgoing ? null : ChatUiTokens.surfaceShadow,
        ),
        child: DefaultTextStyle.merge(
          style: CommonTokens.body.copyWith(color: bodyTextColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isForwarded)
                ChatForwardChip(
                  isCurrentUser: outgoing,
                  label: '转发消息',
                ),
              if (replySummary != null && replySummary!.isNotEmpty)
                ChatReplyPreview(
                  isCurrentUser: outgoing,
                  summary: replySummary!,
                ),
              child,
              if (footerText.isNotEmpty) ...<Widget>[
                const SizedBox(height: ChatUiTokens.bubbleFooterGap),
                ChatMessageMeta(
                  text: footerText,
                  isCurrentUser: outgoing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
