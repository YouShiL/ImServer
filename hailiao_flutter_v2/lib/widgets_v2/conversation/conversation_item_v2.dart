import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_list_item_v2.dart';

class ConversationItemV2 extends StatelessWidget {
  const ConversationItemV2({
    super.key,
    required this.viewModel,
    required this.onTap,
  });

  final ConversationV2ViewModel viewModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PrimaryListItemV2(
      title: viewModel.title,
      subtitle: viewModel.lastMessage,
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFD1D5DB),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          viewModel.type == 2 ? '群' : '聊',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: ChatV2Tokens.textPrimary,
          ),
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            viewModel.timeLabel ?? '',
            style: ChatV2Tokens.headerSubtitle,
          ),
          if (viewModel.unreadCount > 0) ...<Widget>[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE34D59),
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              alignment: Alignment.center,
              child: Text(
                viewModel.unreadCount > 99 ? '99+' : '${viewModel.unreadCount}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
