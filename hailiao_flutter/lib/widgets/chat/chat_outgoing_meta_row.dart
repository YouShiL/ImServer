import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_footer_meta.dart';
import 'package:hailiao_flutter/widgets/chat/chat_outgoing_receipt.dart';

export 'package:hailiao_flutter/widgets/chat/chat_outgoing_receipt.dart'
    show ChatOutgoingReceipt;

/// 己方消息弱信息行：时间 + 送达标记 + 「已编辑」。
///
/// 实现已收口至 [ChatMessageFooterMeta]，本类保留历史构造函数与导出，避免大面积改调用方。
class ChatOutgoingMetaRow extends StatelessWidget {
  const ChatOutgoingMetaRow({
    super.key,
    this.shortTime,
    this.receipt,
    this.showEdited = false,
    this.metaColor,
    this.compact = false,
    this.textTailInline = false,
    /// 保留参数以保持 API 稳定；展示策略由 [ChatOutgoingStatusMetaFactory] / receipt 决定。
    this.isGroupChat = false,
    this.onFailedTap,
  });

  final String? shortTime;
  final ChatOutgoingReceipt? receipt;
  final bool showEdited;
  final Color? metaColor;
  final bool compact;
  final bool textTailInline;
  final bool isGroupChat;
  final VoidCallback? onFailedTap;

  @override
  Widget build(BuildContext context) {
    return ChatMessageFooterMeta(
      shortTime: shortTime,
      receipt: receipt,
      showEdited: showEdited,
      metaColor: metaColor,
      compact: compact,
      textTailInline: textTailInline,
      onFailedTap: onFailedTap,
    );
  }
}
