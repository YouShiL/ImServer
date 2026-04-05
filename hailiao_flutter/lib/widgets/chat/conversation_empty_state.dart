import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/empty_state_view.dart';

class ConversationEmptyState extends StatelessWidget {
  const ConversationEmptyState({
    super.key,
    this.onExploreTap,
  });

  final VoidCallback? onExploreTap;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.chat_bubble_outline_rounded,
      title: '暂无会话',
      detail: '新的聊天会显示在这里，你也可以先去添加好友或发起新的对话。',
      action: onExploreTap == null
          ? null
          : TextButton.icon(
              onPressed: onExploreTap,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('添加好友'),
              style: TextButton.styleFrom(
                foregroundColor: CommonTokens.brandBlue,
              ),
            ),
    );
  }
}
