import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/message_send_state.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

/// 气泡外弱信息：时间 + 己方送达态（与旧 [ChatMessageFooterMeta] 职责一致，不拼进正文）。
///
/// 无内容时返回 `null`，避免气泡下出现空白占位。
Widget? buildChatMessageFooterMetaV2({
  required bool isMine,
  required bool isGroupChat,
  required MessageSendState sendState,
  String? timeLabel,
}) {
  final String? shortTime = formatChatShortTime(timeLabel);
  final TextStyle baseMine = TextStyle(
    fontSize: ChatV2Tokens.metaFontSize,
    height: 1.15,
    color: ChatV2Tokens.outgoingMetaText,
  );
  final TextStyle baseIncoming = TextStyle(
    fontSize: ChatV2Tokens.metaFontSize,
    height: 1.15,
    color: ChatV2Tokens.incomingMetaText,
  );

  if (isMine) {
    final String? suffix = mineOutgoingStatusSuffix(sendState);
    final List<Widget> row = <Widget>[];
    if (isGroupChat) {
      if (sendState == MessageSendState.sending ||
          sendState == MessageSendState.failed) {
        if (shortTime != null && shortTime.isNotEmpty) {
          row.add(Text(shortTime, style: baseMine));
          row.add(const SizedBox(width: 4));
        }
        if (suffix != null && suffix.isNotEmpty) {
          row.add(Text(suffix, style: baseMine));
        }
      } else {
        if (shortTime != null && shortTime.isNotEmpty) {
          row.add(Text(shortTime, style: baseMine));
        }
      }
    } else {
      if (shortTime != null && shortTime.isNotEmpty) {
        row.add(Text(shortTime, style: baseMine));
      }
      if (suffix != null && suffix.isNotEmpty) {
        if (row.isNotEmpty) {
          row.add(const SizedBox(width: 4));
        }
        row.add(Text(suffix, style: baseMine));
      }
    }
    if (row.isEmpty) {
      return null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: row,
    );
  }

  if (shortTime == null || shortTime.isEmpty) {
    return null;
  }
  return Text(shortTime, style: baseIncoming);
}

String? formatChatShortTime(String? iso) {
  if (iso == null || iso.trim().isEmpty) {
    return null;
  }
  final DateTime? dt = DateTime.tryParse(iso.trim());
  if (dt == null) {
    return null;
  }
  return '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}
