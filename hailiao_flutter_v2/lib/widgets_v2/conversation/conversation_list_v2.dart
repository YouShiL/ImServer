import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/widgets_v2/conversation/conversation_item_v2.dart';

class ConversationListV2 extends StatelessWidget {
  const ConversationListV2({
    super.key,
    required this.items,
    required this.onTapItem,
  });

  final List<ConversationV2ViewModel> items;
  final ValueChanged<ConversationV2ViewModel> onTapItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无会话'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final ConversationV2ViewModel item = items[index];
        return ConversationItemV2(
          viewModel: item,
          onTap: () => onTapItem(item),
        );
      },
    );
  }
}
