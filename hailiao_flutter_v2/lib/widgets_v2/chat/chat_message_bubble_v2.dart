import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

/// 与旧 [ChatMessageBubble] 对齐：限宽 + 圆角容器 + 可选 [footer] 在气泡**外**下方。
class ChatMessageBubbleV2 extends StatelessWidget {
  const ChatMessageBubbleV2({
    super.key,
    required this.isMine,
    required this.child,
    this.footer,
    this.omitBubbleFill = false,
  });

  final bool isMine;
  final Widget child;
  /// 气泡外下方弱信息；为 `null` 时不占位。
  final Widget? footer;
  /// 图片等媒体：无绿/白铺底（与旧 omitBubbleFill 一致）。
  final bool omitBubbleFill;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double maxWidth = math.min(
      screenWidth * ChatV2Tokens.bubbleMaxWidthFactor,
      ChatV2Tokens.bubbleMaxWidth,
    );

    final double r = ChatV2Tokens.bubbleRadiusMain;
    final double t = ChatV2Tokens.bubbleRadiusTail;

    final Color bubbleColor = omitBubbleFill
        ? Colors.transparent
        : (isMine ? ChatV2Tokens.outgoingBubble : ChatV2Tokens.incomingBubble);

    final Widget paddedContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Align(
        alignment: isMine ? Alignment.topRight : Alignment.topLeft,
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: child,
      ),
    );

    final EdgeInsets bubblePadding = omitBubbleFill
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(
            horizontal: ChatV2Tokens.bubblePaddingH,
            vertical: ChatV2Tokens.bubblePaddingV,
          );

    final Widget bubbleBody = Container(
      padding: bubblePadding,
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMine ? r : t),
          topRight: Radius.circular(r),
          bottomLeft: Radius.circular(r),
          bottomRight: Radius.circular(isMine ? t : r),
        ),
        boxShadow: omitBubbleFill || isMine
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: DefaultTextStyle.merge(
        style: ChatV2Tokens.messageText,
        child: paddedContent,
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          bubbleBody,
          if (footer != null) ...<Widget>[
            SizedBox(height: ChatV2Tokens.bubbleFooterGap),
            footer!,
          ],
        ],
      ),
    );
  }
}
