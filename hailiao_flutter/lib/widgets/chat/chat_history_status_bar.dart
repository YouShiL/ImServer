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
      title: isLoading ? '加载更早消息…' : (hasMore ? '向上加载历史' : '已是最早消息'),
      subtitle: isLoading ? null : (hasMore ? '点击右侧继续' : null),
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
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onLoadMore,
                  child: const Text('加载'),
                )
              : null,
    );
  }
}
