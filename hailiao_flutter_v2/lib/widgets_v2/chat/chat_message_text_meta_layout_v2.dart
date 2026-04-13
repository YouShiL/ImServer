import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_bubble_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_text_content_v2.dart';

/// 微信式文本 + meta：单行同行尾对齐；多行 meta 贴气泡内底角。
class ChatMessageTextMetaLayoutV2 extends StatelessWidget {
  const ChatMessageTextMetaLayoutV2({
    super.key,
    required this.text,
    required this.isMine,
    required this.maxBubbleWidth,
    this.meta,
  });

  final String text;
  final bool isMine;
  final double maxBubbleWidth;
  final Widget? meta;

  static const double _metaInlineGap = 5;
  static const double _metaStackBottomInset = 6;
  static const double _metaStackSideInset = 10;
  static const double _multiLineBottomReserve = 20;

  bool _isMultiline(
    BuildContext context,
    TextStyle style,
    double contentMaxWidth,
  ) {
    final double w = math.max(0.0, contentMaxWidth);
    if (w <= 0) {
      return false;
    }
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection dir = Directionality.of(context);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
      textScaler: scaler,
    )..layout(maxWidth: w);
    return painter.computeLineMetrics().length > 1;
  }

  BoxDecoration _bubbleDecoration() {
    final double r = ChatV2Tokens.bubbleRadiusMain;
    final double t = ChatV2Tokens.bubbleRadiusTail;
    return BoxDecoration(
      color: isMine ? ChatV2Tokens.outgoingBubble : ChatV2Tokens.incomingBubble,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isMine ? r : t),
        topRight: Radius.circular(r),
        bottomLeft: Radius.circular(r),
        bottomRight: Radius.circular(isMine ? t : r),
      ),
      boxShadow: isMine
          ? null
          : const <BoxShadow>[
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = ChatV2Tokens.messageText;
    final double contentMaxW = math.max(
      0.0,
      maxBubbleWidth - ChatV2Tokens.bubblePaddingH * 2,
    );

    if (meta == null) {
      return ChatMessageBubbleV2(
        isMine: isMine,
        omitBubbleFill: false,
        footer: null,
        child: ChatMessageTextContentV2(text: text),
      );
    }

    final bool multi = _isMultiline(context, style, contentMaxW);

    if (!multi) {
      return Align(
        alignment: isMine ? Alignment.bottomRight : Alignment.bottomLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatV2Tokens.bubblePaddingH,
                vertical: ChatV2Tokens.bubblePaddingV,
              ),
              decoration: _bubbleDecoration(),
              child: DefaultTextStyle.merge(
                style: style,
                child: ChatMessageTextContentV2(text: text),
              ),
            ),
            SizedBox(width: _metaInlineGap),
            meta!,
          ],
        ),
      );
    }

    return Align(
      alignment: isMine ? Alignment.bottomRight : Alignment.bottomLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(
                ChatV2Tokens.bubblePaddingH,
                ChatV2Tokens.bubblePaddingV,
                ChatV2Tokens.bubblePaddingH,
                ChatV2Tokens.bubblePaddingV + _multiLineBottomReserve,
              ),
              decoration: _bubbleDecoration(),
              child: Text(
                text,
                style: style,
              ),
            ),
            Positioned(
              right: isMine ? _metaStackSideInset : null,
              left: isMine ? null : _metaStackSideInset,
              bottom: _metaStackBottomInset,
              child: meta!,
            ),
          ],
        ),
      ),
    );
  }
}
