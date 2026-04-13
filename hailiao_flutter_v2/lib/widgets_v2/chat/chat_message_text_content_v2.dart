import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ChatMessageTextContentV2 extends StatelessWidget {
  const ChatMessageTextContentV2({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: ChatV2Tokens.messageText);
  }
}
