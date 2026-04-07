import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_timeline.dart';
import 'package:hailiao_flutter/widgets/chat/chat_outgoing_meta_row.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';
import 'package:hailiao_flutter/widgets/chat/message_bubble_presenter.dart';
import 'package:hailiao_flutter/widgets/chat/message_dto_chat_display.dart';

/// 己方气泡内统一 Meta 行（文本 / 图片 / 视频 / 音频 / 文件共用）的**组装入口**。
///
/// 送达态只调 [MessageBubblePresenter.resolveOutgoingReceipt]；时间只调 [ChatMessageTimeline.shortHourMinute]；**不在此重复推导**撤回/已读等业务状态。空行则返回 null。
abstract final class ChatOutgoingStatusMetaFactory {
  ChatOutgoingStatusMetaFactory._();

  static Widget? build({
    required MessageDTO message,
    required ChatScene scene,
    required bool textTailInline,
    required VoidCallback? onFailedTap,
  }) {
    if (message.isRecalledMessage) {
      return null;
    }

    final ChatOutgoingReceipt? receipt =
        MessageBubblePresenter.resolveOutgoingReceipt(message, scene);
    final String? hm = ChatMessageTimeline.shortHourMinute(message);
    const Color metaColor = ChatUiTokens.outgoingMetaText;

    if (scene.isGroupChat &&
        receipt == null &&
        hm == null &&
        message.isEdited != true) {
      return null;
    }

    return ChatOutgoingMetaRow(
      shortTime: hm,
      receipt: receipt,
      showEdited: message.isEdited == true,
      metaColor: metaColor,
      compact: true,
      textTailInline: textTailInline,
      isGroupChat: scene.isGroupChat,
      onFailedTap: onFailedTap,
    );
  }
}
