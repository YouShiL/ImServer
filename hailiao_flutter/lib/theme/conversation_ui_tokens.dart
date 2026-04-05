import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ConversationUiTokens {
  ConversationUiTokens._();

  static const Color pageBackground = CommonTokens.pageBackground;
  static const Color surface = CommonTokens.surfacePrimary;
  static const Color softSurface = CommonTokens.softSurface;
  static const Color elevatedSurface = CommonTokens.elevatedSurface;
  static const Color border = CommonTokens.borderColor;
  static const Color divider = CommonTokens.dividerColor;
  static const Color mutedText = CommonTokens.textSecondary;
  static const Color subtleText = CommonTokens.textTertiary;

  static const Color searchBarBackground = CommonTokens.surfacePrimary;
  static const Color searchBarBorder = CommonTokens.hairlineColor;
  static const Color searchBarFocusedBorder = CommonTokens.brandBlue;
  static const Color searchBarHintText = CommonTokens.textTertiary;
  static const Color searchBarIcon = CommonTokens.textSecondary;
  static const List<BoxShadow> searchBarShadow = CommonTokens.shadowNone;
  static const double searchBarHeight = 44;
  static const double searchBarMaxWidth = 760;

  static const Color statsPanelBackground = CommonTokens.softSurface;
  static const Color statsPanelBorder = CommonTokens.hairlineColor;
  static const Color statsSummaryText = CommonTokens.textSecondary;
  static const Color statsActionText = CommonTokens.brandBlue;
  static const Color statsChipBackground = CommonTokens.surfacePrimary;
  static const Color statsChipBorder = CommonTokens.borderColor;
  static const Color statsChipText = CommonTokens.textSecondary;
  static const double statsPanelMaxWidth = 760;

  static const Color itemTitleText = CommonTokens.textPrimary;
  static const Color itemPreviewText = CommonTokens.textSecondary;
  static const Color itemTimeText = CommonTokens.textTertiary;
  static const Color itemTimeUnreadText = CommonTokens.brandBlue;
  static const Color avatarBackground = Color(0xFFEFF3FF);
  static const Color avatarHighlightBackground = CommonTokens.brandSoft;
  static const Color avatarText = CommonTokens.brandBlue;
  static const double avatarSize = 48;
  static const double avatarRadius = CommonTokens.mdRadius;
  static const double contentMaxWidth = 860;

  static const Color unreadBadgeBackground = CommonTokens.brandBlue;
  static const Color unreadBadgeText = CommonTokens.textOnBrand;
  static const double unreadBadgeMinSize = 20;
  static const EdgeInsets unreadBadgePadding = EdgeInsets.symmetric(
    horizontal: 7,
    vertical: 2,
  );

  static const Color draftText = CommonTokens.brandOrange;
  static const Color draftBg = Color(0xFFFFF1E7);
  static const Color topText = Color(0xFF6D5EF6);
  static const Color topBg = Color(0xFFF0EDFF);
  static const Color muteText = Color(0xFF0B7C73);
  static const Color muteBg = Color(0xFFE6F8F5);

  static const Color tagTopBackground = topBg;
  static const Color tagTopText = topText;
  static const Color tagMuteBackground = muteBg;
  static const Color tagMuteText = muteText;
  static const Color tagDraftBackground = draftBg;
  static const Color tagDraftText = draftText;
  static const double tagGap = 6;

  static const double radiusSm = CommonTokens.smRadius;
  static const double radiusMd = CommonTokens.mdRadius;
  static const double radiusLg = CommonTokens.lgRadius;

  static const double listItemVerticalPadding = 10;
  static const double listItemHorizontalPadding = CommonTokens.md;
  static const double listItemTitleBottomGap = CommonTokens.xxs;

  static const TextStyle listItemTitleText = CommonTokens.subtitle;
  static const TextStyle listItemSubtitleText = CommonTokens.bodySmall;
  static const TextStyle listItemMetaText = CommonTokens.caption;
  static const TextStyle statsSummaryTextStyle = CommonTokens.bodySmall;
  static const TextStyle statsActionTextStyle = CommonTokens.bodySmall;

  static const List<BoxShadow> cardShadow = CommonTokens.shadowNone;
}
