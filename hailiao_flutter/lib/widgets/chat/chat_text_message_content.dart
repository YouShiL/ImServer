import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_outgoing_text_bubble_body.dart';

class ChatTextMessageContent extends StatelessWidget {
  const ChatTextMessageContent({
    super.key,
    required this.text,
    required this.textColor,
    this.isSystem = false,
    this.outgoingAlignEnd = false,
    this.inlineMeta,
  });

  final String text;
  final Color textColor;
  final bool isSystem;
  final bool outgoingAlignEnd;
  final Widget? inlineMeta;

  @override
  Widget build(BuildContext context) {
    const TextAlign align = TextAlign.start;
    final CrossAxisAlignment columnCross =
        (isSystem || !outgoingAlignEnd)
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end;

    final TextStyle baseStyle = (isSystem
            ? ChatUiTokens.systemMessageTextStyle
            : CommonTokens.body)
        .copyWith(
          color: textColor,
          fontSize:
              isSystem ? null : ChatUiTokens.messageTextFontSize,
          height: isSystem ? null : ChatUiTokens.messageTextHeight,
          fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
        );

    final Widget body = Text(
      text,
      textAlign: align,
      style: baseStyle,
    );

    if (inlineMeta == null) {
      return body;
    }

    if (outgoingAlignEnd && !isSystem) {
      return ChatOutgoingTextBubbleBody(
        text: text,
        textStyle: baseStyle,
        tailMeta: inlineMeta!,
      );
    }

    return Column(
      crossAxisAlignment: columnCross,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        body,
        SizedBox(height: ChatUiTokens.bubbleContentToMetaGap),
        inlineMeta!,
      ],
    );
  }
}
