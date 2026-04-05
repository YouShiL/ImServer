import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.onChanged,
    required this.onMediaPressed,
    required this.onEmojiPressed,
    required this.onSendPressed,
    required this.showEmojiPicker,
    required this.canSend,
    this.sendIcon = Icons.send,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onMediaPressed;
  final VoidCallback? onEmojiPressed;
  final VoidCallback? onSendPressed;
  final bool showEmojiPicker;
  final bool canSend;
  final IconData sendIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        CommonTokens.sm,
        CommonTokens.xs,
        CommonTokens.sm,
        CommonTokens.xs,
      ),
      decoration: const BoxDecoration(
        color: ChatUiTokens.inputBarBackground,
        border: Border(
          top: BorderSide(color: ChatUiTokens.inputBarBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ChatUiTokens.inputBarMaxWidth,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _CircleActionButton(
                  icon: Icons.add_circle_outline,
                  onPressed: onMediaPressed,
                ),
                const SizedBox(width: CommonTokens.xs),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: ChatUiTokens.inputFieldMinHeight,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ChatUiTokens.inputFieldBackground,
                        borderRadius:
                            BorderRadius.circular(CommonTokens.smRadius),
                        border: Border.all(color: ChatUiTokens.inputFieldBorder),
                      ),
                      child: TextField(
                        controller: controller,
                        enabled: enabled,
                        minLines: 1,
                        maxLines: ChatUiTokens.inputFieldMaxLines.toInt(),
                        style: CommonTokens.body,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: CommonTokens.bodySmall.copyWith(
                            color: ChatUiTokens.inputFieldHintText,
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: CommonTokens.md,
                            vertical: 10,
                          ),
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: CommonTokens.xs),
                _CircleActionButton(
                  icon: showEmojiPicker
                      ? Icons.keyboard_alt_outlined
                      : Icons.sentiment_satisfied_alt,
                  onPressed: onEmojiPressed,
                ),
                const SizedBox(width: CommonTokens.xs),
                Container(
                  width: ChatUiTokens.sendButtonSize,
                  height: ChatUiTokens.sendButtonSize,
                  decoration: BoxDecoration(
                    color: canSend
                        ? ChatUiTokens.sendButtonBackground
                        : ChatUiTokens.sendButtonDisabledBackground,
                    borderRadius:
                        BorderRadius.circular(CommonTokens.pillRadius),
                  ),
                  child: IconButton(
                    splashRadius: ChatUiTokens.sendButtonSize / 2,
                    icon: Icon(sendIcon, color: ChatUiTokens.sendButtonIcon),
                    onPressed: canSend ? onSendPressed : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ChatUiTokens.inputActionSize,
      height: ChatUiTokens.inputActionSize,
      decoration: BoxDecoration(
        color: ChatUiTokens.inputActionBackground,
        borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
        border: Border.all(color: ChatUiTokens.inputActionBorder),
      ),
      child: IconButton(
        icon: Icon(icon, color: ChatUiTokens.inputActionIcon, size: 20),
        splashRadius: ChatUiTokens.inputActionSize / 2,
        onPressed: onPressed,
      ),
    );
  }
}
