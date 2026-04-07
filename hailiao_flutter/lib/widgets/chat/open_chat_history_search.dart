import 'package:flutter/material.dart';
import 'package:hailiao_flutter/screens/chat_message_search_screen.dart';

/// 从资料页 / 群详情进入「搜索聊天记录」，与聊天页 [ChatScreen._openSearchPage] 同款路由。
Future<ChatMessageSearchPop?> openChatHistorySearch(
  BuildContext context, {
  required int targetId,
  required int type,
  Set<int> selectedMessageIds = const <int>{},
}) {
  return Navigator.of(context).push<ChatMessageSearchPop>(
    MaterialPageRoute<ChatMessageSearchPop>(
      builder: (_) => ChatMessageSearchScreen(
        targetId: targetId,
        type: type,
        selectedMessageIds: selectedMessageIds,
      ),
    ),
  );
}
