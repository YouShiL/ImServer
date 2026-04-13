import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ChatMessageTipsV2 extends StatelessWidget {
  const ChatMessageTipsV2({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ChatV2Tokens.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(text, style: ChatV2Tokens.tipsText),
          ),
        ),
      ),
    );
  }
}
