import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_avatar.dart';

class ChatMessageRow extends StatelessWidget {
  const ChatMessageRow({
    super.key,
    required this.isCurrentUser,
    required this.selectionMode,
    required this.selectionValue,
    required this.child,
    this.outgoingLeadingAccessory,
    this.onTap,
    this.onLongPress,
    this.onSelectionToggle,
    this.aboveBubble,
    this.omitSideAvatars = false,
    /// 为 true 时头像与气泡列**顶对齐**（如图片消息）；文本消息保持默认底对齐。
    this.alignBubbleToTop = false,
  });

  final bool isCurrentUser;
  final bool selectionMode;
  final bool selectionValue;
  final Widget child;
  /// 群聊昵称等：置于气泡上方，与 [child] 同列对齐。
  final Widget? aboveBubble;
  /// 为 true 时不绘制左右头像（如撤回弱提示），内容横向居中。
  final bool omitSideAvatars;
  /// 己方消息时置于气泡左侧（靠屏幕中部一侧），如微信发送失败红标。
  final Widget? outgoingLeadingAccessory;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;
  final bool alignBubbleToTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ChatUiTokens.messageRowVerticalPadding,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onLongPress: onLongPress,
        child: omitSideAvatars
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (selectionMode)
                    _SelectionCheckbox(
                      value: selectionValue,
                      onChanged: (_) => onSelectionToggle?.call(),
                    ),
                  Expanded(
                    child: Center(
                      child: _bubbleColumn(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        bubble: _buildMainBubbleArea(),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: alignBubbleToTop
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                mainAxisAlignment: isCurrentUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: <Widget>[
                  if (selectionMode)
                    _SelectionCheckbox(
                      value: selectionValue,
                      onChanged: (_) => onSelectionToggle?.call(),
                    ),
                  if (!isCurrentUser) ...<Widget>[
                    const ChatMessageAvatar(isCurrentUser: false),
                    const SizedBox(width: ChatUiTokens.messageRowHorizontalGap),
                  ],
                  Flexible(
                    child: Align(
                      alignment: alignBubbleToTop
                          ? (isCurrentUser
                              ? Alignment.topRight
                              : Alignment.topLeft)
                          : (isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft),
                      child: _bubbleColumn(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        bubble: _buildMainBubbleArea(),
                      ),
                    ),
                  ),
                  if (isCurrentUser) ...<Widget>[
                    const SizedBox(width: ChatUiTokens.messageRowOutgoingAvatarGap),
                    const ChatMessageAvatar(isCurrentUser: true),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _bubbleColumn({
    required CrossAxisAlignment crossAxisAlignment,
    required Widget bubble,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ?aboveBubble,
        bubble,
      ],
    );
  }

  Widget _buildMainBubbleArea() {
    if (isCurrentUser && outgoingLeadingAccessory != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignBubbleToTop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: <Widget>[
          outgoingLeadingAccessory!,
          const SizedBox(width: 6),
          child,
        ],
      );
    }
    return child;
  }
}

class _SelectionCheckbox extends StatelessWidget {
  const _SelectionCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: ChatUiTokens.messageRowHorizontalGap,
        bottom: 8,
      ),
      child: Checkbox(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
