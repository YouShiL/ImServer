import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/conversation_identity.dart';

/// 进入 [ChatV2Page] 时的路由参数，仅 [kDebugMode] 输出；前缀 `[IM_CHAT_ENTRY]`。
void imChatEntryLog(
  String entrySource, {
  required int targetId,
  required int type,
  String? title,
}) {
  if (!kDebugMode) {
    return;
  }
  final String cacheKey = ConversationIdentity.cacheKey(targetId, type);
  debugPrint(
    '[IM_CHAT_ENTRY] entrySource=$entrySource '
    'targetId=$targetId type=$type cacheKey=$cacheKey title=${title ?? '-'}',
  );
}
