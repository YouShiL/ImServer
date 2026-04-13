import 'package:flutter/foundation.dart';

void _apiFlowPrint(String prefix, String phase, Map<String, Object?> fields) {
  if (!kDebugMode) {
    return;
  }
  final StringBuffer b = StringBuffer('$prefix $phase');
  for (final MapEntry<String, Object?> e in fields.entries) {
    b.write(' ${e.key}=${e.value}');
  }
  debugPrint(b.toString());
}

/// 好友列表 / 进聊天前：对端 uid、friendId、资料 id 对齐情况。
void imFriendFlowLog(String phase, Map<String, Object?> fields) {
  _apiFlowPrint('[IM_FRIEND_FLOW]', phase, fields);
}

/// 群列表 / 进聊天前：group_chat.id vs 业务 groupId 与最终 targetId。
void imGroupFlowLog(String phase, Map<String, Object?> fields) {
  _apiFlowPrint('[IM_GROUP_FLOW]', phase, fields);
}

/// 与会话 API / DTO 对齐；可与 [IM_CONV_SOURCE] 配合看全链路。
void imConvApiLog(String phase, Map<String, Object?> fields) {
  _apiFlowPrint('[IM_CONV_API]', phase, fields);
}
