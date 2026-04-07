import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/wx_bottom_sheet_shell.dart';

/// 微信式消息操作面板：顶部分隔条 + 操作列表 + 底部「取消」独立区。
class ChatSheetActionItem {
  const ChatSheetActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

Future<void> showChatMessageActionsSheet(
  BuildContext context, {
  required List<ChatSheetActionItem> actions,
}) {
  return wxShowBottomSheetShell(
    context,
    showCancelAction: true,
    child: Builder(
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(actions.length, (int i) {
            final ChatSheetActionItem item = actions[i];
            final bool last = i == actions.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      item.onTap();
                    },
                    child: SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              item.icon,
                              size: 22,
                              color: item.destructive
                                  ? CommonTokens.danger
                                  : ChatUiTokens.mediaAttachIcon,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                style: CommonTokens.body.copyWith(
                                  color: item.destructive
                                      ? CommonTokens.danger
                                      : CommonTokens.textPrimary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!last)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: CommonTokens.lineSubtle,
                  ),
              ],
            );
          }),
        );
      },
    ),
  );
}
