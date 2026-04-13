import 'package:flutter/foundation.dart';

/// 仅用于调试会话 identity（targetId / type / cacheKey）一致性；[kDebugMode] 外不输出。
void imIdentityLog(String phase, Map<String, Object?> fields) {
  if (!kDebugMode) {
    return;
  }
  final StringBuffer b = StringBuffer('[IM_IDENTITY] $phase');
  for (final MapEntry<String, Object?> e in fields.entries) {
    b.write(' ${e.key}=${e.value}');
  }
  debugPrint(b.toString());
}
