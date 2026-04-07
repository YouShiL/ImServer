import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/chat/chat_composer_banner.dart';

/// 输入区顶部「回复 / 编辑引用」条：视觉与交互与 [ChatComposerBanner] 一致，语义收口到 Composer 层。
class ChatInputReplyBanner extends StatelessWidget {
  const ChatInputReplyBanner({
    super.key,
    required this.visible,
    required this.isEditing,
    required this.summaryText,
    required this.onClose,
  });

  final bool visible;
  final bool isEditing;
  final String summaryText;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return ChatComposerBanner(
      isEditing: isEditing,
      summaryText: summaryText,
      onClose: onClose,
    );
  }
}
