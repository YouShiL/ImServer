import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/chat/chat_forward_chip.dart';
import 'package:hailiao_flutter/widgets/chat/chat_reply_preview.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.isCurrentUser,
    required this.child,
    this.footer,
    this.replySummary,
    this.isForwarded = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.selectionMode = false,
    this.selectionValue = false,
    this.onTap,
    this.onLongPress,
    this.onSelectionToggle,
    /// 为 null 时使用 [ChatUiTokens.bubbleDefaultFallbackPadding]。
    this.contentPadding,
    /// 为 true 时不铺绿/白气泡底色（高亮/多选仍保留底色），用于图片等以媒体为主体的消息。
    this.omitBubbleFill = false,
  });

  final bool isCurrentUser;
  final Widget child;
  /// 消息下方弱信息（时间+送达图标、对方「已编辑」等）；null 则不展示。
  final Widget? footer;
  final String? replySummary;
  final bool isForwarded;
  final bool isSelected;
  final bool isHighlighted;
  final bool selectionMode;
  final bool selectionValue;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;
  final EdgeInsets? contentPadding;
  final bool omitBubbleFill;

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
            : (omitBubbleFill
                ? Colors.transparent
                : (outgoing
                    ? ChatUiTokens.outgoingBubble
                    : ChatUiTokens.incomingBubble));
    final Color bodyTextColor = outgoing
        ? ChatUiTokens.outgoingBubbleText
        : ChatUiTokens.incomingBubbleText;
    final bool showBubbleBorder = isHighlighted || isSelected;
    final double r = ChatUiTokens.bubbleRadiusMain;
    final double t = ChatUiTokens.bubbleRadiusTail;

    /// 己方：[Align] 使用 `widthFactor/heightFactor: 1`，否则默认 [Align] 会横向占满 [maxWidth]，短文本绿也会假宽。
    /// 对方：保持默认 [Align]，短消息仍可按父级宽度假饱满对齐（与微信常见行为一致）；长文由 [ConstrainedBox] + 子级换行撑开。
    final Widget bubbleInner = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Align(
        alignment: outgoing ? Alignment.topRight : Alignment.topLeft,
        widthFactor: outgoing ? 1.0 : null,
        heightFactor: outgoing ? 1.0 : null,
        child: Column(
          crossAxisAlignment:
              outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
          ],
        ),
      ),
    );

    final EdgeInsets resolvedPadding =
        contentPadding ?? ChatUiTokens.bubbleDefaultFallbackPadding;

    final double minBubbleW = outgoing
        ? ChatUiTokens.outgoingBubbleMinWidth
        : ChatUiTokens.incomingBubbleMinWidth;

    final Widget bubbleBody = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minBubbleW),
      child: Container(
        padding: resolvedPadding,
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(outgoing ? r : t),
            topRight: Radius.circular(r),
            bottomLeft: Radius.circular(r),
            bottomRight: Radius.circular(outgoing ? t : r),
          ),
          border: Border.all(
            color: isHighlighted
                ? ChatUiTokens.warning
                : isSelected
                    ? ChatUiTokens.info
                    : Colors.transparent,
            width: showBubbleBorder ? 1 : 0,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: CommonTokens.body.copyWith(color: bodyTextColor),
          child: bubbleInner,
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          bubbleBody,
          if (footer != null) ...<Widget>[
            SizedBox(height: ChatUiTokens.bubbleFooterGap),
            footer!,
          ],
        ],
      ),
    );
  }
}
