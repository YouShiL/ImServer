import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/widgets/chat/chat_outgoing_receipt.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';
import 'package:hailiao_flutter/widgets/chat/message_dto_chat_display.dart';

/// 依赖 [ChatScene]、**邻消息**或**消息列表**的展示规则（单靠一条 [MessageDTO] 无法判定）。
///
/// **放这儿：** `resolve*`、`shouldShow*`、`find*`（跨列表）；**不放：** 仅依赖单条的 getter（见 [MessageDTOChatDisplay]）、时间格式（见 [ChatMessageTimeline]）、Widget 拼装。
abstract final class MessageBubblePresenter {
  MessageBubblePresenter._();

  /// 己方消息送达标记：群聊成功态无勾；单聊含已读/未读勾。
  static ChatOutgoingReceipt? resolveOutgoingReceipt(
    MessageDTO message,
    ChatScene scene,
  ) {
    if (message.isRecalledMessage) {
      return null;
    }
    if (scene.isGroupChat) {
      if (message.isOutgoingStatusSending) {
        return ChatOutgoingReceipt.sending;
      }
      if (message.isOutgoingStatusFailed) {
        return ChatOutgoingReceipt.failed;
      }
      return null;
    }
    if (message.isOutgoingStatusSending) {
      return ChatOutgoingReceipt.sending;
    }
    if (message.isOutgoingStatusFailed) {
      return ChatOutgoingReceipt.failed;
    }
    if (message.isRead == true) {
      return ChatOutgoingReceipt.read;
    }
    return ChatOutgoingReceipt.sentUnread;
  }

  /// 在列表中按 id 查找被回复消息（列表上下文）。
  static MessageDTO? findReplyTarget(int? id, List<MessageDTO> messages) {
    if (id == null) {
      return null;
    }
    for (final MessageDTO message in messages) {
      if (message.id == id) {
        return message;
      }
    }
    return null;
  }

  /// 群聊且非己方时，是否在昵称位显示发送者名称。
  /// 相邻同发送者折叠：与上一条非同一 fromUserId 时显示（含列表首条）。
  static bool shouldShowGroupSenderName({
    required ChatScene scene,
    required int currentUserId,
    required MessageDTO message,
    MessageDTO? previousSameThreadMessage,
  }) {
    if (scene != ChatScene.group) {
      return false;
    }
    if (message.isSystemLike) {
      return false;
    }
    if (message.isRecalledMessage) {
      return false;
    }
    if (message.isFromCurrentUser(currentUserId)) {
      return false;
    }
    final String? id = message.fromUserId?.toString();
    if (id == null || id.isEmpty) {
      return true;
    }
    if (previousSameThreadMessage == null) {
      return true;
    }
    final String? prevId = previousSameThreadMessage.fromUserId?.toString();
    if (prevId == null || prevId.isEmpty) {
      return true;
    }
    return id != prevId;
  }
}
