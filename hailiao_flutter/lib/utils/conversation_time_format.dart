import 'package:intl/intl.dart';

/// 会话列表时间展示（本地日历：今天 / 昨天 / 本周 / 更早）。
abstract final class ConversationTimeFormat {
  ConversationTimeFormat._();

  static const List<String> _weekShort = <String>[
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  /// [raw] 为 ISO-8601 等 [DateTime.tryParse] 可解析串；失败则原样返回（避免空白误伤）。
  static String formatListTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    final String s = raw.trim();
    final DateTime? parsed = DateTime.tryParse(s);
    if (parsed == null) {
      return s;
    }
    final DateTime local = parsed.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime msgDay = DateTime(local.year, local.month, local.day);
    final int dayDiffFromToday = today.difference(msgDay).inDays;
    if (dayDiffFromToday == 0) {
      return DateFormat('HH:mm').format(local);
    }
    if (dayDiffFromToday == 1) {
      return '昨天';
    }
    final DateTime todayMonday =
        today.subtract(Duration(days: today.weekday - 1));
    final DateTime msgMonday =
        msgDay.subtract(Duration(days: msgDay.weekday - 1));
    if (todayMonday.year == msgMonday.year &&
        todayMonday.month == msgMonday.month &&
        todayMonday.day == msgMonday.day) {
      return _weekShort[local.weekday - 1];
    }
    return DateFormat('yyyy/MM/dd').format(local);
  }
}
