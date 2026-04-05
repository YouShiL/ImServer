import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

class ChatMessageRow extends StatelessWidget {
  const ChatMessageRow({
    super.key,
    required this.isCurrentUser,
    required this.selectionMode,
    required this.selectionValue,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSelectionToggle,
  });

  final bool isCurrentUser;
  final bool selectionMode;
  final bool selectionValue;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final avatar = _AvatarShell(isCurrentUser: isCurrentUser);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ChatUiTokens.messageRowVerticalPadding,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            if (selectionMode)
              _SelectionCheckbox(
                value: selectionValue,
                onChanged: (_) => onSelectionToggle?.call(),
              ),
            if (!isCurrentUser) ...<Widget>[
              avatar,
              const SizedBox(width: ChatUiTokens.messageRowHorizontalGap),
            ],
            Flexible(
              child: Align(
                alignment: isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: child,
              ),
            ),
            if (isCurrentUser) ...<Widget>[
              const SizedBox(width: ChatUiTokens.messageRowHorizontalGap),
              avatar,
            ],
          ],
        ),
      ),
    );
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

class _AvatarShell extends StatelessWidget {
  const _AvatarShell({required this.isCurrentUser});

  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ChatUiTokens.messageAvatarSize,
      height: ChatUiTokens.messageAvatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrentUser
            ? ChatUiTokens.currentUserAvatarBackground
            : ChatUiTokens.peerAvatarBackground,
        border: Border.all(
          color: isCurrentUser
              ? ChatUiTokens.currentUserAvatarBorder
              : ChatUiTokens.peerAvatarBorder,
        ),
      ),
      child: Icon(
        isCurrentUser ? Icons.person : Icons.person_outline,
        size: 18,
        color: isCurrentUser
            ? ChatUiTokens.currentUserAvatarIcon
            : ChatUiTokens.peerAvatarIcon,
      ),
    );
  }
}
