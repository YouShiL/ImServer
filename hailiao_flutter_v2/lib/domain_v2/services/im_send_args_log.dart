import 'package:flutter/foundation.dart';

/// 发送链路调试：各层 [inputTargetId]/[inputType] 与最终 SDK channel 对齐情况。
/// 仅 [kDebugMode] 输出，前缀 `[IM_SEND_ARGS]`。
void imSendArgsLog(String phase, Map<String, Object?> fields) {
  if (!kDebugMode) {
    return;
  }
  final StringBuffer b = StringBuffer('[IM_SEND_ARGS] $phase');
  for (final MapEntry<String, Object?> e in fields.entries) {
    b.write(' ${e.key}=${e.value}');
  }
  debugPrint(b.toString());
}

/// 图片发送排查专用（仅 [kDebugMode]），前缀 `[IM_IMAGE_SEND]`。
void imImageSendLog(String phase, Map<String, Object?> fields) {
  if (!kDebugMode) {
    return;
  }
  final StringBuffer b = StringBuffer('[IM_IMAGE_SEND] $phase');
  for (final MapEntry<String, Object?> e in fields.entries) {
    b.write(' ${e.key}=${e.value}');
  }
  debugPrint(b.toString());
}

String imSendTextPreview(String text, {int maxLen = 48}) {
  final String t = text.trim();
  if (t.length <= maxLen) {
    return t;
  }
  return '${t.substring(0, maxLen)}…';
}
