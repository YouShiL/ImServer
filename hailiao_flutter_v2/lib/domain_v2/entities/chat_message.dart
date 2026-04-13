import 'package:hailiao_flutter_v2/domain_v2/entities/message_send_state.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    this.serverId,
    this.clientId,
    required this.targetId,
    required this.type,
    required this.senderId,
    this.senderName,
    this.senderProfileNickname,
    required this.text,
    this.createdAt,
    required this.isMine,
    required this.sendState,
    this.localInboundRead = true,
    this.imageUrl,
  });

  final String id;
  final int? serverId;
  final String? clientId;
  final int targetId;
  final int type;
  final int? senderId;
  final String? senderName;

  /// REST 历史消息携带的 [MessageDTO.fromUserInfo.nickname]；SDK 路径一般为 null。
  final String? senderProfileNickname;
  final String text;

  /// 非空时表示图片消息（展示用 URL，可为相对路径）。
  final String? imageUrl;
  final String? createdAt;
  final bool isMine;
  final MessageSendState sendState;

  /// 仅对 [!isMine] 有意义：本端是否已将该条入站消息视为「已读」（本地一致性；私聊可与 [markConversationRead] 配合）。
  /// 群聊不追踪入站条目的细粒度已读，恒为 true。
  final bool localInboundRead;

  ChatMessage copyWith({
    String? id,
    int? serverId,
    Object? clientId = _sentinel,
    int? targetId,
    int? type,
    Object? senderId = _sentinel,
    Object? senderName = _sentinel,
    Object? senderProfileNickname = _sentinel,
    String? text,
    Object? imageUrl = _sentinel,
    Object? createdAt = _sentinel,
    bool? isMine,
    MessageSendState? sendState,
    bool? localInboundRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientId: identical(clientId, _sentinel) ? this.clientId : clientId as String?,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      senderId: identical(senderId, _sentinel) ? this.senderId : senderId as int?,
      senderName: identical(senderName, _sentinel) ? this.senderName : senderName as String?,
      senderProfileNickname: identical(senderProfileNickname, _sentinel)
          ? this.senderProfileNickname
          : senderProfileNickname as String?,
      text: text ?? this.text,
      imageUrl: identical(imageUrl, _sentinel) ? this.imageUrl : imageUrl as String?,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
      isMine: isMine ?? this.isMine,
      sendState: sendState ?? this.sendState,
      localInboundRead: localInboundRead ?? this.localInboundRead,
    );
  }

  static const Object _sentinel = Object();
}
