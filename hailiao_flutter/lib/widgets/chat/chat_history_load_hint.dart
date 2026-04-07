import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 历史区顶部：加载中 / 加载更多 / 无更多。
class ChatHistoryLoadHint extends StatelessWidget {
  const ChatHistoryLoadHint({
    super.key,
    required this.loadingHistory,
    required this.hasMoreHistory,
    required this.onLoadOlderTap,
  });

  final bool loadingHistory;
  final bool hasMoreHistory;
  final VoidCallback onLoadOlderTap;

  @override
  Widget build(BuildContext context) {
    if (loadingHistory) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ChatUiTokens.subtleText.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }
    if (hasMoreHistory) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLoadOlderTap,
            child: Text(
              '更早消息',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Center(
        child: Text(
          '没有更多了',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[400]?.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
