import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ProfileUiTokens {
  ProfileUiTokens._();

  static const Color pageBackground = CommonTokens.pageBackground;
  static const Color heroBackground = CommonTokens.surfacePrimary;
  static const Color heroAvatarBackground = Color(0xFFEFF4FF);
  static const Color heroAvatarText = CommonTokens.brandBlue;
  static const Color heroMetaChipBackground = Color(0xFFF4F7FB);
  static const Color heroMetaChipText = CommonTokens.textSecondary;
  static const Color heroStatusOnline = CommonTokens.success;
  static const Color heroStatusOffline = CommonTokens.textTertiary;
  static const Color actionSoftBackground = CommonTokens.softSurface;
  static const Color actionSoftBorder = CommonTokens.borderColor;
  static const Color actionSoftIcon = CommonTokens.textSecondary;
  static const Color dangerBackground = Color(0xFFFFF7F7);
  static const Color dangerBorder = Color(0xFFF1D5D5);
  static const Color dangerText = CommonTokens.danger;

  static const TextStyle heroTitleText = CommonTokens.headline;
  static const TextStyle heroSubtitleText = CommonTokens.body;
  static const TextStyle heroMetaText = CommonTokens.bodySmall;
  static const TextStyle sectionTitleText = CommonTokens.subtitle;
  static const TextStyle sectionSubtitleText = CommonTokens.bodySmall;
  static const TextStyle infoLabelText = CommonTokens.bodySmall;
  static const TextStyle infoValueText = CommonTokens.body;

  static const double pageMaxWidth = 920;
  static const double sectionSpacing = CommonTokens.md;
  static const double heroPadding = CommonTokens.xl;
  static const double heroAvatarSize = 88;
}
