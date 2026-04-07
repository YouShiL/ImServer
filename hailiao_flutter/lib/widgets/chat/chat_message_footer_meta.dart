import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_status_badge.dart';
import 'package:hailiao_flutter/widgets/chat/chat_outgoing_receipt.dart';

/// 气泡下方 / 气泡内尾部弱信息：时间 + 送达状态 + 「已编辑」等（**纯布局**，不读 [MessageDTO] 业务规则）。
///
/// 文本内联尾部仍由 [ChatOutgoingTextBubbleBody]；图标形态与 [ChatMessageStatusBadge] 一致。
class ChatMessageFooterMeta extends StatelessWidget {
  const ChatMessageFooterMeta({
    super.key,
    this.shortTime,
    this.receipt,
    this.showEdited = false,
    this.metaColor,
    this.compact = false,
    this.textTailInline = false,
    this.onFailedTap,
  });

  final String? shortTime;
  final ChatOutgoingReceipt? receipt;
  final bool showEdited;
  final Color? metaColor;
  final bool compact;
  final bool textTailInline;
  final VoidCallback? onFailedTap;

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? ChatUiTokens.metaFontSize : 10;
    final double lineHeight = compact ? 1.05 : 1.15;
    final double gap =
        compact ? ChatUiTokens.metaTimeReceiptGap : 4;
    TextStyle base = ChatUiTokens.messageMetaTextStyle.copyWith(
      fontSize: fontSize,
      height: lineHeight,
    );
    if (metaColor != null) {
      base = base.copyWith(color: metaColor);
    }

    final List<Widget> row = <Widget>[];
    if (shortTime != null && shortTime!.isNotEmpty) {
      row.add(Text(shortTime!, style: base));
    }

    if (receipt != null) {
      if (row.isNotEmpty) {
        row.add(SizedBox(width: gap));
      }
      row.add(
        ChatMessageStatusBadge(
          receipt: receipt!,
          baseStyle: base,
          compact: compact,
          textTailInline: textTailInline,
          onFailedTap: onFailedTap,
        ),
      );
    }

    if (showEdited) {
      if (row.isNotEmpty) {
        row.add(Text(' · ', style: base));
      }
      row.add(
        Text(
          '已编辑',
          style: base.copyWith(
            color: base.color?.withValues(alpha: 0.92),
          ),
        ),
      );
    }

    if (row.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: row,
    );
  }
}

/// 对方消息气泡下弱提示行（如「已编辑」），与 [ChatMessageFooterMeta] 同一套 meta 色与字号，仅布局为整行弱文案。
class ChatMessageIncomingFooterLine extends StatelessWidget {
  const ChatMessageIncomingFooterLine({
    super.key,
    required this.text,
    required this.isFromPeer,
  });

  final String text;
  final bool isFromPeer;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromPeer ? Alignment.centerLeft : Alignment.centerRight,
      child: Text(
        text,
        textAlign: isFromPeer ? TextAlign.left : TextAlign.right,
        style: ChatUiTokens.messageMetaTextStyle.copyWith(
          fontSize: ChatUiTokens.metaFontSize,
          color: ChatUiTokens.incomingMetaText,
        ),
      ),
    );
  }
}
