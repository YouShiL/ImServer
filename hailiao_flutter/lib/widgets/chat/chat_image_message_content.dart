import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 设为 `true` 时在图片右下角显示红色 TEST，用于确认 [bottomTrailingOverlay] 几何与层级；验证后请改回 `false`。
const bool _kVerifyImageOverlayLayout = false;

/// 图片 / 视频共用的缩略图区域（圆角、渐变、占位、网络/本地预览）。
///
/// [ChatImageMessageContent] / [ChatVideoMessageContent] 分别固定 [isVideo]。
/// 仅图片会使用 [bottomTrailingOverlay]；视频固定为 null，行为不变。
class ChatMediaThumbnailContent extends StatelessWidget {
  const ChatMediaThumbnailContent({
    super.key,
    required this.path,
    required this.onTap,
    this.label,
    required this.isVideo,
    this.bottomTrailingOverlay,
  });

  final String path;
  final VoidCallback onTap;
  final String? label;
  final bool isVideo;
  /// 叠在缩略图右下角（时间、对勾等）；与 [isVideo] 为 true 时互斥使用。
  final Widget? bottomTrailingOverlay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? math.min(
                ChatUiTokens.imageMessageMaxWidth,
                constraints.maxWidth,
              ).clamp(
                ChatUiTokens.imageMessageMinWidth,
                ChatUiTokens.imageMessageMaxWidth,
              )
            : ChatUiTokens.imageMessageMaxWidth;
        final double height = isVideo
            ? ChatUiTokens.videoMessageHeight
            : width.clamp(
                ChatUiTokens.imageMessageMinWidth,
                ChatUiTokens.imageMessageMaxHeight,
              );

        final Widget mediaBody = GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ChatUiTokens.mediaRadiusMd),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                _buildPreview(width, height),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.black.withValues(alpha: isVideo ? 0.26 : 0.14),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isVideo)
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                if (label != null && label!.isNotEmpty)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ChatUiTokens.mediaLabelBackground,
                          borderRadius: BorderRadius.circular(
                            ChatUiTokens.radiusSm,
                          ),
                        ),
                        child: Text(
                          label!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ChatUiTokens.mediaLabelText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isVideo && bottomTrailingOverlay != null)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: _kVerifyImageOverlayLayout
                        ? Container(
                            color: Colors.red,
                            padding: const EdgeInsets.all(4),
                            child: const Text(
                              'TEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: DefaultTextStyle(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  height: 1.05,
                                ),
                                child: IconTheme(
                                  data: IconThemeData(
                                    color:
                                        Colors.white.withValues(alpha: 0.92),
                                    size: 12,
                                  ),
                                  child: bottomTrailingOverlay!,
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        );

        return SizedBox(
          width: width,
          height: height,
          child: mediaBody,
        );
      },
    );
  }

  Widget _buildPreview(double width, double height) {
    final File file = File(path);
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(width, height),
      );
    }
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(width, height),
      );
    }
    return _buildPlaceholder(width, height);
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: ChatUiTokens.mediaPlaceholderBackground,
      alignment: Alignment.center,
      child: Icon(
        isVideo ? Icons.movie_creation_outlined : Icons.image_outlined,
        color: ChatUiTokens.mediaPlaceholderIcon,
        size: 36,
      ),
    );
  }
}

/// 图片气泡内容（时间与送达态可由 [bottomTrailingMeta] 叠在图内右下角）。
///
/// 发送失败时，仅 [ChatMessageStatusBadge] 感叹号区域可点（热区由 badge 放大），
/// 点击行为由会话层 [ChatThreadMessageBubble] 配置的 `onFailedTap`（底栏重试/删本地）处理。
class ChatImageMessageContent extends StatelessWidget {
  const ChatImageMessageContent({
    super.key,
    required this.path,
    required this.onTap,
    this.label,
    this.bottomTrailingMeta,
  });

  final String path;
  final VoidCallback onTap;
  final String? label;
  /// Telegram 式叠在图片右下角（通常为时间 + 对勾）；为 null 则不绘制叠层。
  final Widget? bottomTrailingMeta;

  @override
  Widget build(BuildContext context) {
    return ChatMediaThumbnailContent(
      path: path,
      onTap: onTap,
      label: label,
      isVideo: false,
      bottomTrailingOverlay: bottomTrailingMeta,
    );
  }
}
