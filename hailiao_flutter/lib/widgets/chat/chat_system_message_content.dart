import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/chat/chat_text_message_content.dart';

/// 系统类弱样式文案（撤回提示、居中/斜体语义等），内部复用 [ChatTextMessageContent] 的 `isSystem` 排版。
class ChatSystemMessageContent extends StatelessWidget {
  const ChatSystemMessageContent({
    super.key,
    required this.text,
    required this.textColor,
  });

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return ChatTextMessageContent(
      text: text,
      textColor: textColor,
      isSystem: true,
    );
  }
}
