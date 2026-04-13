import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ChatBottomPanelV2 extends StatelessWidget {
  const ChatBottomPanelV2({
    super.key,
    required this.mode,
    this.onAttachItemTap,
    this.onEmojiSelected,
    this.onEmojiBackspace,
  });

  final ChatV2BottomMode mode;

  /// 附件面板内第 [index] 项点击（0=相册）。
  final void Function(int index)? onAttachItemTap;

  /// 表情模式下点击某个 emoji 字符。
  final ValueChanged<String>? onEmojiSelected;

  /// 表情模式下删除光标前一段（由页面实现具体删除逻辑）。
  final VoidCallback? onEmojiBackspace;

  @override
  Widget build(BuildContext context) {
    if (mode == ChatV2BottomMode.idle) {
      return const SizedBox.shrink();
    }

    final bool isEmoji = mode == ChatV2BottomMode.emoji;
    final List<String> items = isEmoji
        ? <String>['😀', '😁', '🤣', '😍', '😭', '👍', '🎉', '❤️']
        : <String>['相册', '拍摄', '语音通话', '视频通话', '位置', '文件'];

    return Container(
      height: ChatV2Tokens.panelHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: ChatV2Tokens.headerBackground,
        border: Border(top: BorderSide(color: ChatV2Tokens.divider)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (BuildContext context, int index) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: isEmoji
                        ? (onEmojiSelected != null
                            ? () => onEmojiSelected!(items[index])
                            : null)
                        : (onAttachItemTap != null
                            ? () => onAttachItemTap!(index)
                            : null),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ChatV2Tokens.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          items[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isEmoji ? 24 : 13,
                            color: ChatV2Tokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isEmoji && onEmojiBackspace != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: '删除',
                onPressed: onEmojiBackspace,
                icon: const Icon(Icons.backspace_outlined),
                color: ChatV2Tokens.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
