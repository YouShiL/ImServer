import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

class ChatImageMessageContent extends StatelessWidget {
  const ChatImageMessageContent({
    super.key,
    required this.path,
    required this.onTap,
    this.label,
    this.isVideo = false,
  });

  final String path;
  final VoidCallback onTap;
  final String? label;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? math.min(
                constraints.maxWidth,
                ChatUiTokens.imageMessageMaxWidth,
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

        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ChatUiTokens.mediaRadiusMd),
            child: Stack(
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
              ],
            ),
          ),
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
