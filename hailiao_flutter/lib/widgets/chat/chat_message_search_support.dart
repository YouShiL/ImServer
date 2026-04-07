// 搜索/筛选辅助：文案与类型分支统一走 [MessageDTOChatDisplay] + [ChatMessageBodyTypes]。

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/theme/chat_date_format.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_body_types.dart';
import 'package:hailiao_flutter/widgets/chat/message_dto_chat_display.dart';

String chatSearchMessageTypeLabel(MessageDTO message) {
  switch (message.safeBodyType) {
    case ChatMessageBodyTypes.image:
      return '图片';
    case ChatMessageBodyTypes.audio:
      return '音频';
    case ChatMessageBodyTypes.video:
      return '视频';
    case ChatMessageBodyTypes.file:
      return '文件';
    default:
      return '文本';
  }
}

String chatSearchMessagePathLabel(MessageDTO message) {
  final c = message.content ?? '';
  return c.isEmpty ? '-' : c;
}

String chatSearchSummary(MessageDTO? message) {
  if (message == null) {
    return '';
  }
  if (message.isRecalledMessage) {
    return '此消息已撤回';
  }
  switch (message.safeBodyType) {
    case ChatMessageBodyTypes.image:
      return '[图片]';
    case ChatMessageBodyTypes.audio:
      return '[音频]';
    case ChatMessageBodyTypes.video:
      return '[视频]';
    case ChatMessageBodyTypes.file:
      return '[文件]';
    default:
      final text =
          EmojiList.replacePlaceholders(message.content ?? '').trim();
      return text.isEmpty ? '[文本消息]' : text;
  }
}

String chatSearchMediaSummaryText(MessageDTO message) {
  return [
    '类型：${chatSearchMessageTypeLabel(message)}',
    '时间：${ChatDateFormat.display(message.createdAt) ?? '-'}',
    '路径：${chatSearchMessagePathLabel(message)}',
  ].join('\n');
}

String chatSearchResultContext(MessageDTO message, String senderLabel) {
  final tags = <String>[
    chatSearchMessageTypeLabel(message),
    senderLabel,
    if (message.forwardFromMsgId != null) '转发',
    if (message.replyToMsgId != null) '回复',
    if (message.isEdited == true) '已编辑',
  ];
  return [
    ChatDateFormat.display(message.createdAt) ?? '',
    tags.join(' · '),
  ].where((part) => part.isNotEmpty).join(' · ');
}

bool chatSearchMatchesTypeFilter(MessageDTO message, String filter) {
  switch (filter) {
    case '文本':
      return message.showsTextBubblePayload;
    case '图片':
      return message.safeBodyType == ChatMessageBodyTypes.image;
    case '音频':
      return message.safeBodyType == ChatMessageBodyTypes.audio;
    case '视频':
      return message.safeBodyType == ChatMessageBodyTypes.video;
    default:
      return true;
  }
}

bool chatSearchMatchesSenderFilter(
  MessageDTO message,
  String filter,
  int? currentUserId,
) {
  switch (filter) {
    case '我发的':
      return message.isSameSenderAs(currentUserId);
    case '对方发送':
      return !message.isSameSenderAs(currentUserId);
    default:
      return true;
  }
}

IconData chatSearchMessageTypeIcon(MessageDTO message) {
  switch (message.safeBodyType) {
    case ChatMessageBodyTypes.image:
      return Icons.image_outlined;
    case ChatMessageBodyTypes.audio:
      return Icons.mic_none_outlined;
    case ChatMessageBodyTypes.video:
      return Icons.videocam_outlined;
    case ChatMessageBodyTypes.file:
      return Icons.insert_drive_file_outlined;
    default:
      return Icons.chat_bubble_outline;
  }
}

Map<String, int> chatSearchMessageTypeStats(List<MessageDTO> messages) {
  return <String, int>{
    '文本': messages.where((item) => item.showsTextBubblePayload).length,
    '图片': messages.where((item) => item.safeBodyType == ChatMessageBodyTypes.image).length,
    '音频': messages.where((item) => item.safeBodyType == ChatMessageBodyTypes.audio).length,
    '视频': messages.where((item) => item.safeBodyType == ChatMessageBodyTypes.video).length,
  };
}

TextSpan chatSearchHighlightedSummarySpan(
  MessageDTO message,
  String keyword,
) {
  final summary = chatSearchSummary(message);
  final trimmed = keyword.trim();
  if (trimmed.isEmpty) {
    return TextSpan(text: summary);
  }

  final lowerSummary = summary.toLowerCase();
  final lowerKeyword = trimmed.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;

  while (true) {
    final index = lowerSummary.indexOf(lowerKeyword, start);
    if (index == -1) {
      spans.add(TextSpan(text: summary.substring(start)));
      break;
    }
    if (index > start) {
      spans.add(TextSpan(text: summary.substring(start, index)));
    }
    spans.add(
      TextSpan(
        text: summary.substring(index, index + trimmed.length),
        style: const TextStyle(
          backgroundColor: Color(0xFFFDE68A),
          color: Color(0xFF92400E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    start = index + trimmed.length;
  }

  return TextSpan(children: spans);
}
