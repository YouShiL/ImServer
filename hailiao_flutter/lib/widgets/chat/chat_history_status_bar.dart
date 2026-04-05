import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/chat/chat_status_banner.dart';

class ChatHistoryStatusBar extends StatelessWidget {
  const ChatHistoryStatusBar({
    super.key,
    required this.isLoading,
    required this.hasMore,
    this.onLoadMore,
  });

  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return ChatStatusBanner(
      icon: isLoading ? Icons.sync : Icons.history_rounded,
      title: isLoading ? '正在加载更早消息' : (hasMore ? '可继续加载历史消息' : '历史消息已全部加载'),
      subtitle: isLoading
          ? '聊天记录会在此处按时间顺序继续补齐'
          : (hasMore ? '点击继续向上加载更早的消息内容' : '已到达当前会话的最早消息位置'),
      tone: ChatStatusBannerTone.neutral,
      compact: true,
      trailing: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : hasMore
              ? TextButton(
                  onPressed: onLoadMore,
                  child: const Text('加载更多'),
                )
              : null,
    );
  }
}
