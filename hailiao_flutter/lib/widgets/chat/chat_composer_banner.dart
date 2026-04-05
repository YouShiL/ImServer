import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatComposerBanner extends StatelessWidget {
  const ChatComposerBanner({
    super.key,
    required this.isEditing,
    required this.summaryText,
    required this.onClose,
  });

  final bool isEditing;
  final String summaryText;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ChatUiTokens.statusBannerMaxWidth,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            CommonTokens.md,
            CommonTokens.xs,
            CommonTokens.md,
            0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: CommonTokens.md,
            vertical: CommonTokens.sm,
          ),
          decoration: BoxDecoration(
            color: ChatUiTokens.statusBannerInfoBackground,
            borderRadius: BorderRadius.circular(ChatUiTokens.radiusMd),
            border: Border.all(color: ChatUiTokens.statusBannerInfoBorder),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                  color: ChatUiTokens.statusBannerInfoIcon,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: CommonTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isEditing ? '编辑消息' : '回复消息',
                      style: ChatUiTokens.statusBannerTitleTextStyle.copyWith(
                        color: ChatUiTokens.statusBannerInfoIcon,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summaryText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ChatUiTokens.statusBannerSubtitleTextStyle.copyWith(
                        color: ChatUiTokens.statusBannerSubtitle,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
