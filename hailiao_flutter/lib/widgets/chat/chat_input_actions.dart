import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';

/// 输入区辅助逻辑：表情插入、与场景相关的附件能力旗标（不单测 UI）。
abstract final class ChatInputActions {
  ChatInputActions._();

  /// 将表情插入 [controller] 当前选区或追加到末尾，行为与原先聊天页一致。
  static void insertEmoji(Emoji emoji, TextEditingController controller) {
    final String t = controller.text;
    final TextSelection sel = controller.selection;
    if (sel.isValid && sel.start >= 0 && sel.end <= t.length) {
      final String next = t.replaceRange(sel.start, sel.end, emoji.code);
      final int offset = sel.start + emoji.code.length;
      controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: offset),
      );
    } else {
      controller.text += emoji.code;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
  }

  /// [ChatAttachPanel.isSingleChat]：是否展示音视频通话等单聊专属单元格。
  static bool attachPanelIsSingleChat(ChatScene scene) =>
      scene == ChatScene.single;
}
