import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_actions_sheet.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_body_types.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_bubble.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_inner_content.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_footer_meta.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_row.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_timeline.dart';
import 'package:hailiao_flutter/widgets/chat/chat_image_message_content.dart';
import 'package:hailiao_flutter/widgets/chat/chat_outgoing_meta_row.dart';
import 'package:hailiao_flutter/widgets/chat/chat_outgoing_status_meta_factory.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';
import 'package:hailiao_flutter/widgets/chat/chat_sender_name_label.dart';
import 'package:hailiao_flutter/widgets/chat/message_bubble_presenter.dart';
import 'package:hailiao_flutter/widgets/chat/message_dto_chat_display.dart';
import 'package:provider/provider.dart';

/// 己方图片发送失败：轻量底栏「重试 / 删除」（删除仅移除本地列表，与多选移除一致）。
Future<void> showFailedOutgoingImageActionSheet(
  BuildContext context, {
  required MessageDTO message,
  required Future<void> Function(MessageDTO message) onRetryOutgoingFailed,
}) {
  return showChatMessageActionsSheet(
    context,
    actions: <ChatSheetActionItem>[
      ChatSheetActionItem(
        icon: Icons.refresh_rounded,
        label: '重试发送',
        onTap: () {
          unawaited(onRetryOutgoingFailed(message));
        },
      ),
      ChatSheetActionItem(
        icon: Icons.delete_outline,
        label: '删除消息',
        destructive: true,
        onTap: () {
          final int? id = message.id;
          if (id == null) {
            return;
          }
          context.read<MessageProvider>().removeMessagesLocal(<int>[id]);
        },
      ),
    ],
  );
}

