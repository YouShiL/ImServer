import 'package:flutter/foundation.dart';

/// 会话列表数据源与映射调试；仅 [kDebugMode]；前缀 `[IM_CONV_SOURCE]`。
void imConvSourceLog(String phase, Map<String, Object?> fields) {
  if (!kDebugMode) {
    return;
  }
  final StringBuffer b = StringBuffer('[IM_CONV_SOURCE] $phase');
  for (final MapEntry<String, Object?> e in fields.entries) {
    b.write(' ${e.key}=${e.value}');
  }
  debugPrint(b.toString());
}
