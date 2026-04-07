import 'package:flutter/material.dart';
import 'package:hailiao_flutter/widgets/chat/chat_image_message_content.dart';

/// 视频气泡缩略图 + 播放叠层（点击预览由外层注入 [onTap]）。
class ChatVideoMessageContent extends StatelessWidget {
  const ChatVideoMessageContent({
    super.key,
    required this.path,
    required this.onTap,
    this.peerLabel,
  });

  final String path;
  final VoidCallback onTap;

  /// 对方消息时展示的弱标签（如「视频消息」）；己方通常为 null。
  final String? peerLabel;

  @override
  Widget build(BuildContext context) {
    return ChatMediaThumbnailContent(
      path: path,
      onTap: onTap,
      label: peerLabel,
      isVideo: true,
    );
  }
}
