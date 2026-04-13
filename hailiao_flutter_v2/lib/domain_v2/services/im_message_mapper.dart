import 'dart:convert';

import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/theme/chat_date_format.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/conversation_summary.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/message_send_state.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/conversation_identity.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/identity_resolver.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_conv_source_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_conv_title_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_identity_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_send_args_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_event.dart';
import 'package:wukongimfluttersdk/entity/msg.dart';
import 'package:wukongimfluttersdk/model/wk_image_content.dart';
import 'package:wukongimfluttersdk/model/wk_text_content.dart';
import 'package:wukongimfluttersdk/type/const.dart';
import 'package:wukongimfluttersdk/wkim.dart';

class ImMessageMapper {
  ImMessageMapper({IdentityResolver? identityResolver})
      : _identity = identityResolver ?? IdentityResolver();

  final IdentityResolver _identity;

  /// SDK [WKImageContent] 在 refresh/回执后 [url] 可能未同步，但 [WKMsg.content] 常为完整 JSON，从中补全可展示地址。
  static String? _resolveSdkImageUrl(WKMsg raw, WKImageContent mc) {
    final String fromModel = mc.url.trim();
    if (fromModel.isNotEmpty) {
      imImageSendLog('mapSdkMessage_image_url', <String, Object?>{
        'source': 'WKImageContent.url',
        'len': fromModel.length.toString(),
      });
      return fromModel;
    }
    final String localPath = mc.localPath.trim();
    imImageSendLog('mapSdkMessage_image_url_fields', <String, Object?>{
      'urlEmpty': 'true',
      'localPathLen': localPath.length.toString(),
      'contentLen': raw.content.trim().length.toString(),
    });
    final String rawStr = raw.content.trim();
    if (rawStr.isEmpty) {
      return null;
    }
    try {
      final dynamic j = jsonDecode(rawStr);
      if (j is Map) {
        for (final String key in <String>['url', 'path']) {
          final Object? v = j[key];
          if (v is String && v.trim().isNotEmpty) {
            final String u = v.trim();
            imImageSendLog('mapSdkMessage_image_url', <String, Object?>{
              'source': 'WKMsg.content_json.$key',
              'len': u.length.toString(),
            });
            return u;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static const int _historyContentLogMax = 420;

  static String _truncateForHistoryLog(String? s) {
    if (s == null) {
      return '';
    }
    final String t = s.trim();
    if (t.length <= _historyContentLogMax) {
      return t;
    }
    return '${t.substring(0, _historyContentLogMax)}…';
  }

  static bool _looksLikeHttpUrl(String s) {
    return RegExp(r'^https?://', caseSensitive: false).hasMatch(s.trim());
  }

  /// REST 历史 [msgType]==2：[content]/[extra] 可能是裸 URL、相对路径、单层 JSON、嵌套 JSON 或 `content` 内再嵌一段 JSON 字符串。
  /// 解析失败返回 `null`。
  static String? parseImageUrlFromHistoryContent(String? raw) {
    if (raw == null) {
      return null;
    }
    final String t = raw.trim();
    if (t.isEmpty) {
      return null;
    }
    if (_looksLikeHttpUrl(t)) {
      return t.trim();
    }
    final String first = t.isEmpty ? '' : t.substring(0, 1);
    if (first == '{' || first == '[') {
      try {
        final dynamic decoded = jsonDecode(t);
        final String? extracted = _extractImageUrlFromJson(decoded);
        if (extracted != null) {
          return extracted;
        }
      } catch (_) {
        return null;
      }
      return null;
    }
    return t;
  }

  /// 自嵌套结构取首个可用图片地址（WuKong 常见：平铺 `url`；或 `content` 为 JSON 字符串）。
  static String? _extractImageUrlFromJson(dynamic node, {int depth = 0}) {
    if (depth > 8) {
      return null;
    }
    if (node is String) {
      final String s = node.trim();
      if (s.isEmpty) {
        return null;
      }
      if (_looksLikeHttpUrl(s) || s.startsWith('/')) {
        return s;
      }
      if (s.startsWith('{') || s.startsWith('[')) {
        try {
          return _extractImageUrlFromJson(jsonDecode(s), depth: depth + 1);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    if (node is Map) {
      final Map<dynamic, dynamic> map = node;
      for (final String key in <String>[
        'url',
        'path',
        'fileUrl',
        'imageUrl',
        'src',
      ]) {
        final Object? v = map[key];
        if (v is String) {
          final String u = v.trim();
          if (u.isNotEmpty) {
            return u;
          }
        }
      }
      final Object? contentVal = map['content'];
      if (contentVal != null) {
        final String? fromContent = _extractImageUrlFromJson(contentVal, depth: depth + 1);
        if (fromContent != null) {
          return fromContent;
        }
      }
      for (final Object? v in map.values) {
        final String? nested = _extractImageUrlFromJson(v, depth: depth + 1);
        if (nested != null) {
          return nested;
        }
      }
    }
    if (node is List) {
      for (final Object? e in node) {
        final String? nested = _extractImageUrlFromJson(e, depth: depth + 1);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  void _logHistoryImageParse(MessageDTO dto, String? parsedUrl, String branch) {
    imImageSendLog('history_rest_parse_image', <String, Object?>{
      'messageId': dto.id?.toString() ?? dto.msgId ?? '-',
      'msgType': (dto.msgType ?? -1).toString(),
      'branch': branch,
      'contentPreview': _truncateForHistoryLog(dto.content),
      'extraPreview': _truncateForHistoryLog(dto.extra),
      'parsedUrlLen': (parsedUrl ?? '').length.toString(),
      'parsedUrlPrefix': parsedUrl == null || parsedUrl.isEmpty
          ? ''
          : (parsedUrl.length > 120 ? '${parsedUrl.substring(0, 120)}…' : parsedUrl),
    });
  }

  /// 后端 [ConversationDTO]（见 hailiao-api ConversationController#convertToDTO）：
  /// - [ConversationDTO.id]：会话表主键，不是 WuKong channel，也不应作为聊天 target。
  /// - [ConversationDTO.userId]：会话所属用户（当前登录用户），不是对端。
  /// - [ConversationDTO.targetId]：对端用户 id（type=1）或业务群侧用于会话维度的 id（type=2），与 WuKong 对齐依赖后端写入。
  /// - [ConversationDTO.type]：1 私聊 / 2 群聊，与 WuKong channelType 1/2 一致。
  ConversationSummary mapConversation(ConversationDTO dto) {
    final int targetId = dto.targetId ?? 0;
    final int type = dto.type ?? 1;
    final String draft = (dto.draft ?? '').trim();
    final String lastMessage = draft.isNotEmpty
        ? '[草稿] $draft'
        : ((dto.lastMessage ?? '').trim().isNotEmpty
            ? dto.lastMessage!.trim()
            : '[暂无消息]');

    final ConversationSummary summary = ConversationSummary(
      conversationId: dto.id,
      targetId: targetId,
      type: type,
      title: _identity.resolveTitle(
        targetId,
        type,
        serverConversationName: dto.name,
      ),
      serverConversationName: dto.name,
      lastMessage: lastMessage,
      lastMessageTime: dto.lastMessageTime,
      unreadCount: dto.unreadCount ?? 0,
      draftText: draft.isNotEmpty ? draft : null,
      isTop: dto.isTop == true,
      isMuted: dto.isMute == true,
    );
    imConvSourceLog('mapConversation_to_summary', <String, Object?>{
      'sourceModel': 'ConversationDTO->ConversationSummary',
      'dto_targetId': dto.targetId?.toString() ?? 'null',
      'dto_type': dto.type?.toString() ?? 'null',
      'dto_id': dto.id?.toString() ?? 'null',
      'dto_userId': dto.userId?.toString() ?? 'null',
      'mapped_targetId': summary.targetId.toString(),
      'mapped_type': summary.type.toString(),
      'mapped_conversationId': summary.conversationId?.toString() ?? 'null',
      'title': summary.title,
    });
    imConvTitleLog('mapConversation', <String, Object?>{
      'conversationId': dto.id?.toString() ?? 'null',
      'dto_userId': dto.userId?.toString() ?? 'null',
      'dto_targetId': dto.targetId?.toString() ?? 'null',
      'dto_name': dto.name ?? '-',
      'dto_avatar': dto.avatar ?? '-',
      'type': type.toString(),
      'mapped_targetId': summary.targetId.toString(),
      'resolvedTitle': summary.title,
      'resolvedAvatar': dto.avatar ?? '-',
      'friendMap': 'IdentityResolver',
    });
    return summary;
  }

  ChatMessage mapMessage(
    MessageDTO dto, {
    required int targetId,
    required int type,
    int? currentUserId,
  }) {
    final bool isMine =
        currentUserId != null && dto.fromUserId != null && dto.fromUserId == currentUserId;
    final int? mt = dto.msgType;
    String text;
    String? imageUrl;
    if (mt == 2) {
      final String? fromContent = parseImageUrlFromHistoryContent(dto.content);
      late final String imageUrlResolved;
      late final String branch;
      if (fromContent != null && fromContent.trim().isNotEmpty) {
        imageUrlResolved = fromContent;
        branch = 'content';
      } else {
        final String? fromExtra = parseImageUrlFromHistoryContent(dto.extra);
        if (fromExtra != null && fromExtra.trim().isNotEmpty) {
          imageUrlResolved = fromExtra;
          branch = 'extra';
        } else {
          imageUrlResolved = '';
          branch = 'none';
        }
      }
      imageUrl = imageUrlResolved;
      text = '[图片]';
      _logHistoryImageParse(dto, imageUrl, branch);
    } else {
      text = (dto.content ?? '').trim().isNotEmpty
          ? dto.content!.trim()
          : '[暂无内容]';
    }

    final String? profileNick = dto.fromUserInfo?.nickname?.trim();
    return ChatMessage(
      id: _resolveMessageId(dto),
      serverId: dto.id,
      clientId: dto.clientMsgNo,
      targetId: targetId,
      type: type,
      senderId: dto.fromUserId,
      senderName: _identity.resolveDisplayNameForMessage(
        dto.fromUserId,
        chatType: type,
        chatTargetId: targetId,
        profileNickname:
            profileNick != null && profileNick.isNotEmpty ? profileNick : null,
      ),
      senderProfileNickname:
          profileNick != null && profileNick.isNotEmpty ? profileNick : null,
      text: text,
      imageUrl: imageUrl,
      createdAt: dto.createdAt,
      isMine: isMine,
      sendState: _mapSendState(
        dto.status,
        isRead: isMine && dto.isRead == true,
      ),
      localInboundRead: isMine
          ? true
          : (type == 1 ? (dto.isRead == true) : true),
    );
  }

  ChatMessage createOptimisticText({
    required int targetId,
    required int type,
    required int senderId,
    required String text,
    String? clientId,
  }) {
    final String resolvedClientId =
        clientId ?? 'local-${DateTime.now().microsecondsSinceEpoch}';
    imIdentityLog('optimistic_create', <String, Object?>{
      'senderId': senderId.toString(),
      'selfUserId': senderId.toString(),
      'channelId': '-',
      'channelType': type.toString(),
      'resolvedTargetId': targetId.toString(),
      'messageType': type.toString(),
      'cacheKey': ConversationIdentity.cacheKey(targetId, type),
      'clientId': resolvedClientId,
      'serverId': '-',
    });
    return ChatMessage(
      id: resolvedClientId,
      clientId: resolvedClientId,
      targetId: targetId,
      type: type,
      senderId: senderId,
      senderName: _identity.resolveDisplayNameForMessage(
        senderId,
        chatType: type,
        chatTargetId: targetId,
      ),
      text: text,
      imageUrl: null,
      createdAt: DateTime.now().toIso8601String(),
      isMine: true,
      sendState: MessageSendState.sending,
      localInboundRead: true,
    );
  }

  ChatMessage createOptimisticImage({
    required int targetId,
    required int type,
    required int senderId,
    required String imageUrl,
    String? clientId,
  }) {
    final String resolvedClientId =
        clientId ?? 'local-img-${DateTime.now().microsecondsSinceEpoch}';
    imIdentityLog('optimistic_create_image', <String, Object?>{
      'senderId': senderId.toString(),
      'selfUserId': senderId.toString(),
      'channelId': '-',
      'channelType': type.toString(),
      'resolvedTargetId': targetId.toString(),
      'messageType': type.toString(),
      'cacheKey': ConversationIdentity.cacheKey(targetId, type),
      'clientId': resolvedClientId,
      'serverId': '-',
    });
    return ChatMessage(
      id: resolvedClientId,
      clientId: resolvedClientId,
      targetId: targetId,
      type: type,
      senderId: senderId,
      senderName: _identity.resolveDisplayNameForMessage(
        senderId,
        chatType: type,
        chatTargetId: targetId,
      ),
      text: '[图片]',
      imageUrl: imageUrl,
      createdAt: DateTime.now().toIso8601String(),
      isMine: true,
      sendState: MessageSendState.sending,
      localInboundRead: true,
    );
  }

  ChatMessage? mapSdkMessage(
    WKMsg rawEvent, {
    required int? currentUserId,
  }) {
    final int? selfUserId = _resolveCurrentUserId(currentUserId);
    final int? senderId = _parseInt(rawEvent.fromUID);
    final int? resolvedTargetId = ConversationIdentity.resolveSdkTargetId(
      rawEvent,
      currentUserId: selfUserId,
    );

    if (resolvedTargetId == null) {
      imIdentityLog('mapSdkMessage_skip_null_target', <String, Object?>{
        'senderId': senderId?.toString(),
        'selfUserId': selfUserId?.toString(),
        'channelId': rawEvent.channelID,
        'channelType': rawEvent.channelType.toString(),
        'resolvedTargetId': 'null',
        'messageType': '-',
        'cacheKey': '-',
        'clientId': rawEvent.clientMsgNO.trim().isEmpty
            ? '-'
            : rawEvent.clientMsgNO.trim(),
        'serverId': rawEvent.messageID.isEmpty ? '-' : rawEvent.messageID,
      });
      return null;
    }

    final int type = rawEvent.channelType == WKChannelType.group ? 2 : 1;
    final bool incomingPrivateUnread =
        type == 1 &&
            selfUserId != null &&
            senderId != null &&
            senderId != selfUserId;
    final dynamic mc = rawEvent.messageContent;
    String? imageUrl;
    String text = _resolveSdkContent(rawEvent).trim();
    if (mc is WKImageContent) {
      imageUrl = _resolveSdkImageUrl(rawEvent, mc);
      text = '[图片]';
    }
    final String resolvedClientId = rawEvent.clientMsgNO.trim();
    final int? resolvedServerId =
        _parseInt(rawEvent.messageID) ??
        (rawEvent.messageSeq > 0 ? rawEvent.messageSeq : null);
    final String id =
        resolvedServerId?.toString() ??
        (resolvedClientId.isNotEmpty
            ? resolvedClientId
            : 'wk-${rawEvent.clientSeq}-${rawEvent.timestamp}');

    imIdentityLog('mapSdkMessage', <String, Object?>{
      'senderId': senderId?.toString(),
      'selfUserId': selfUserId?.toString(),
      'channelId': rawEvent.channelID,
      'channelType': rawEvent.channelType.toString(),
      'resolvedTargetId': resolvedTargetId.toString(),
      'messageType': type.toString(),
      'cacheKey': ConversationIdentity.cacheKey(resolvedTargetId, type),
      'clientId': resolvedClientId.isNotEmpty ? resolvedClientId : '-',
      'serverId': resolvedServerId?.toString() ?? '-',
    });

    return ChatMessage(
      id: id,
      serverId: resolvedServerId,
      clientId: resolvedClientId.isNotEmpty ? resolvedClientId : null,
      targetId: resolvedTargetId,
      type: type,
      senderId: senderId,
      senderName: _identity.resolveDisplayNameForMessage(
        senderId,
        chatType: type,
        chatTargetId: resolvedTargetId,
      ),
      text: text.isNotEmpty ? text : '[暂无内容]',
      imageUrl: imageUrl,
      createdAt: _formatSdkTimestamp(rawEvent.timestamp),
      isMine: selfUserId != null && senderId == selfUserId,
      sendState: _resolveSdkMessageState(
        rawEvent,
        currentUserId: selfUserId,
      ),
      localInboundRead: incomingPrivateUnread ? false : true,
    );
  }

  WukongImEvent? mapIncomingEvent(
    WKMsg rawEvent, {
    required int? currentUserId,
  }) {
    final ChatMessage? message = mapSdkMessage(
      rawEvent,
      currentUserId: currentUserId,
    );
    if (message == null) {
      return null;
    }
    return WukongImEvent.incoming(message);
  }

  WukongImEvent? mapRefreshEvent(
    WKMsg rawEvent, {
    required int? currentUserId,
  }) {
    final ChatMessage? message = mapSdkMessage(
      rawEvent,
      currentUserId: currentUserId,
    );
    if (message == null) {
      return null;
    }
    return WukongImEvent.refresh(
      message: message,
      sendState: _resolveSdkMessageState(
        rawEvent,
        currentUserId: currentUserId,
      ),
    );
  }

  MessageSendState mapSdkSendState(int? status) {
    switch (status) {
      case WKSendMsgResult.sendLoading:
        return MessageSendState.sending;
      case WKSendMsgResult.sendFail:
      case WKSendMsgResult.noRelation:
      case WKSendMsgResult.blackList:
      case WKSendMsgResult.notOnWhiteList:
        return MessageSendState.failed;
      default:
        return MessageSendState.sent;
    }
  }

  MessageSendState _mapSendState(int? status, {bool isRead = false}) {
    if (isRead) {
      return MessageSendState.read;
    }
    switch (status) {
      case 2:
        return MessageSendState.failed;
      case 0:
        return MessageSendState.sending;
      default:
        return MessageSendState.sent;
    }
  }

  MessageSendState _resolveSdkMessageState(
    WKMsg rawEvent, {
    required int? currentUserId,
  }) {
    if (_isOutgoingPrivateReadReceipt(rawEvent, currentUserId: currentUserId)) {
      return MessageSendState.read;
    }
    return mapSdkSendState(rawEvent.status);
  }

  String _resolveMessageId(MessageDTO dto) {
    final String raw = (dto.id?.toString() ??
            dto.clientMsgNo ??
            dto.msgId ??
            dto.createdAt ??
            '')
        .trim();
    return raw.isEmpty ? '${dto.hashCode}' : raw;
  }

  int? _resolveCurrentUserId(int? currentUserId) {
    if (currentUserId != null) {
      return currentUserId;
    }
    final String? uid = WKIM.shared.options.uid;
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return int.tryParse(uid);
  }

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  String _resolveSdkContent(WKMsg msg) {
    final dynamic messageContent = msg.messageContent;
    if (messageContent is WKTextContent && messageContent.content.isNotEmpty) {
      return messageContent.content;
    }

    final String? displayText = messageContent?.displayText();
    if (displayText != null && displayText.isNotEmpty) {
      return displayText;
    }

    return msg.content.toString();
  }

  String? _formatSdkTimestamp(dynamic timestamp) {
    final int? value = _parseInt(timestamp);
    if (value == null || value <= 0) {
      return null;
    }
    final int millis = value > 9999999999 ? value : value * 1000;
    return ChatDateFormat.fromMillis(millis);
  }

  bool _isOutgoingPrivateReadReceipt(
    WKMsg msg, {
    required int? currentUserId,
  }) {
    if (msg.channelType != WKChannelType.personal) {
      return false;
    }
    final WKMsgExtra? extra = msg.wkMsgExtra;
    if (extra == null || extra.readed <= 0) {
      return false;
    }
    final int? self = _resolveCurrentUserId(currentUserId);
    final int? senderId = _parseInt(msg.fromUID);
    return self != null && senderId == self;
  }
}
