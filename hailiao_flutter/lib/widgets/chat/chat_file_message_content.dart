import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatFileMessageContent extends StatelessWidget {
  const ChatFileMessageContent({
    super.key,
    required this.path,
    required this.isCurrentUser,
    required this.onTap,
    this.title,
    this.subtitle,
    this.leadingIcon,
    this.isHighlighted = false,
  });

  final String path;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;
  final IconData? leadingIcon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final Color background = isHighlighted
        ? ChatUiTokens.mediaHighlightSurface
        : isCurrentUser
            ? ChatUiTokens.fileCardOutgoing
            : ChatUiTokens.fileCardIncoming;
    final Color iconBackground = isCurrentUser
        ? ChatUiTokens.fileCardIconBackgroundOutgoing
        : ChatUiTokens.fileCardIconBackgroundIncoming;
    final Color iconColor = isCurrentUser
        ? ChatUiTokens.fileCardIconOutgoing
        : ChatUiTokens.fileCardIconIncoming;
    final Color titleColor = isCurrentUser
        ? ChatUiTokens.outgoingBubbleText
        : ChatUiTokens.incomingBubbleText;
    final Color subtitleColor = isCurrentUser
        ? ChatUiTokens.outgoingMetaText
        : ChatUiTokens.incomingMetaText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: ChatUiTokens.fileCardMinWidth,
        ),
        padding: const EdgeInsets.all(CommonTokens.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(ChatUiTokens.mediaRadiusMd),
          border: Border.all(
            color: isCurrentUser
                ? Colors.transparent
                : ChatUiTokens.fileCardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(ChatUiTokens.radiusSm),
              ),
              child: Icon(
                leadingIcon ?? _defaultIcon(path),
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: CommonTokens.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title ?? _basename(path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatUiTokens.fileTitleTextStyle.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ?? _extensionLabel(path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatUiTokens.fileSubtitleTextStyle.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _basename(String path) {
    final String normalized = path.replaceAll('\\', '/');
    final String last = normalized.split('/').where((String part) => part.isNotEmpty).isEmpty
        ? path
        : normalized.split('/').where((String part) => part.isNotEmpty).last;
    return last.isEmpty ? '附件消息' : Uri.decodeComponent(last);
  }

  static String _extensionLabel(String path) {
    final String name = _basename(path);
    final int dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == name.length - 1) {
      return '文件消息';
    }
    return '${name.substring(dotIndex + 1).toUpperCase()} 文件';
  }

  static IconData _defaultIcon(String path) {
    final String ext = _extensionLabel(path).toLowerCase();
    if (ext.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (ext.contains('doc') || ext.contains('txt')) {
      return Icons.description_outlined;
    }
    if (ext.contains('xls') || ext.contains('csv')) {
      return Icons.table_chart_outlined;
    }
    if (ext.contains('zip') || ext.contains('rar')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}
