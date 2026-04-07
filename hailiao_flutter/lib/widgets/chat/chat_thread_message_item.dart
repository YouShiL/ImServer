import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_timeline.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';
import 'package:hailiao_flutter/widgets/chat/chat_thread_message_bubble.dart';
import 'package:hailiao_flutter/widgets/chat/chat_time_separator.dart';
import 'package:hailiao_flutter/widgets/chat/message_bubble_presenter.dart';
import 'package:hailiao_flutter/widgets/chat/message_dto_chat_display.dart';

/// 列表中单条消息：时间分隔 + [ChatThreadMessageBubble]。
class ChatThreadMessageItem extends StatelessWidget {
  const ChatThreadMessageItem({
    super.key,
    required this.message,
    required this.index,
    required this.messages,
    required this.currentUserId,
    required this.historyBoundaryIndex,
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
    required this.onSelectMessagesForDate,
  });

  final MessageDTO message;
  final int index;
  final List<MessageDTO> messages;
  final int? currentUserId;
  final int? historyBoundaryIndex;
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
  final void Function(String bucket) onSelectMessagesForDate;

  @override
  Widget build(BuildContext context) {
    final bool showTimeSep = ChatMessageTimeline.needTimeSeparator(
      index: index,
      messages: messages,
      historyBoundaryIndex: historyBoundaryIndex,
    );
    final bool isOutgoing = message.isSameSenderAs(currentUserId);
    final bool noticeStrip = message.isConversationNoticeStrip;
    final MessageDTO? previous =
        index > 0 ? messages[index - 1] : null;
    final int? uid = currentUserId;
    final String? groupSenderLabel = uid != null &&
            MessageBubblePresenter.shouldShowGroupSenderName(
              scene: scene,
              currentUserId: uid,
              message: message,
              previousSameThreadMessage: previous,
            )
        ? message.displaySenderFallbackName
        : null;

    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: noticeStrip
            ? Alignment.center
            : (isOutgoing ? Alignment.centerRight : Alignment.centerLeft),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ChatUiTokens.messageContentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: noticeStrip
                ? CrossAxisAlignment.center
                : (isOutgoing
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (showTimeSep)
                Align(
                  alignment: Alignment.center,
                  child: ChatTimeSeparator(
                    label: ChatMessageTimeline.formatSeparatorLabel(message),
                    trailing: selectionMode
                        ? GestureDetector(
                            onTap: () {
                              final String? b =
                                  ChatMessageTimeline.dateKey(message);
                              if (b != null) {
                                onSelectMessagesForDate(b);
                              }
                            },
                            child: Icon(
                              Icons.checklist_rtl_outlined,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                          )
                        : null,
                  ),
                ),
              ChatThreadMessageBubble(
                message: message,
                isCurrentUser: isOutgoing,
                allMessages: messages,
                selectionMode: selectionMode,
                selectedMessageIds: selectedMessageIds,
                highlightedMessageId: highlightedMessageId,
                scene: scene,
                groupSenderLabel: groupSenderLabel,
                onShowMessageActions: onShowMessageActions,
                onToggleSelection: onToggleSelection,
                onOpenMediaPreview: onOpenMediaPreview,
                onOpenMediaDetails: onOpenMediaDetails,
                audioDurationLabel: audioDurationLabel,
                onRetryOutgoingFailed: onRetryOutgoingFailed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
