import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ChatBottomInputV2 extends StatelessWidget {
  const ChatBottomInputV2({
    super.key,
    required this.viewModel,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSend,
    required this.onEmojiTap,
    this.onRequestKeyboardFromEmoji,
  });

  final ChatV2ComposerViewModel viewModel;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onEmojiTap;
  final VoidCallback? onRequestKeyboardFromEmoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: ChatV2Tokens.inputBarMinHeight),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_voice_outlined),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 38),
              decoration: BoxDecoration(
                color: ChatV2Tokens.surface,
                borderRadius: BorderRadius.circular(6),
                border: const Border.fromBorderSide(
                  BorderSide(color: ChatV2Tokens.divider),
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onTap: () {
                  if (viewModel.bottomMode == ChatV2BottomMode.emoji) {
                    onRequestKeyboardFromEmoji?.call();
                  }
                },
                onSubmitted: (_) => onSend(),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: viewModel.hintText,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onEmojiTap,
            icon: Icon(
              viewModel.bottomMode == ChatV2BottomMode.emoji
                  ? Icons.keyboard_alt_outlined
                  : Icons.emoji_emotions_outlined,
            ),
          ),
          if (viewModel.inputText.trim().isEmpty)
            const SizedBox(width: 48)
          else
            TextButton(
              onPressed: onSend,
              child: const Text('发送'),
            ),
        ],
      ),
    );
  }
}
