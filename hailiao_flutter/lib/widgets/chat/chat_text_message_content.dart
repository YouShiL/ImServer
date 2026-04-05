import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatTextMessageContent extends StatelessWidget {
  const ChatTextMessageContent({
    super.key,
    required this.text,
    required this.textColor,
    this.isSystem = false,
  });

  final String text;
  final Color textColor;
  final bool isSystem;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (isSystem
              ? ChatUiTokens.systemMessageTextStyle
              : CommonTokens.body)
          .copyWith(
            color: textColor,
            height: 1.45,
            fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
          ),
    );
  }
}
