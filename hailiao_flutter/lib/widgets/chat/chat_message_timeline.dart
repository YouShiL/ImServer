import 'package:hailiao_flutter/models/message_dto.dart';

/// 纯时间与日期：解析、`createdAt` 日期键、分隔文案、插入间隔、[shortHourMinute]。
///
/// **不放：** 是否己方/系统/撤回、`msgType`、气泡或 notice 布局（见 [MessageDTOChatDisplay]、[MessageBubblePresenter]）。入参中的 [MessageDTO] 仅作时间字段载体。
abstract final class ChatMessageTimeline {
  ChatMessageTimeline._();

  static DateTime? tryParseMessageTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final String s = raw.trim();
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {}
    if (s.length >= 19 && s[4] == '-' && (s[10] == 'T' || s[10] == ' ')) {
      try {
        return DateTime.parse(s.substring(0, 19)).toLocal();
      } catch (_) {}
    }
    return null;
  }

  static String? dateKey(MessageDTO message) {
    final DateTime? t = tryParseMessageTime(message.createdAt);
    if (t != null) {
      return '${t.year}-${t.month.toString().padLeft(2, '0')}-'
          '${t.day.toString().padLeft(2, '0')}';
    }
    final String createdAt = message.createdAt ?? '';
    if (createdAt.length >= 10) {
      return createdAt.substring(0, 10);
    }
    return createdAt.isEmpty ? null : createdAt;
  }

  static String formatSeparatorLabel(MessageDTO message) {
    final DateTime? t = tryParseMessageTime(message.createdAt);
    if (t == null) {
      return dateKey(message) ?? '时间未知';
    }
    final DateTime loc = t.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime msgDay = DateTime(loc.year, loc.month, loc.day);

    if (msgDay == today) {
      return '今天';
    }
    final DateTime yest = today.subtract(const Duration(days: 1));
    if (msgDay == yest) {
      return '昨天';
    }
    final int deltaDays = today.difference(msgDay).inDays;
    if (deltaDays >= 0 && deltaDays < 7) {
      const List<String> names = <String>[
        '星期一',
        '星期二',
        '星期三',
        '星期四',
        '星期五',
        '星期六',
        '星期日',
      ];
      return names[loc.weekday - 1];
    }
    return '${loc.year}/${loc.month.toString().padLeft(2, '0')}/'
        '${loc.day.toString().padLeft(2, '0')}';
  }

  static bool needTimeSeparator({
    required int index,
    required List<MessageDTO> messages,
    int? historyBoundaryIndex,
  }) {
    if (index < 0 || index >= messages.length) {
      return false;
    }
    if (index == 0) {
      return true;
    }
    if (historyBoundaryIndex != null && index == historyBoundaryIndex) {
      return true;
    }
    final MessageDTO curr = messages[index];
    final MessageDTO prev = messages[index - 1];
    final DateTime? prevT = tryParseMessageTime(prev.createdAt);
    final DateTime? currT = tryParseMessageTime(curr.createdAt);
    if (prevT != null && currT != null) {
      final DateTime prevDay =
          DateTime(prevT.year, prevT.month, prevT.day);
      final DateTime currDay =
          DateTime(currT.year, currT.month, currT.day);
      if (prevDay != currDay) {
        return true;
      }
      return currT.difference(prevT).abs() >= const Duration(minutes: 30);
    }
    return dateKey(prev) != dateKey(curr);
  }

  static String? shortHourMinute(MessageDTO message) {
    final DateTime? t = tryParseMessageTime(message.createdAt);
    if (t == null) {
      return null;
    }
    final DateTime loc = t.toLocal();
    return '${loc.hour.toString().padLeft(2, '0')}:'
        '${loc.minute.toString().padLeft(2, '0')}';
  }
}
