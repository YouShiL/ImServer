import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_outgoing_receipt.dart';

/// 发送状态图标区：发送中圈、失败标、单勾、双勾。**仅按 [ChatOutgoingReceipt] 绘制**，不解析 [MessageDTO] 或 status 数值。
class ChatMessageStatusBadge extends StatelessWidget {
  const ChatMessageStatusBadge({
    super.key,
    required this.receipt,
    required this.baseStyle,
    this.compact = false,
    this.textTailInline = false,
    this.onFailedTap,
  });

  final ChatOutgoingReceipt receipt;
  final TextStyle baseStyle;
  final bool compact;
  final bool textTailInline;
  final VoidCallback? onFailedTap;

  static Color get _tickColor =>
      ChatUiTokens.outgoingCheckIconColor;

  @override
  Widget build(BuildContext context) {
    return _buildMark();
  }

  Widget _buildMark() {
    final bool tail = compact && textTailInline;
    final double tickSize =
        tail ? ChatUiTokens.metaIconSize : (compact ? 11 : 14);
    switch (receipt) {
      case ChatOutgoingReceipt.sending:
        final double s = tail ? 12 : (compact ? 9 : 11);
        return SizedBox(
          width: s,
          height: s,
          child: CircularProgressIndicator(
            strokeWidth: tail ? 1.0 : (compact ? 1.0 : 1.35),
            color: baseStyle.color?.withValues(alpha: 0.75),
          ),
        );
      case ChatOutgoingReceipt.failed:
        final Widget icon = Icon(
          Icons.error_outline_rounded,
          size: tail ? ChatUiTokens.metaIconSize : (compact ? 10 : 13),
          color: ChatUiTokens.warning.withValues(alpha: 0.85),
        );
        if (onFailedTap != null) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onFailedTap,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(child: icon),
            ),
          );
        }
        return icon;
      case ChatOutgoingReceipt.sentUnread:
        return Icon(
          Icons.done_rounded,
          size: tickSize,
          color: baseStyle.color ?? _tickColor,
        );
      case ChatOutgoingReceipt.read:
        return Icon(
          Icons.done_all_rounded,
          size: tickSize,
          color: baseStyle.color ?? _tickColor,
        );
    }
  }
}
