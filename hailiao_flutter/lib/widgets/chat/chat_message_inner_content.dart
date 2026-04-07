import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_audio_message_content.dart';
import 'package:hailiao_flutter/widgets/chat/chat_file_message_content.dart';
import 'package:hailiao_flutter/widgets/chat/chat_image_message_content.dart';
import 'package:hailiao_flutter/widgets/chat/chat_system_message_content.dart';
import 'package:hailiao_flutter/widgets/chat/chat_text_message_content.dart';
import 'package:hailiao_flutter/widgets/chat/chat_unknown_message_content.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_body_types.dart';
import 'package:hailiao_flutter/widgets/chat/chat_video_message_content.dart';
import 'package:hailiao_flutter/widgets/chat/message_dto_chat_display.dart';

/// 单条消息主内容区（不含气泡壳与 meta 叠层）：按类型分发给独立内容组件。
class ChatMessageInnerContent extends StatelessWidget {
  const ChatMessageInnerContent({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isHighlighted = false,
    this.outgoingInlineMeta,
    required this.onImageOrVideoTap,
    required this.onAudioTap,
    required this.onFileTap,
    required this.audioDurationLabel,
  });

  final MessageDTO message;
  final bool isCurrentUser;
  final bool isHighlighted;
  final Widget? outgoingInlineMeta;
  final VoidCallback onImageOrVideoTap;
  final VoidCallback onAudioTap;
  final VoidCallback onFileTap;
  final String? Function(MessageDTO message) audioDurationLabel;

  Color get _bodyTextColor => isHighlighted
      ? const Color(0xFF333333)
      : (isCurrentUser
          ? ChatUiTokens.outgoingBubbleText
          : ChatUiTokens.incomingBubbleText);

  Color get _recalledTextColor => isHighlighted
      ? ChatUiTokens.systemMessageText
      : (isCurrentUser
          ? ChatUiTokens.outgoingMetaText
          : ChatUiTokens.systemMessageText);

  String? _payloadPreviewForUnknown(String? raw) {
    final String t = (raw ?? '').trim();
    if (t.isEmpty) {
      return null;
    }
    const int max = 80;
    if (t.length <= max) {
      return t;
    }
    return '${t.substring(0, max)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (message.isRecalledMessage) {
      return ChatSystemMessageContent(
        text: '消息已撤回',
        textColor: _recalledTextColor,
      );
    }

    final int t = message.safeBodyType;

    switch (t) {
      case ChatMessageBodyTypes.image:
        return ChatImageMessageContent(
          path: message.content ?? '',
          onTap: onImageOrVideoTap,
          label: isCurrentUser ? null : '图片消息',
        );
      case ChatMessageBodyTypes.video:
        return ChatVideoMessageContent(
          path: message.content ?? '',
          onTap: onImageOrVideoTap,
          peerLabel: isCurrentUser ? null : '视频消息',
        );
      case ChatMessageBodyTypes.audio:
        return ChatAudioMessageContent(
          isCurrentUser: isCurrentUser,
          onTap: onAudioTap,
          durationLabel: audioDurationLabel(message),
          isHighlighted: isHighlighted,
        );
      case ChatMessageBodyTypes.file:
        return ChatFileMessageContent(
          path: message.content ?? '',
          isCurrentUser: isCurrentUser,
          isHighlighted: isHighlighted,
          onTap: onFileTap,
        );
      case ChatMessageBodyTypes.text:
        return ChatTextMessageContent(
          text: EmojiList.replacePlaceholders(message.content ?? ''),
          textColor: _bodyTextColor,
          outgoingAlignEnd: isCurrentUser,
          inlineMeta: outgoingInlineMeta,
        );
      default:
        return ChatUnknownMessageContent(
          msgType: t,
          payloadPreview: _payloadPreviewForUnknown(message.content),
        );
    }
  }
}
