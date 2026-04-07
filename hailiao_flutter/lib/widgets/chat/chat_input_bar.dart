import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

/// 微信式输入条：[语音/键盘] [输入框 | 按住说话] [表情] [+]
/// 右侧固定为表情 + 扩展；发送仅通过键盘 IME 或表情面板，不在此行出现第三个动作槽。
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.onChanged,
    required this.isVoiceMode,
    required this.voiceModeAllowed,
    required this.onVoiceModeToggle,
    required this.isEmojiPanelOpen,
    required this.isAttachPanelOpen,
    required this.onEmojiPressed,
    required this.onAttachPressed,
    required this.hasComposeText,
    required     this.onTextSubmitted,
    this.focusNode,
    this.onHoldToSpeakTap,
    /// 点击输入框（含已获焦时再次点击）：用于与「打开键盘」动作对齐的补滚等。
    this.onComposerTextFieldTap,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final String hintText;
  final ValueChanged<String> onChanged;
  /// 语音模式：中间为「按住说话」，且隐藏表情按钮。
  final bool isVoiceMode;
  /// 编辑中等场景下禁止切入语音（为 false 时左侧麦克风禁用）。
  final bool voiceModeAllowed;
  final VoidCallback? onVoiceModeToggle;
  final bool isEmojiPanelOpen;
  final bool isAttachPanelOpen;
  final VoidCallback? onEmojiPressed;
  final VoidCallback? onAttachPressed;
  final bool hasComposeText;
  final VoidCallback? onTextSubmitted;
  /// 轻点「按住说话」占位反馈（如 SnackBar），不涉及录音业务。
  final VoidCallback? onHoldToSpeakTap;
  final VoidCallback? onComposerTextFieldTap;

  static const double _sideSlot = 36;

  @override
  Widget build(BuildContext context) {
    final double h = ChatUiTokens.inputFieldMinHeight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: ChatUiTokens.inputBarBackground,
        border: Border(
          top: BorderSide(color: ChatUiTokens.inputBarBorder),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ChatUiTokens.inputBarMaxWidth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: _sideSlot,
                height: h,
                child: _ModeIconButton(
                  icon: isVoiceMode
                      ? Icons.keyboard_alt_outlined
                      : Icons.mic_none_rounded,
                  iconSize: 22,
                  selected: false,
                  onPressed: enabled && voiceModeAllowed && onVoiceModeToggle != null
                      ? onVoiceModeToggle
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: isVoiceMode
                    ? _HoldToSpeakBar(
                        height: h,
                        enabled: enabled,
                        onTap: onHoldToSpeakTap,
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(minHeight: h),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: ChatUiTokens.inputFieldBackground,
                            borderRadius: BorderRadius.circular(
                              ChatUiTokens.inputFieldRadius,
                            ),
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            enabled: enabled,
                            minLines: 1,
                            maxLines: ChatUiTokens.inputFieldMaxLines.toInt(),
                            style: CommonTokens.body
                                .copyWith(fontSize: 16, height: 1.25),
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.send,
                            onTap: onComposerTextFieldTap,
                            onSubmitted: enabled &&
                                    hasComposeText &&
                                    onTextSubmitted != null
                                ? (_) => onTextSubmitted!()
                                : null,
                            decoration: InputDecoration(
                              hintText: hintText,
                              hintStyle: CommonTokens.bodySmall.copyWith(
                                color: ChatUiTokens.inputFieldHintText
                                    .withValues(alpha: 0.42),
                                fontSize: 14.5,
                              ),
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: onChanged,
                          ),
                        ),
                      ),
              ),
              if (!isVoiceMode) ...<Widget>[
                const SizedBox(width: 6),
                SizedBox(
                  width: _sideSlot,
                  height: h,
                  child: _ModeIconButton(
                    icon: isEmojiPanelOpen
                        ? Icons.keyboard_alt_outlined
                        : Icons.emoji_emotions_outlined,
                    iconSize: 20,
                    selected: isEmojiPanelOpen,
                    onPressed: enabled ? onEmojiPressed : null,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              SizedBox(
                width: _sideSlot,
                height: h,
                child: _ModeIconButton(
                  icon: Icons.add_circle_outline,
                  iconSize: 20,
                  selected: isAttachPanelOpen,
                  iconColor: Colors.grey[500],
                  onPressed: enabled ? onAttachPressed : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldToSpeakBar extends StatelessWidget {
  const _HoldToSpeakBar({
    required this.height,
    required this.enabled,
    this.onTap,
  });

  final double height;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChatUiTokens.inputFieldBackground,
      borderRadius: BorderRadius.circular(ChatUiTokens.inputFieldRadius),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(ChatUiTokens.inputFieldRadius),
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              '按住 说话',
              style: CommonTokens.bodySmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: enabled
                    ? CommonTokens.textSecondary
                    : CommonTokens.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeIconButton extends StatelessWidget {
  const _ModeIconButton({
    required this.icon,
    required this.onPressed,
    this.iconSize = 22,
    this.iconColor,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? iconColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bool active = onPressed != null;
    final Color resolved = iconColor ??
        (active
            ? ChatUiTokens.inputActionIcon
            : ChatUiTokens.inputActionIcon.withValues(alpha: 0.35));
    return Material(
      color: selected
          ? Colors.black.withValues(alpha: 0.06)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: selected ? ChatUiTokens.inputActionIcon : resolved,
          ),
        ),
      ),
    );
  }
}
