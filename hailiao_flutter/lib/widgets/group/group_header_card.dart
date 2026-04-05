import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/group_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_surface.dart';
import 'package:hailiao_flutter/widgets/common/badge_tag.dart';

class GroupHeaderCard extends StatelessWidget {
  const GroupHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.description,
    required this.notice,
    this.avatarUrl,
  });

  final String title;
  final String subtitle;
  final List<String> meta;
  final String? description;
  final String? notice;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(GroupUiTokens.heroPadding),
      backgroundColor: GroupUiTokens.heroBackground,
      borderRadius: 20,
      showBorder: true,
      child: Column(
        children: <Widget>[
          _GroupAvatar(
            title: title,
            avatarUrl: avatarUrl,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GroupUiTokens.heroTitleText,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GroupUiTokens.heroMetaText,
          ),
          if ((description ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: GroupUiTokens.heroSubtitleText,
            ),
          ],
          if (meta.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: meta
                  .map(
                    (String item) => BadgeTag(
                      label: item,
                      backgroundColor: GroupUiTokens.chipBackground,
                      textColor: GroupUiTokens.chipText,
                    ),
                  )
                  .toList(),
            ),
          ],
          if ((notice ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GroupUiTokens.noticeBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GroupUiTokens.noticeBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.campaign_outlined,
                    size: 18,
                    color: GroupUiTokens.noticeIcon,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notice!,
                      style: GroupUiTokens.sectionSubtitleText.copyWith(
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({
    required this.title,
    this.avatarUrl,
  });

  final String title;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final String initial = title.isNotEmpty ? title.substring(0, 1) : '群';
    if ((avatarUrl ?? '').startsWith('http')) {
      return Container(
        width: GroupUiTokens.heroAvatarSize,
        height: GroupUiTokens.heroAvatarSize,
        decoration: BoxDecoration(
          color: GroupUiTokens.heroAvatarBackground,
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(avatarUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: GroupUiTokens.heroAvatarSize,
      height: GroupUiTokens.heroAvatarSize,
      decoration: BoxDecoration(
        color: GroupUiTokens.heroAvatarBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GroupUiTokens.heroTitleText.copyWith(
          color: GroupUiTokens.heroAvatarIcon,
        ),
      ),
    );
  }
}
