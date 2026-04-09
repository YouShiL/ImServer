import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 表情区：上方 emoji 网格；底部删除 + 辅助发送（不替代输入条上的发送）。
class ChatEmojiPanel extends StatefulWidget {
  /// 嵌入 composer 下方时的总高度（与 [build] 布局一致，供聊天列表统一 bottom padding）。
  static const double embeddedHeight =
      12 + 240 + 14 + 14 + 34;

  const ChatEmojiPanel({
    super.key,
    required this.controller,
    required this.onEmojiSelected,
    required this.onDeleteLast,
    required this.onDeleteLongClear,
    required this.onAuxiliarySend,
    required this.canCompose,
  });

  final TextEditingController controller;
  final ValueChanged<Emoji> onEmojiSelected;
  final VoidCallback onDeleteLast;
  final VoidCallback onDeleteLongClear;
  final VoidCallback onAuxiliarySend;

  /// 与输入框一致：拉黑等场景下禁用删除/辅助发送。
  final bool canCompose;

  @override
  State<ChatEmojiPanel> createState() => _ChatEmojiPanelState();
}

class _ChatEmojiPanelState extends State<ChatEmojiPanel> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(ChatEmojiPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerTick);
    super.dispose();
  }

  void _onControllerTick() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasText => widget.controller.text.isNotEmpty;
  bool get _canSend =>
      widget.canCompose && widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChatUiTokens.inputBarBackground,
        border: Border(
          top: BorderSide(
            color: ChatUiTokens.inputBarBorder.withValues(alpha: 0.85),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SizedBox(
              height: 240,
              child: GridView.count(
                physics: const ClampingScrollPhysics(),
                crossAxisCount: 8,
                childAspectRatio: 1,
                children: EmojiList.emojis
                    .map(
                      (emoji) => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => widget.onEmojiSelected(emoji),
                        child: Center(
                          child: Text(
                            emoji.display,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SizedBox(
                  height: 34,
                  child: GestureDetector(
                    onLongPress: widget.canCompose && _hasText
                        ? widget.onDeleteLongClear
                        : null,
                    child: OutlinedButton(
                      onPressed: widget.canCompose && _hasText
                          ? widget.onDeleteLast
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        foregroundColor: (widget.canCompose && _hasText)
                            ? const Color(0xFF5F6B7A)
                            : const Color(0xFFBFC5CE),
                        side: BorderSide(
                          color: (widget.canCompose && _hasText)
                              ? const Color(0xFFD0D5DB)
                              : const Color(0xFFE8EAED),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 20,
                        color: (widget.canCompose && _hasText)
                            ? const Color(0xFF5F6B7A)
                            : const Color(0xFFBFC5CE),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 34,
                  child: Material(
                    color: _canSend
                        ? ChatUiTokens.sendButtonBackground
                        : ChatUiTokens.sendButtonDisabledBackground,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: _canSend ? widget.onAuxiliarySend : null,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Center(
                          child: Text(
                            '发送',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _canSend
                                  ? Colors.white
                                  : ChatUiTokens.sendButtonDisabledIcon,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
