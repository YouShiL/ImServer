import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

/// 内联在输入条下方的扩展面板（与 [ChatEmojiPanel] 同层，不占满屏）。
/// 单聊首屏 5 项高频能力；群聊首屏仅媒体与文件，留白由网格自然形成。
class ChatAttachPanel extends StatelessWidget {
  /// 与 [build] 中 padding + 网格行高一致；[itemCount] 为格子数量（单聊 5 / 群聊 3）。
  static double embeddedHeightForItemCount(int itemCount) {
    final int rows = ((itemCount.clamp(1, 32) + 3) ~/ 4);
    const double verticalPadding = 12 + 18;
    return verticalPadding +
        rows * 76 +
        (rows > 1 ? (rows - 1) * 14 : 0);
  }

  const ChatAttachPanel({
    super.key,
    required this.isSingleChat,
    required this.onGallery,
    required this.onCamera,
    required this.onFile,
    this.onVoiceCall,
    this.onVideoCall,
  });

  final bool isSingleChat;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onFile;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onVideoCall;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cells = <Widget>[
      _AttachCell(
        icon: Icons.photo_library_outlined,
        label: '相册',
        onTap: onGallery,
      ),
      _AttachCell(
        icon: Icons.photo_camera_outlined,
        label: '拍摄',
        onTap: onCamera,
      ),
      _AttachCell(
        icon: Icons.insert_drive_file_outlined,
        label: '文件',
        onTap: onFile,
      ),
      if (isSingleChat && onVoiceCall != null)
        _AttachCell(
          icon: Icons.call_outlined,
          label: '语音通话',
          onTap: onVoiceCall!,
        ),
      if (isSingleChat && onVideoCall != null)
        _AttachCell(
          icon: Icons.video_call_outlined,
          label: '视频通话',
          onTap: onVideoCall!,
        ),
    ];

    return Material(
      color: ChatUiTokens.inputBarBackground,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        decoration: BoxDecoration(
          color: ChatUiTokens.inputBarBackground,
          border: Border(
            top: BorderSide(
              color: ChatUiTokens.inputBarBorder.withValues(alpha: 0.85),
            ),
          ),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisExtent: 76,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
          ),
          itemCount: cells.length,
          itemBuilder: (BuildContext context, int index) => cells[index],
        ),
      ),
    );
  }
}

class _AttachCell extends StatelessWidget {
  const _AttachCell({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ChatUiTokens.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: ChatUiTokens.mediaAttachIcon.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CommonTokens.caption.copyWith(
                  fontSize: 10,
                  height: 1.15,
                  color: CommonTokens.textTertiary.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
