import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/conversation_ui_tokens.dart';
import 'package:hailiao_flutter/utils/network_avatar_url.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';

/// 会话列表行：紧凑微信式密度；主标题 + 弱摘要 + 右上时间 + 未读角标。
class ConversationListItem extends StatelessWidget {
  const ConversationListItem({
    super.key,
    required this.title,
    required this.previewText,
    required this.timeText,
    required this.hasUnread,
    required this.isDraft,
    required this.onTap,
    required this.onLongPress,
    this.isTop = false,
    this.isMute = false,
    this.unreadCount = 0,
    this.avatarText,
    this.avatarImageUrl,
  });

  final String title;
  final String previewText;
  final String timeText;
  final bool hasUnread;
  final bool isDraft;
  final bool isTop;
  final bool isMute;
  final int unreadCount;
  final String? avatarText;
  final String? avatarImageUrl;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const double _rowH = 66;
  static const double _padH = 12;
  static const double _avatar = ConversationUiTokens.avatarSize;
  static const double _midGap = 11;

  @override
  Widget build(BuildContext context) {
    final String initial =
        avatarText ?? ProfileDisplayTexts.listAvatarInitial(title);
    final avatar = _ConversationAvatar(
      text: initial,
      highlight: hasUnread,
      imageUrl: avatarImageUrl,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: SizedBox(
              height: _rowH,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _padH),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    avatar,
                    const SizedBox(width: _midGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ConversationUiTokens.listItemTitleText
                                .copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: ConversationUiTokens.itemTitleText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              if (isTop)
                                Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Icon(
                                    Icons.push_pin_outlined,
                                    size: 12,
                                    color: ConversationUiTokens.itemStatusIcon,
                                  ),
                                ),
                              if (isMute)
                                Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Icon(
                                    Icons.volume_off_outlined,
                                    size: 13,
                                    color: ConversationUiTokens.itemStatusIcon,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  previewText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ConversationUiTokens
                                      .listItemSubtitleText
                                      .copyWith(
                                    fontSize: 12,
                                    height: 1.25,
                                    color: isDraft
                                        ? ConversationUiTokens.tagDraftText
                                        : CommonTokens.textTertiary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (timeText.isNotEmpty)
                          Text(
                            timeText,
                            style: ConversationUiTokens.listItemMetaText.copyWith(
                              fontSize: 11,
                              height: 1.1,
                              color: hasUnread
                                  ? ConversationUiTokens.itemTimeUnreadText
                                  : ConversationUiTokens.itemTimeText,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        if (unreadCount > 0) ...<Widget>[
                          if (timeText.isNotEmpty) const SizedBox(height: 4),
                          _UnreadBadge(count: unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: CommonTokens.lineSubtle,
          indent: _padH + _avatar + _midGap,
        ),
      ],
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.text,
    required this.highlight,
    this.imageUrl,
  });

  final String text;
  final bool highlight;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String? url = httpOrHttpsAvatarUrlOrNull(imageUrl);
    final double r = ConversationUiTokens.avatarSize / 2;
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: SizedBox(
          width: ConversationUiTokens.avatarSize,
          height: ConversationUiTokens.avatarSize,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) =>
                _letter(r),
          ),
        ),
      );
    }
    return _letter(r);
  }

  Widget _letter(double r) {
    return Container(
      width: ConversationUiTokens.avatarSize,
      height: ConversationUiTokens.avatarSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        color: highlight
            ? ConversationUiTokens.avatarHighlightBackground
            : ConversationUiTokens.avatarBackground,
      ),
      child: Center(
        child: Text(
          text,
          style: CommonTokens.subtitle.copyWith(
            fontSize: 15,
            color: ConversationUiTokens.avatarText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final String label = count > 99 ? '99+' : '$count';
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
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
