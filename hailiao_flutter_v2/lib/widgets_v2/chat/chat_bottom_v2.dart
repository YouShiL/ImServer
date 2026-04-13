import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_bottom_input_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_bottom_panel_v2.dart';

class ChatBottomV2 extends StatelessWidget {
  const ChatBottomV2({
    super.key,
    required this.viewModel,
    required this.controller,
    required this.focusNode,
    required this.onInputChanged,
    required this.onSend,
    required this.onEmojiTap,
    this.onRequestKeyboardFromEmoji,
    this.onEmojiSelected,
    this.onEmojiBackspace,
  });

  final ChatV2ComposerViewModel viewModel;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onInputChanged;
  final VoidCallback onSend;
  final VoidCallback onEmojiTap;
  final VoidCallback? onRequestKeyboardFromEmoji;
  final ValueChanged<String>? onEmojiSelected;
  final VoidCallback? onEmojiBackspace;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ChatV2Tokens.headerBackground,
        border: Border(top: BorderSide(color: ChatV2Tokens.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ChatBottomInputV2(
              viewModel: viewModel,
              controller: controller,
              focusNode: focusNode,
              onChanged: onInputChanged,
              onSend: onSend,
              onEmojiTap: onEmojiTap,
              onRequestKeyboardFromEmoji: onRequestKeyboardFromEmoji,
            ),
            ChatBottomPanelV2(
              mode: viewModel.bottomMode,
              onEmojiSelected: onEmojiSelected,
              onEmojiBackspace: onEmojiBackspace,
            ),
          ],
        ),
      ),
    );
  }
}
