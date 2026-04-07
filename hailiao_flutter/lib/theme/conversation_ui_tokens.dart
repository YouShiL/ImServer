import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';

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
  static const Color searchBarFocusedBorder = UiTokens.primaryBlue;
  static const Color searchBarHintText = CommonTokens.textTertiary;
  static const Color searchBarIcon = CommonTokens.textSecondary;
  static const List<BoxShadow> searchBarShadow = CommonTokens.shadowNone;
  static const double searchBarHeight = ImDesignTokens.heightInput;
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
  static const Color itemTimeText = Color(0xFFB0B0B0);
  static const Color itemTimeUnreadText = UiTokens.primaryBlue;
  static const Color itemStatusIcon = Color(0xFFC8C8C8);
  static const Color avatarBackground = Color(0xFFEFF3FF);
  static const Color avatarHighlightBackground = CommonTokens.brandSoft;
  static const Color avatarText = CommonTokens.brandBlue;
  static const double avatarSize = 40;
  static const double avatarRadius = 20;
  /// 宽屏限制放宽，移动端接近全宽（扁平会话列表）。
  static const double contentMaxWidth = 1600;

  static const Color unreadBadgeBackground = Color(0xFFFF3B30);
  static const Color unreadBadgeText = Color(0xFFFFFFFF);
  static const double unreadBadgeMinSize = 17;
  static const EdgeInsets unreadBadgePadding = EdgeInsets.symmetric(
    horizontal: 5,
    vertical: 1,
  );

  static const Color draftText = Color(0xFF9E9E9E);
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
