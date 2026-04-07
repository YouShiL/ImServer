import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_history_load_hint.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_list.dart';

/// 聊天页消息区域：多选条、顶部上下文、loading / 空态 / 列表。
class ChatMessagesBody extends StatelessWidget {
  const ChatMessagesBody({
    super.key,
    this.selectionBar,
    this.topBanner,
    required this.isLoading,
    required this.isEmpty,
    required this.loading,
    required this.empty,
    required this.listScrollController,
    required this.listPadding,
    required this.messageCount,
    required this.itemBuilder,
    required this.loadingHistory,
    required this.hasMoreHistory,
    required this.onLoadOlderTap,
  });

  final Widget? selectionBar;
  final Widget? topBanner;
  final bool isLoading;
  final bool isEmpty;
  final Widget loading;
  final Widget empty;
  final ScrollController listScrollController;
  final EdgeInsets listPadding;
  final int messageCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool loadingHistory;
  final bool hasMoreHistory;
  final VoidCallback onLoadOlderTap;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets resolvedListPadding = EdgeInsets.fromLTRB(
      ChatUiTokens.pageHorizontalPadding,
      listPadding.top,
      ChatUiTokens.pageHorizontalPadding,
      listPadding.bottom,
    );
    return Column(
      children: <Widget>[
        ?selectionBar,
        ?topBanner,
        Expanded(
          child: ColoredBox(
            color: ChatUiTokens.pageBackground,
            child: isLoading
                ? loading
                : isEmpty
                    ? empty
                    : Column(
                        children: <Widget>[
                          ChatHistoryLoadHint(
                            loadingHistory: loadingHistory,
                            hasMoreHistory: hasMoreHistory,
                            onLoadOlderTap: onLoadOlderTap,
                          ),
                          Expanded(
                            child: ChatMessageList(
                              controller: listScrollController,
                              padding: resolvedListPadding,
                              itemCount: messageCount,
                              itemBuilder: itemBuilder,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}
