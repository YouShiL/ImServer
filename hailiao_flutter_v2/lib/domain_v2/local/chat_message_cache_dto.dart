import 'dart:convert';

import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/message_send_state.dart';

/// 会话消息本地缓存行与 [ChatMessage] 的互转（JSON），供 Drift / 未来存储层复用。
abstract final class ChatMessageCacheDto {
  ChatMessageCacheDto._();

  static Map<String, dynamic> toJson(ChatMessage m) {
    return <String, dynamic>{
      'id': m.id,
      'serverId': m.serverId,
      'clientId': m.clientId,
      'targetId': m.targetId,
      'type': m.type,
      'senderId': m.senderId,
      'senderName': m.senderName,
      'senderProfileNickname': m.senderProfileNickname,
      'text': m.text,
      'imageUrl': m.imageUrl,
      'createdAt': m.createdAt,
      'isMine': m.isMine,
      'sendState': m.sendState.name,
      'localInboundRead': m.localInboundRead,
    };
  }

  static ChatMessage fromJson(Map<String, dynamic> j) {
    final String sendStateName = j['sendState'] as String? ?? 'sent';
    final MessageSendState sendState = MessageSendState.values.firstWhere(
      (MessageSendState e) => e.name == sendStateName,
      orElse: () => MessageSendState.sent,
    );
    return ChatMessage(
      id: j['id'] as String,
      serverId: j['serverId'] as int?,
      clientId: j['clientId'] as String?,
      targetId: j['targetId'] as int,
      type: j['type'] as int,
      senderId: j['senderId'] as int?,
      senderName: j['senderName'] as String?,
      senderProfileNickname: j['senderProfileNickname'] as String?,
      text: j['text'] as String? ?? '',
      imageUrl: j['imageUrl'] as String?,
      createdAt: j['createdAt'] as String?,
      isMine: j['isMine'] as bool,
      sendState: sendState,
      localInboundRead: j['localInboundRead'] as bool? ?? true,
    );
  }

  static String encode(ChatMessage m) => jsonEncode(toJson(m));

  static ChatMessage decode(String json) =>
      fromJson(jsonDecode(json) as Map<String, dynamic>);

  static int createdAtMillis(ChatMessage m) {
    final String? raw = m.createdAt;
    if (raw == null || raw.trim().isEmpty) {
      return 0;
    }
    final DateTime? t = DateTime.tryParse(raw.trim());
    if (t != null) {
      return t.millisecondsSinceEpoch;
    }
    try {
      return int.parse(raw);
    } catch (_) {
      return 0;
    }
  }
}
