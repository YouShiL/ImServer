import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class AppUiTokens {
  AppUiTokens._();

  static const Color pageBackground = CommonTokens.pageBackground;
  static const Color surface = CommonTokens.surfacePrimary;
  static const Color softSurface = CommonTokens.surfaceMuted;
  static const Color border = CommonTokens.dividerColor;
  static const Color mutedText = CommonTokens.textSecondary;
  static const Color subtleText = CommonTokens.textTertiary;
  static const Color danger = CommonTokens.danger;
  static const Color warning = CommonTokens.brandOrange;
  static const Color success = CommonTokens.success;
  static const Color info = CommonTokens.brandBlue;
  static const Color selected = Color(0xFFDBEAFE);
  static const Color highlight = Color(0xFFFFF3C4);

  static const double radiusXs = CommonTokens.space8;
  static const double radiusSm = CommonTokens.radiusSm;
  static const double radiusMd = CommonTokens.radiusMd;
  static const double radiusLg = CommonTokens.radiusLg;
  static const double gapXs = CommonTokens.space4;
  static const double gapSm = CommonTokens.space8;
  static const double gapMd = CommonTokens.space12;
  static const double gapLg = CommonTokens.space16;
  static const double gapXl = CommonTokens.space20;

  static const List<BoxShadow> cardShadow = CommonTokens.shadowSoft;
}
