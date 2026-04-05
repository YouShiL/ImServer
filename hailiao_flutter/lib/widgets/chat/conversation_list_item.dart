import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/conversation_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_list_item.dart';
import 'package:hailiao_flutter/widgets/common/badge_tag.dart';

class ConversationListItem extends StatelessWidget {
  const ConversationListItem({
    super.key,
    required this.title,
    required this.previewText,
    required this.timeText,
    required this.hasUnread,
    required this.isTop,
    required this.isMute,
    required this.isDraft,
    required this.onTap,
    required this.onLongPress,
    this.unreadCount = 0,
    this.avatarText,
  });

  final String title;
  final String previewText;
  final String timeText;
  final bool hasUnread;
  final bool isTop;
  final bool isMute;
  final bool isDraft;
  final int unreadCount;
  final String? avatarText;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final List<_BadgeData> badges = <_BadgeData>[
      if (isTop)
        const _BadgeData(
          label: '置顶',
          textColor: ConversationUiTokens.tagTopText,
          backgroundColor: ConversationUiTokens.tagTopBackground,
        ),
      if (isMute)
        const _BadgeData(
          label: '免打扰',
          textColor: ConversationUiTokens.tagMuteText,
          backgroundColor: ConversationUiTokens.tagMuteBackground,
        ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ConversationUiTokens.contentMaxWidth,
        ),
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onLongPress: onLongPress,
            behavior: HitTestBehavior.opaque,
            child: AppListItem(
              onTap: onTap,
              padding: const EdgeInsets.symmetric(
                horizontal: ConversationUiTokens.listItemHorizontalPadding,
                vertical: ConversationUiTokens.listItemVerticalPadding,
              ),
              dividerIndent: 76,
              dividerEndIndent: CommonTokens.md,
              leading: _AvatarBadge(
                text: avatarText ?? _fallbackAvatarText(title),
                highlight: hasUnread,
              ),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ConversationUiTokens.listItemTitleText.copyWith(
                        color: ConversationUiTokens.itemTitleText,
                        fontWeight:
                            hasUnread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (timeText.isNotEmpty) ...<Widget>[
                    const SizedBox(width: CommonTokens.xs),
                    Text(
                      timeText,
                      style: ConversationUiTokens.listItemMetaText.copyWith(
                        color: hasUnread
                            ? ConversationUiTokens.itemTimeUnreadText
                            : ConversationUiTokens.itemTimeText,
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ConversationUiTokens.listItemSubtitleText.copyWith(
                      color: isDraft
                          ? ConversationUiTokens.tagDraftText
                          : ConversationUiTokens.itemPreviewText,
                      fontWeight:
                          isDraft ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (badges.isNotEmpty) ...<Widget>[
                    const SizedBox(height: CommonTokens.xs),
                    Wrap(
                      spacing: ConversationUiTokens.tagGap,
                      runSpacing: CommonTokens.xxs,
                      children: badges
                          .map((badge) => _ConversationBadge(data: badge))
                          .toList(),
                    ),
                  ],
                ],
              ),
              trailing: unreadCount > 0
                  ? _UnreadBadge(count: unreadCount)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  String _fallbackAvatarText(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return '?';
    }
    return text.characters.first.toUpperCase();
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.text,
    required this.highlight,
  });

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ConversationUiTokens.avatarSize,
      height: ConversationUiTokens.avatarSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ConversationUiTokens.avatarRadius),
        color: highlight
            ? ConversationUiTokens.avatarHighlightBackground
            : ConversationUiTokens.avatarBackground,
      ),
      child: Center(
        child: Text(
          text,
          style: CommonTokens.subtitle.copyWith(
            color: ConversationUiTokens.avatarText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ConversationBadge extends StatelessWidget {
  const _ConversationBadge({required this.data});

  final _BadgeData data;

  @override
  Widget build(BuildContext context) {
    return BadgeTag(
      label: data.label,
      backgroundColor: data.backgroundColor,
      textColor: data.textColor,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: ConversationUiTokens.unreadBadgeMinSize,
        minHeight: ConversationUiTokens.unreadBadgeMinSize,
      ),
      padding: ConversationUiTokens.unreadBadgePadding,
      decoration: BoxDecoration(
        color: ConversationUiTokens.unreadBadgeBackground,
        borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: ConversationUiTokens.listItemMetaText.copyWith(
            color: ConversationUiTokens.unreadBadgeText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
}
