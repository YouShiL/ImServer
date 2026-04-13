import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_avatar_v2.dart';

/// 与旧 [ChatMessageRow] 对齐：左右头像 + [Flexible] + [Align] 稳定列，不拼 Spacer。
///
/// 头像与气泡 **底部对齐**（微信式），[alignBubbleToTop] 保留入参以兼容调用方，布局恒为底对齐。
class ChatMessageRowV2 extends StatelessWidget {
  const ChatMessageRowV2({
    super.key,
    required this.isMine,
    required this.child,
    this.aboveBubble,
    this.alignBubbleToTop = false,
  });

  final bool isMine;
  final Widget child;
  /// 群聊对方昵称等，置于气泡上方，与 [child] 同列。
  final Widget? aboveBubble;
  /// 保留字段；当前实现统一底对齐，与图片/文本均与头像底缘对齐。
  final bool alignBubbleToTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ChatV2Tokens.messageRowVerticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isMine) ...<Widget>[
            const ChatMessageAvatarV2(isMine: false),
            const SizedBox(width: ChatV2Tokens.messageRowHorizontalGap),
          ],
          Flexible(
            child: Align(
              alignment: isMine ? Alignment.bottomRight : Alignment.bottomLeft,
              child: _bubbleColumn(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                bubble: child,
              ),
            ),
          ),
          if (isMine) ...<Widget>[
            const SizedBox(width: ChatV2Tokens.messageRowOutgoingAvatarGap),
            const ChatMessageAvatarV2(isMine: true),
          ],
        ],
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
}
