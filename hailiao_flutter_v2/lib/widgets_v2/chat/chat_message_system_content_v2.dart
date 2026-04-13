import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ChatMessageSystemContentV2 extends StatelessWidget {
  const ChatMessageSystemContentV2({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: ChatV2Tokens.tipsText,
        ),
      ),
    );
  }
}
