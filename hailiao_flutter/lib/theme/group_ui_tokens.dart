import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class GroupUiTokens {
  GroupUiTokens._();

  static const Color pageBackground = CommonTokens.pageBackground;
  static const Color sectionBackground = CommonTokens.surfacePrimary;
  static const Color sectionBorder = CommonTokens.borderColor;
  static const Color heroBackground = CommonTokens.surfacePrimary;
  static const Color heroSoftBackground = CommonTokens.softSurface;
  static const Color heroAvatarBackground = CommonTokens.brandSoft;
  static const Color heroAvatarIcon = CommonTokens.brandBlue;
  static const Color chipBackground = CommonTokens.softSurface;
  static const Color chipText = CommonTokens.textSecondary;
  static const Color chipAccentBackground = Color(0xFFEFF5FF);
  static const Color chipAccentText = CommonTokens.brandBlue;
  static const Color noticeBackground = Color(0xFFF7F9FC);
  static const Color noticeBorder = Color(0xFFE5ECF5);
  static const Color noticeIcon = Color(0xFF6B7A90);
  static const Color memberAvatarBackground = Color(0xFFF1F4F8);
  static const Color memberAvatarText = CommonTokens.textPrimary;
  static const Color memberAvatarBorder = CommonTokens.borderColor;
  static const Color settingIconBackground = Color(0xFFF3F6FA);
  static const Color settingIconColor = Color(0xFF617186);
  static const Color dangerBackground = Color(0xFFFFF7F7);
  static const Color dangerBorder = Color(0xFFF1D5D5);
  static const Color dangerText = CommonTokens.danger;
  static const Color dangerSoftText = Color(0xFFB14A4A);

  static const TextStyle sectionTitleText = CommonTokens.subtitle;
  static const TextStyle sectionSubtitleText = CommonTokens.bodySmall;
  static const TextStyle heroTitleText = CommonTokens.headline;
  static const TextStyle heroSubtitleText = CommonTokens.body;
  static const TextStyle heroMetaText = CommonTokens.bodySmall;
  static const TextStyle memberNameText = CommonTokens.bodySmall;
  static const TextStyle memberRoleText = CommonTokens.caption;

  static const double pageMaxWidth = 920;
  static const double sectionSpacing = CommonTokens.md;
  static const double sectionPadding = CommonTokens.md;
  static const double heroPadding = CommonTokens.xl;
  static const double heroAvatarSize = 84;
  static const double memberPreviewAvatarSize = 42;
  static const double memberPreviewGap = CommonTokens.sm;
  static const double memberPreviewStripHeight = 84;
}
