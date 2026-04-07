import 'package:intl/intl.dart';

/// Normalizes API / IM timestamps for chat UI (yyyy-MM-dd HH:mm:ss, local).
class ChatDateFormat {
  ChatDateFormat._();

  static final DateFormat _display = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String? display(String? raw) {
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return _display.format(parsed.toLocal());
    }
    final asNum = num.tryParse(trimmed);
    if (asNum != null) {
      final v = asNum.toInt();
      final millis = v > 9999999999 ? v : v * 1000;
      return _display.format(
        DateTime.fromMillisecondsSinceEpoch(millis).toLocal(),
      );
    }
    return trimmed;
  }

  /// yyyy-MM-dd for date dividers (今天 / 昨天 等仍用原有逻辑，只取前 10 位)。
  static String dateBucket(String? raw) {
    final s = display(raw);
    if (s == null || s.isEmpty) {
      return '';
    }
    if (s.length >= 10) {
      return s.substring(0, 10);
    }
    return s;
  }

  static String? fromMillis(int millis) {
    if (millis <= 0) {
      return null;
    }
    return _display.format(
      DateTime.fromMillisecondsSinceEpoch(millis).toLocal(),
    );
  }

  /// Parses ISO-8601, [display] output, or epoch seconds/millis.
  static int? parseToMillis(String? raw) {
    if (raw == null) {
      return null;
    }
    final t = raw.trim();
    if (t.isEmpty) {
      return null;
    }
    final iso = DateTime.tryParse(t);
    if (iso != null) {
      return iso.millisecondsSinceEpoch;
    }
    try {
      return _display.parse(t, false).millisecondsSinceEpoch;
    } catch (_) {}
    final n = num.tryParse(t);
    if (n == null) {
      return null;
    }
    final v = n.toInt();
    return v > 9999999999 ? v : v * 1000;
  }
}
