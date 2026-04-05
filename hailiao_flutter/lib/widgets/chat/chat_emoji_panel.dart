import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

class ChatEmojiPanel extends StatelessWidget {
  const ChatEmojiPanel({
    super.key,
    required this.onEmojiSelected,
  });

  final ValueChanged<Emoji> onEmojiSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 196,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: const BoxDecoration(
        color: ChatUiTokens.surface,
        border: Border(top: BorderSide(color: ChatUiTokens.border)),
      ),
      child: GridView.count(
        crossAxisCount: 8,
        childAspectRatio: 1.05,
        children: EmojiList.emojis
            .map(
              (emoji) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onEmojiSelected(emoji),
                child: Center(
                  child: Text(
                    emoji.display,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