/// 单条消息的完整气泡与行布局（头像、多选、状态 meta），与聊天页原 [_buildMessageBubble] 对齐。
class ChatThreadMessageBubble extends StatelessWidget {
  const ChatThreadMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.allMessages,
    required this.selectionMode,
    required this.selectedMessageIds,
    required this.highlightedMessageId,
    required this.scene,
    required this.onShowMessageActions,
    required this.onToggleSelection,
    required this.onOpenMediaPreview,
    required this.onOpenMediaDetails,
    required this.audioDurationLabel,
    required this.onRetryOutgoingFailed,
    this.groupSenderLabel,
  });

  final MessageDTO message;
  /// 群聊对方发送者昵称（已由列表项按规则算出，为 null 则不展示）。
  final String? groupSenderLabel;
  final bool isCurrentUser;
  final List<MessageDTO> allMessages;
  final bool selectionMode;
  final Set<int> selectedMessageIds;
  final int? highlightedMessageId;
  final ChatScene scene;
  final void Function(MessageDTO message, bool isCurrentUser) onShowMessageActions;
  final void Function(MessageDTO message) onToggleSelection;
  final Future<void> Function(MessageDTO message) onOpenMediaPreview;
  final Future<void> Function(MessageDTO message) onOpenMediaDetails;
  final String? Function(MessageDTO message) audioDurationLabel;
  final Future<void> Function(MessageDTO message) onRetryOutgoingFailed;

  @override
  Widget build(BuildContext context) {
    final MessageDTO? replyTarget =
        MessageBubblePresenter.findReplyTarget(message.replyToMsgId, allMessages);
    final bool isHighlighted = highlightedMessageId == message.id;
    final bool isSelected =
        message.id != null && selectedMessageIds.contains(message.id);

    final bool standaloneImageLayout = !message.isRecalledMessage &&
        message.safeBodyType == ChatMessageBodyTypes.image;

    final bool embedOutgoingTextMeta =
        isCurrentUser && !message.isRecalledMessage && message.showsTextBubblePayload;
    final Widget? outgoingStatusMeta = isCurrentUser && !message.isRecalledMessage
        ? ChatOutgoingStatusMetaFactory.build(
            message: message,
            scene: scene,
            textTailInline: embedOutgoingTextMeta,
            onFailedTap: message.isOutgoingStatusFailed
                ? () => unawaited(onRetryOutgoingFailed(message))
                : null,
          )
        : null;

    Widget? imageOverlayMeta = standaloneImageLayout
        ? _imageBubbleOverlayMeta(
            context: context,
            message: message,
            isCurrentUser: isCurrentUser,
            scene: scene,
          )
        : null;

    /// 与 [_imageBubbleOverlayMeta] 判定极少数分支若漂移，仍保证己方图片有可读的叠层 meta。
    if (standaloneImageLayout &&
        isCurrentUser &&
        !message.isRecalledMessage &&
        imageOverlayMeta == null) {
      final Widget? fromFactory = ChatOutgoingStatusMetaFactory.build(
        message: message,
        scene: scene,
        textTailInline: true,
        onFailedTap: message.isOutgoingStatusFailed
            ? () => unawaited(showFailedOutgoingImageActionSheet(
                  context,
                  message: message,
                  onRetryOutgoingFailed: onRetryOutgoingFailed,
                ))
            : null,
      );
      if (fromFactory != null) {
        imageOverlayMeta = IconTheme(
          data: IconThemeData(
            color: Colors.white.withValues(alpha: 0.95),
            size: ChatUiTokens.metaIconSize,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: ChatUiTokens.metaFontSize,
            ),
            child: fromFactory,
          ),
        );
      }
    }

    Widget bubbleChild = standaloneImageLayout
        ? ChatImageMessageContent(
            path: message.content ?? '',
            onTap: () => unawaited(onOpenMediaPreview(message)),
            label: isCurrentUser ? null : '图片消息',
            bottomTrailingMeta: imageOverlayMeta,
          )
        : ChatMessageInnerContent(
            message: message,
            isCurrentUser: isCurrentUser,
            isHighlighted: isHighlighted,
            outgoingInlineMeta:
                embedOutgoingTextMeta ? outgoingStatusMeta : null,
            onImageOrVideoTap: () => unawaited(onOpenMediaPreview(message)),
            onAudioTap: () => unawaited(onOpenMediaDetails(message)),
            onFileTap: () => unawaited(onOpenMediaDetails(message)),
            audioDurationLabel: audioDurationLabel,
          );

    if (isCurrentUser &&
        !message.isRecalledMessage &&
        !embedOutgoingTextMeta &&
        outgoingStatusMeta != null &&
        !standaloneImageLayout) {
      bubbleChild = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          bubbleChild,
          SizedBox(height: ChatUiTokens.bubbleContentToMetaGap),
          outgoingStatusMeta,
        ],
      );
    } else if (!isCurrentUser &&
        !message.isRecalledMessage &&
        message.isEdited == true &&
        !standaloneImageLayout) {
      bubbleChild = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          bubbleChild,
          SizedBox(height: ChatUiTokens.bubbleContentToMetaGap),
          const ChatMessageIncomingFooterLine(
            text: '已编辑',
            isFromPeer: true,
          ),
        ],
      );
    }

    final String? replySummary = replyTarget?.replyPreviewSummary;

    final bool strip = message.isConversationNoticeStrip;
    final Widget? aboveBubble =
        (groupSenderLabel == null || strip)
            ? null
            : ChatSenderNameLabel(name: groupSenderLabel!);

    return ChatMessageRow(
      isCurrentUser: isCurrentUser,
      selectionMode: selectionMode,
      selectionValue: isSelected,
      outgoingLeadingAccessory: null,
      omitSideAvatars: strip,
      aboveBubble: aboveBubble,
      alignBubbleToTop: standaloneImageLayout,
      onLongPress: () => onShowMessageActions(message, isCurrentUser),
      onTap: selectionMode ? () => onToggleSelection(message) : null,
      onSelectionToggle: () => onToggleSelection(message),
      child: ChatMessageBubble(
        isCurrentUser: isCurrentUser,
        isHighlighted: isHighlighted,
        isSelected: isSelected,
        selectionMode: selectionMode,
        selectionValue: isSelected,
        isForwarded: message.forwardFromMsgId != null,
        replySummary: replySummary,
        footer: null,
        contentPadding: _bubbleContentPadding(message, isCurrentUser, strip),
        omitBubbleFill: standaloneImageLayout,
        child: bubbleChild,
      ),
    );
  }

  /// 与 [ChatOutgoingStatusMetaFactory] 判定一致，颜色改为叠在图上可读的反色。
  Widget? _imageBubbleOverlayMeta({
    required BuildContext context,
    required MessageDTO message,
    required bool isCurrentUser,
    required ChatScene scene,
  }) {
    if (message.isRecalledMessage) {
      return null;
    }
    final Color onPhoto =
        Colors.white.withValues(alpha: 0.95);
    if (isCurrentUser) {
      final ChatOutgoingReceipt? receipt =
          MessageBubblePresenter.resolveOutgoingReceipt(message, scene);
      final String? hm = ChatMessageTimeline.shortHourMinute(message);
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
        metaColor: onPhoto,
        compact: true,
        textTailInline: true,
        isGroupChat: scene.isGroupChat,
        onFailedTap: message.isOutgoingStatusFailed
            ? () => unawaited(showFailedOutgoingImageActionSheet(
                  context,
                  message: message,
                  onRetryOutgoingFailed: onRetryOutgoingFailed,
                ))
            : null,
      );
    }
    final String? hm = ChatMessageTimeline.shortHourMinute(message);
    if ((hm == null || hm.isEmpty) && message.isEdited != true) {
      return null;
    }
    return ChatMessageFooterMeta(
      shortTime: hm,
      showEdited: message.isEdited == true,
      compact: true,
      metaColor: onPhoto,
      textTailInline: true,
    );
  }

  /// 文本 / 媒体 / 文件音频分别使用 token padding；notice 条走兜底。
  static EdgeInsets? _bubbleContentPadding(
    MessageDTO message,
    bool isCurrentUser,
    bool noticeStrip,
  ) {
    if (noticeStrip) {
      return null;
    }
    if (message.showsTextBubblePayload) {
      return isCurrentUser
          ? ChatUiTokens.outgoingTextBubblePadding
          : ChatUiTokens.incomingTextBubblePadding;
    }
    switch (message.safeBodyType) {
      case ChatMessageBodyTypes.image:
        return EdgeInsets.zero;
      case ChatMessageBodyTypes.video:
        return ChatUiTokens.mediaBubblePadding;
      case ChatMessageBodyTypes.audio:
      case ChatMessageBodyTypes.file:
        return ChatUiTokens.fileAudioBubblePadding;
      default:
        return null;
    }
  }
}
