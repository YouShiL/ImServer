import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:wukongimfluttersdk/entity/msg.dart';
import 'package:wukongimfluttersdk/model/wk_text_content.dart';
import 'package:wukongimfluttersdk/type/const.dart';

/// Maps raw IM SDK events into the minimal parameters expected by
/// MessageProvider. This file intentionally avoids any Provider, UI, or SDK
/// runtime dependency and only defines conversion skeletons.
class ImEventMapper {
  const ImEventMapper();

  MessageDTO? mapIncomingMessage(Object? rawEvent) {
    if (rawEvent is! WKMsg) {
      return null;
    }

    final channelType = rawEvent.channelType;
    final targetId = _parseInt(rawEvent.channelID);
    final isGroup = channelType != WKChannelType.personal;
    final content = _resolveContent(rawEvent);

    return MessageDTO(
      id: _parseInt(rawEvent.messageID) ?? rawEvent.messageSeq,
      fromUserId: _parseInt(rawEvent.fromUID),
      toUserId: isGroup ? null : targetId,
      groupId: isGroup ? targetId : null,
      content: content,
      msgType: _mapContentType(rawEvent.contentType),
      // TODO: Confirm the SDK's read/view flag field before mapping isRead.
      status: _mapSdkStatus(rawEvent.status),
      createdAt: _formatTimestamp(rawEvent.timestamp),
    );
  }

  List<MessageDTO> mapIncomingMessages(Object? rawEvent) {
    if (rawEvent is List) {
      return rawEvent
          .map(mapIncomingMessage)
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

  int mapSendSuccessStatus(Object? rawEvent) {
    // Current app semantics in chat_screen.dart:
    // 0 => sending
    // non-zero => sent
    // We map successful SDK refresh/ack events to 1 so the UI renders "已发送".
    return 1;
  }

  int mapSendFailureStatus(Object? rawEvent) {
    // Current app semantics only distinguish:
    // 0 => sending
    // non-zero => sent
    // There is no dedicated failure rendering path yet, so we conservatively
    // map failure to 0 to avoid incorrectly showing "已发送".
    return 0;
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
    // Current project semantics:
    // 0 => sending
    // non-zero => sent
    return sdkStatus == WKSendMsgResult.sendLoading ? 0 : 1;
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
    return DateTime.fromMillisecondsSinceEpoch(millis).toIso8601String();
  }
}
