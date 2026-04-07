import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_text_message_content.dart';

/// 未知或未接入的 [msgType] 兜底，避免新类型拖垮布局。
class ChatUnknownMessageContent extends StatelessWidget {
  const ChatUnknownMessageContent({
    super.key,
    required this.msgType,
    this.payloadPreview,
  });

  final int msgType;

  /// 可选的原始内容摘要（已截断处理由调用方负责）。
  final String? payloadPreview;

  @override
  Widget build(BuildContext context) {
    final String text = (payloadPreview != null && payloadPreview!.trim().isNotEmpty)
        ? '暂不支持的消息类型（$msgType）\n${payloadPreview!.trim()}'
        : '暂不支持的消息类型（类型 $msgType）';
    return ChatTextMessageContent(
      text: text,
      textColor: ChatUiTokens.systemMessageText,
      isSystem: true,
    );
  }
}
