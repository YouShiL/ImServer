import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/profile_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_surface.dart';
import 'package:hailiao_flutter/widgets/common/badge_tag.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.description,
    this.statusText,
  });

  final String title;
  final String subtitle;
  final List<String> meta;
  final String? description;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(ProfileUiTokens.heroPadding),
      backgroundColor: ProfileUiTokens.heroBackground,
      borderRadius: 20,
      showBorder: true,
      child: Column(
        children: <Widget>[
          _ProfileAvatar(title: title),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ProfileUiTokens.heroTitleText,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: ProfileUiTokens.heroMetaText,
          ),
          if ((statusText ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusText == '在线'
                        ? ProfileUiTokens.heroStatusOnline
                        : ProfileUiTokens.heroStatusOffline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText!,
                  style: ProfileUiTokens.heroSubtitleText,
                ),
              ],
            ),
          ],
          if ((description ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: ProfileUiTokens.heroSubtitleText,
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
                      backgroundColor: ProfileUiTokens.heroMetaChipBackground,
                      textColor: ProfileUiTokens.heroMetaChipText,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final String initial = title.isNotEmpty ? title.substring(0, 1) : '号';
    return Container(
      width: ProfileUiTokens.heroAvatarSize,
      height: ProfileUiTokens.heroAvatarSize,
      decoration: BoxDecoration(
        color: ProfileUiTokens.heroAvatarBackground,
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: ProfileUiTokens.heroTitleText.copyWith(
          color: ProfileUiTokens.heroAvatarText,
        ),
      ),
    );
  }
}
