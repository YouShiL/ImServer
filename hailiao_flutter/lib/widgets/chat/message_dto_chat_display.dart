import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_body_types.dart';

/// 单条 [MessageDTO] 的展示派生属性：只读当前这条消息的字段即可得到。
///
/// **放这儿：** `is*` / `safe*` / `display*` / `shows*` 等；**不放：** 依赖 [ChatScene]、上一条消息、`index`、整表查找（见 [MessageBubblePresenter]）；**时间文案**见 [ChatMessageTimeline]。
extension MessageDTOChatDisplay on MessageDTO {
  /// 系统/事件类占位：约定 `fromUserId == 0` 为系统发送（与 `null` 区分）。
  bool get isSystemLike => fromUserId == 0;

  bool isFromCurrentUser(int currentUserId) => fromUserId == currentUserId;

  /// 与列表「己方」判断一致：显式使用 `fromUserId == currentUserId`（含双方均为 `null` 时为 true）。
  bool isSameSenderAs(int? currentUserId) => fromUserId == currentUserId;

  bool get isRecalledMessage => isRecalled == true;

  /// 会话级弱提示行（不占两侧头像带等）；当前与 [isRecalledMessage] 一致。
  bool get isConversationNoticeStrip => isRecalledMessage;

  bool get isOutgoingStatusFailed => (status ?? 1) == 2;

  bool get isOutgoingStatusSending => (status ?? 1) == 0;

  int get safeBodyType => msgType ?? ChatMessageBodyTypes.text;

  /// 文本气泡 payload（缺省 msgType 视为文本）。
  bool get showsTextBubblePayload => safeBodyType == ChatMessageBodyTypes.text;

  /// 群线程等：展示用发送者名（昵称优先，否则 `用户id`）。
  String get displaySenderFallbackName {
    final String? nickname = fromUserInfo?.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    final int? id = fromUserId;
    if (id != null) {
      return '用户$id';
    }
    return '用户';
  }

  /// 回复引用条摘要（与聊天气泡 reply chip 行为对齐）。
  String get replyPreviewSummary {
    switch (safeBodyType) {
      case ChatMessageBodyTypes.image:
        return '[图片]';
      case ChatMessageBodyTypes.audio:
        return '[音频]';
      case ChatMessageBodyTypes.video:
        return '[视频]';
      case ChatMessageBodyTypes.file:
        return '[文件]';
      default:
        return EmojiList.replacePlaceholders(content ?? '');
    }
  }
}
