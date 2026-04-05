import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatUiTokens {
  ChatUiTokens._();

  static const Color pageBackground = CommonTokens.pageBackground;
  static const Color surface = CommonTokens.surfacePrimary;
  static const Color softSurface = CommonTokens.softSurface;
  static const Color elevatedSurface = CommonTokens.elevatedSurface;
  static const Color border = CommonTokens.borderColor;
  static const Color divider = CommonTokens.dividerColor;
  static const Color mutedText = CommonTokens.textSecondary;
  static const Color subtleText = CommonTokens.textTertiary;
  static const Color info = CommonTokens.info;
  static const Color warning = CommonTokens.warning;
  static const Color selected = Color(0xFFE8F0FF);
  static const Color highlight = Color(0xFFFFF6DD);

  static const Color outgoingBubble = CommonTokens.brandBlue;
  static const Color outgoingBubbleText = CommonTokens.textOnBrand;
  static const Color incomingBubble = CommonTokens.surfacePrimary;
  static const Color incomingBubbleText = CommonTokens.textPrimary;
  static const Color incomingBubbleBorder = CommonTokens.borderColor;
  static const Color systemMessageBg = Color(0xFFF2F5F9);
  static const Color systemMessageText = CommonTokens.textTertiary;
  static const Color outgoingMetaText = Color(0xFFE9EEFF);
  static const Color incomingMetaText = CommonTokens.textTertiary;
  static const Color replyPanelIncoming = Color(0xFFF4F7FB);
  static const Color replyPanelOutgoing = Color(0xFF7392FB);
  static const Color replyAccentIncoming = Color(0xFFCAD4E3);
  static const Color replyAccentOutgoing = Color(0xFFB8C9FF);
  static const Color bubbleFlagIncoming = Color(0xFFF3F6FA);
  static const Color bubbleFlagOutgoing = Color(0xFF7594FB);
  static const Color fileCardIncoming = Color(0xFFF5F7FA);
  static const Color fileCardOutgoing = Color(0xFF6F8EFA);
  static const Color fileCardBorder = CommonTokens.borderColor;
  static const Color fileCardIconBackgroundIncoming = Color(0xFFE8EEF7);
  static const Color fileCardIconBackgroundOutgoing = Color(0xFF89A3FF);
  static const Color fileCardIconIncoming = Color(0xFF5A6B84);
  static const Color fileCardIconOutgoing = CommonTokens.textOnBrand;
  static const Color audioCardIncoming = Color(0xFFF5F7FA);
  static const Color audioCardOutgoing = Color(0xFF6F8EFA);
  static const Color audioTrackIncoming = Color(0xFFCCD6E3);
  static const Color audioTrackOutgoing = Color(0xFFC7D4FF);
  static const Color mediaLabelBackground = Color(0xB3141A24);
  static const Color mediaLabelText = Colors.white;

  static const Color mediaHighlightSurface = Color(0xFFFFFBEB);
  static const Color mediaPeerSurface = Color(0xFFF3F5F8);
  static const Color mediaSelfSurface = Color(0xFF7897FB);
  static const Color mediaPlaceholderBackground = CommonTokens.softSurface;
  static const Color mediaPlaceholderIcon = CommonTokens.textTertiary;

  static const Color searchChipBackground = CommonTokens.surfacePrimary;
  static const Color searchChipBorder = CommonTokens.borderColor;
  static const Color searchChipText = CommonTokens.textSecondary;

  static const TextStyle chatHeaderTitleText = CommonTokens.title;
  static const TextStyle chatHeaderSubtitleText = CommonTokens.bodySmall;
  static const TextStyle forwardChipTextStyle = CommonTokens.caption;
  static const TextStyle replyPreviewTextStyle = CommonTokens.bodySmall;
  static const TextStyle messageMetaTextStyle = CommonTokens.caption;
  static const TextStyle fileTitleTextStyle = CommonTokens.body;
  static const TextStyle fileSubtitleTextStyle = CommonTokens.caption;
  static const TextStyle audioTitleTextStyle = CommonTokens.body;
  static const TextStyle audioSubtitleTextStyle = CommonTokens.caption;
  static const TextStyle systemMessageTextStyle = CommonTokens.bodySmall;

  static const Color timeSeparatorText = CommonTokens.textTertiary;
  static const Color timeSeparatorBackground = Color(0xFFF1F4F8);
  static const Color timeSeparatorLine = CommonTokens.dividerColor;
  static const Color timeSeparatorBorder = CommonTokens.borderColor;
  static const TextStyle timeSeparatorTextStyle = CommonTokens.caption;

  static const Color headerContextText = CommonTokens.textTertiary;
  static const Color headerStatusOnline = CommonTokens.success;
  static const Color headerStatusIdle = Color(0xFF9AA6B6);
  static const Color headerContextChipBackground = Color(0xFFF1F4F8);
  static const Color headerContextChipText = CommonTokens.textSecondary;

  static const Color statusBannerBackground = Color(0xFFF8FAFD);
  static const Color statusBannerBorder = CommonTokens.borderColor;
  static const Color statusBannerTitle = CommonTokens.textPrimary;
  static const Color statusBannerSubtitle = CommonTokens.textSecondary;
  static const Color statusBannerIcon = Color(0xFF728197);
  static const Color statusBannerInfoBackground = Color(0xFFF4F7FC);
  static const Color statusBannerInfoBorder = Color(0xFFDDE6F4);
  static const Color statusBannerInfoIcon = CommonTokens.info;
  static const Color statusBannerWarningBackground = Color(0xFFFFF7EB);
  static const Color statusBannerWarningBorder = Color(0xFFF4D9A8);
  static const Color statusBannerWarningIcon = Color(0xFFB7791F);
  static const Color statusBannerSuccessBackground = Color(0xFFF1FAF5);
  static const Color statusBannerSuccessBorder = Color(0xFFCDE8D7);
  static const Color statusBannerSuccessIcon = CommonTokens.success;

  static const TextStyle headerContextTextStyle = CommonTokens.caption;
  static const TextStyle statusBannerTitleTextStyle = CommonTokens.bodySmall;
  static const TextStyle statusBannerSubtitleTextStyle = CommonTokens.caption;

  static const Color inputBarBackground = Color(0xFFF7F9FC);
  static const Color inputBarBorder = CommonTokens.dividerColor;
  static const Color inputFieldBackground = CommonTokens.surfacePrimary;
  static const Color inputFieldBorder = CommonTokens.borderColor;
  static const Color inputFieldHintText = CommonTokens.textTertiary;
  static const Color inputActionBackground = CommonTokens.surfacePrimary;
  static const Color inputActionBorder = CommonTokens.borderColor;
  static const Color inputActionIcon = CommonTokens.textSecondary;
  static const Color sendButtonBackground = CommonTokens.brandBlue;
  static const Color sendButtonDisabledBackground = Color(0xFFC9D5F2);
  static const Color sendButtonIcon = CommonTokens.textOnBrand;

  static const double radiusXs = CommonTokens.xsRadius;
  static const double radiusSm = CommonTokens.smRadius;
  static const double radiusMd = CommonTokens.mdRadius;
  static const double radiusLg = CommonTokens.lgRadius;
  static const double mediaRadius = radiusSm;
  static const double mediaRadiusMd = radiusMd;
  static const double messageContentGap = CommonTokens.xs;
  static const double replyAccentWidth = 3;
  static const double forwardChipBottomGap = CommonTokens.xs;

  static const double bubbleHorizontalPadding = CommonTokens.sm;
  static const double bubbleVerticalPadding = 9;
  static const double bubbleMaxWidthFactor = 0.76;
  static const double bubbleMaxWidth = 540;
  static const double bubbleFooterGap = 4;
  static const double imageMessageMaxWidth = 220;
  static const double imageMessageMinWidth = 164;
  static const double imageMessageMaxHeight = 260;
  static const double videoMessageHeight = 148;
  static const double fileCardMinWidth = 196;
  static const double audioCardMinWidth = 168;
  static const double messageRowVerticalPadding = 3;
  static const double messageRowHorizontalGap = 10;
  static const double messageAvatarSize = 32;
  static const double inputActionSize = 40;
  static const double sendButtonSize = 40;
  static const double inputFieldMaxLines = 4;
  static const double inputFieldMinHeight = 42;
  static const double inputBarMaxWidth = 900;
  static const double messageContentMaxWidth = 900;
  static const double headerMaxWidth = 920;
  static const double statusBannerMaxWidth = 900;
  static const double topSectionSpacing = CommonTokens.sm;
  static const double messageListTopSpacing = CommonTokens.xs;
  static const double messageListBottomSpacing = CommonTokens.sm;

  static const Color currentUserAvatarBackground = CommonTokens.brandSoft;
  static const Color currentUserAvatarBorder = Color(0xFFD6E0FF);
  static const Color currentUserAvatarIcon = CommonTokens.brandBlue;
  static const Color peerAvatarBackground = Color(0xFFF1F4F8);
  static const Color peerAvatarBorder = CommonTokens.borderColor;
  static const Color peerAvatarIcon = Color(0xFF6B7686);

  static const List<BoxShadow> surfaceShadow = CommonTokens.shadowNone;
}
