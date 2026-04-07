import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/theme/chat_date_format.dart';
import 'package:wukongimfluttersdk/entity/msg.dart';
import 'package:wukongimfluttersdk/model/wk_text_content.dart';
import 'package:wukongimfluttersdk/type/const.dart';

/// Maps raw IM SDK events into the minimal parameters expected by
/// MessageProvider. This file intentionally avoids any Provider, UI, or SDK
/// runtime dependency and only defines conversion skeletons.
class ImEventMapper {
  const ImEventMapper();

  MessageDTO? mapIncomingMessage(
    Object? rawEvent, {
    int? currentUserId,
  }) {
    if (rawEvent is! WKMsg) {
      return null;
    }

    final channelType = rawEvent.channelType;
    final targetId = _parseInt(rawEvent.channelID);
    final isGroup = channelType != WKChannelType.personal;
    final content = _resolveContent(rawEvent);
    final int? fromUid = _parseInt(rawEvent.fromUID);

    /// 私聊 channelID 一般为会话对方；对方发来的行 [toUserId] 应对齐 REST（收件人为当前用户）。
    int? privateToUserId;
    if (!isGroup) {
      if (currentUserId != null && fromUid != null) {
        privateToUserId =
            fromUid == currentUserId ? targetId : currentUserId;
      } else {
        privateToUserId = targetId;
      }
    }

    return MessageDTO(
      id: _parseInt(rawEvent.messageID) ??
          _parseInt(rawEvent.clientSeq) ??
          rawEvent.messageSeq,
      fromUserId: fromUid,
      toUserId: isGroup ? null : privateToUserId,
      groupId: isGroup ? targetId : null,
      content: content,
      msgType: _mapContentType(rawEvent.contentType),
      // TODO: Confirm the SDK's read/view flag field before mapping isRead.
      status: _mapSdkStatus(rawEvent.status),
      createdAt: _formatTimestamp(rawEvent.timestamp),
    );
  }

  List<MessageDTO> mapIncomingMessages(
    Object? rawEvent, {
    int? currentUserId,
  }) {
    if (rawEvent is List) {
      return rawEvent
          .map((e) => mapIncomingMessage(e, currentUserId: currentUserId))
          .whereType<MessageDTO>()
          .toList(growable: false);
    }

    // TODO: Handle SDK batch container shapes if they differ from List<WKMsg>.
    return const <MessageDTO>[];
  }

  int? mapLocalMessageId(Object? rawEvent) {
    if (rawEvent is! WKMsg) {
      return null;
    }

    // The current app matches send-result updates by integer id.
    // Prefer messageId when present; fall back to clientSeq if the SDK has not
    // yet assigned a stable server id.
    return _parseInt(rawEvent.messageID) ?? _parseInt(rawEvent.clientSeq);
  }

  int? mapServerMessageId(Object? rawEvent) {
    if (rawEvent is! WKMsg) {
      return null;
    }

    return _parseInt(rawEvent.messageID) ?? rawEvent.messageSeq;
  }

  /// App-layer [MessageDTO.msgType] (1 text, 2 image, 3 voice, 4 video).
  int? mapAppMsgType(Object? rawEvent) {
    if (rawEvent is! WKMsg) {
      return null;
    }
    return _mapContentType(rawEvent.contentType);
  }

  int mapSendSuccessStatus(Object? rawEvent) {
    // 0 => sending, 1 => sent, 2 => failed (see chat UI).
    if (rawEvent is! WKMsg) {
      return 1;
    }
    if (rawEvent.status == WKSendMsgResult.sendLoading) {
      return 0;
    }
    return 1;
  }

  int mapSendFailureStatus(Object? rawEvent) {
    return WKSendMsgResult.sendFail;
  }

  String? mapUpdatedContent(Object? rawEvent) {
    if (rawEvent is! WKMsg) {
      return null;
    }

    return _resolveContent(rawEvent);
  }

  int? mapReadReceiptTargetId(Object? rawEvent) {
    // TODO: Extract the conversation target id for a read receipt event.
    return null;
  }

  int? mapReadReceiptType(Object? rawEvent) {
    // TODO: Extract the conversation type (e.g. 1 private / 2 group).
    return null;
  }

  int? mapReadReceiptUnreadCount(Object? rawEvent) {
    // TODO: Extract the unread count after a read-receipt sync.
    return 0;
  }

  int? mapRecallMessageId(Object? rawEvent) {
    // TODO: Extract the recalled message id.
    return null;
  }

  int? mapEditedMessageId(Object? rawEvent) {
    // TODO: Extract the edited message id.
    return null;
  }

  int? mapConversationUnreadTargetId(Object? rawEvent) {
    // TODO: Extract the target id from a conversation unread-sync event.
    return null;
  }

  int? mapConversationUnreadType(Object? rawEvent) {
    // TODO: Extract the conversation type from a conversation unread-sync event.
    return null;
  }

  int? mapConversationUnreadCount(Object? rawEvent) {
    // TODO: Extract the unread count from a conversation unread-sync event.
    return null;
  }

  int _mapContentType(int sdkContentType) {
    if (sdkContentType == WkMessageContentType.image) {
      return 2;
    }
    if (sdkContentType == WkMessageContentType.voice) {
      return 3;
    }
    if (sdkContentType == WkMessageContentType.video) {
      return 4;
    }
    return 1;
  }

  int _mapSdkStatus(int sdkStatus) {
    if (sdkStatus == WKSendMsgResult.sendLoading) {
      return 0;
    }
    if (sdkStatus == WKSendMsgResult.sendFail ||
        sdkStatus == WKSendMsgResult.noRelation ||
        sdkStatus == WKSendMsgResult.blackList ||
        sdkStatus == WKSendMsgResult.notOnWhiteList) {
      return WKSendMsgResult.sendFail;
    }
    return 1;
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

  String _resolveContent(WKMsg msg) {
    final messageContent = msg.messageContent;
    if (messageContent is WKTextContent && messageContent.content.isNotEmpty) {
      return messageContent.content;
    }

    final displayText = messageContent?.displayText();
    if (displayText != null && displayText.isNotEmpty) {
      return displayText;
    }

    final raw = msg.content;
    return raw.toString();
  }

  String? _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return null;
    }

    int? value;
    if (timestamp is int) {
      value = timestamp;
    } else if (timestamp is num) {
      value = timestamp.toInt();
    } else {
      value = int.tryParse(timestamp.toString());
    }
    if (value == null || value <= 0) {
      return null;
    }

    final millis = value > 9999999999 ? value : value * 1000;
    return ChatDateFormat.fromMillis(millis);
  }
}
