import 'package:flutter/material.dart';

class CommonTokens {
  CommonTokens._();

  // Foundation colors
  static const Color brandBlue = Color(0xFF5C7CFA);
  static const Color brandPressed = Color(0xFF4B68D6);
  static const Color brandSoft = Color(0xFFEAF0FF);
  static const Color brandYellow = Color(0xFFF1B94C);
  static const Color brandOrange = Color(0xFFEA7A2F);

  /// 产品级页面灰底（微信/Telegram 系浅色底）。
  static const Color bgPrimary = Color(0xFFF7F7F7);
  static const Color bgSecondary = Color(0xFFF0F4F8);
  static const Color surfacePrimary = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFD);
  static const Color elevatedSurface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF8E99AA);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  static const Color lineSubtle = Color(0xFFEEEEEE);
  static const Color dividerSoft = Color(0xFFEEF2F6);
  static const Color hairlineSoft = Color(0xFFF3F5F8);

  static const Color success = Color(0xFF1FA971);
  static const Color warning = Color(0xFFF5A524);
  static const Color danger = Color(0xFFD94B4B);
  static const Color dangerSoft = Color(0xFFFDECEC);
  static const Color info = brandBlue;

  // Foundation spacing (4pt grid)
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  // Backward-compatible spacing aliases
  static const double space4 = xxs;
  static const double space8 = xs;
  static const double space12 = sm;
  static const double space16 = md;
  static const double space20 = lg;
  static const double space24 = xl;

  // Foundation radius
  static const double xsRadius = 8;
  static const double smRadius = 12;
  static const double mdRadius = 16;
  static const double lgRadius = 20;
  static const double xlRadius = 24;
  static const double pillRadius = 999;

  // Backward-compatible radius aliases
  static const double radiusSm = smRadius;
  static const double radiusMd = mdRadius;
  static const double radiusLg = lgRadius;
  static const double radiusXl = xlRadius;

  // Foundation shadows
  static const List<BoxShadow> shadowSoft = <BoxShadow>[
    BoxShadow(
      color: Color(0x120E1726),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> shadowFloating = <BoxShadow>[
    BoxShadow(
      color: Color(0x120E1726),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
  static const List<BoxShadow> shadowNone = <BoxShadow>[];

  // Typography
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    height: 1.3,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.45,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.35,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.25,
  );

  // Backward-compatible typography aliases
  static const TextStyle section = title;
  static const TextStyle secondary = bodySmall;

  // Semantic tokens
  static const Color pageBackground = Color(0xFFF7F7F7);
  static const Color appSurface = Color(0xFFFFFFFF);
  static const Color appBorder = Color(0xFFEEEEEE);
  static const Color appTextPrimary = Color(0xFF111111);
  static const Color appTextSecondary = Color(0xFF666666);
  static const Color cardBackground = surfacePrimary;
  static const Color inputBackground = surfacePrimary;
  static const Color searchBackground = surfaceMuted;
  static const Color softSurface = surfaceMuted;
  static const Color dividerColor = dividerSoft;
  static const Color borderColor = lineSubtle;
  static const Color hairlineColor = hairlineSoft;
  static const Color headerBackground = bgPrimary;

  static const Color primaryButtonBackground = brandBlue;
  static const Color primaryButtonBackgroundDisabled = Color(0xFFB8C7F4);
  static const Color primaryButtonText = textOnBrand;
  static const Color primaryButtonTextDisabled = Color(0xFFF8FAFD);
  static const double primaryButtonHeight = 54;
  static const double primaryButtonRadius = smRadius;

  static const Color secondaryButtonText = brandBlue;
  static const Color secondaryButtonTextDisabled = Color(0xFF94A7E5);
  static const Color secondaryButtonBorder = lineSubtle;
  static const Color secondaryButtonBackground = surfacePrimary;
  static const Color secondaryButtonBackgroundPressed = brandSoft;
  static const double secondaryButtonHeight = 54;
  static const double secondaryButtonRadius = smRadius;
  static const double buttonIconGap = xs;

  static const Color badgeBackground = surfaceMuted;
  static const Color badgeText = textSecondary;

  static const TextStyle buttonPrimaryTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: primaryButtonText,
    height: 1.2,
  );

  static const TextStyle buttonSecondaryTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: secondaryButtonText,
    height: 1.2,
  );

  static const TextStyle listTitleTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.35,
  );

  static const TextStyle listSubtitleTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.45,
  );

  static const TextStyle metaTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    height: 1.3,
  );
}

/// 第二轮 IM 统一设计 Token：间距 / 圆角 / 高度 / 语义色（页面引用本类，避免魔法数）。
abstract final class ImDesignTokens {
  ImDesignTokens._();

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  /// 弹窗大圆角（与 [spaceXl] 不同：24 为版心区块间距，20 为对话框圆角与内边距基准）。
  static const double radiusXl = 20;
  static const double imDialogPadding = 16;
  static const double imDialogRadius = 16;

  static const double heightInput = 44;
  static const double heightItem = 56;
  static const double heightButton = 48;

  /// 资料 / 设置列表左侧圆形 icon 底。
  static const double leadingIconSize = 40;

  static const double dialogPadding = imDialogPadding;
  static const double dialogSectionGap = spaceLg;

  static const double iconSm = 20;
  static const double iconMd = 22;
  static const double iconLg = 24;

  static const Color primary = CommonTokens.brandBlue;
  static const Color textPrimary = CommonTokens.textPrimary;
  static const Color textSecondary = CommonTokens.textSecondary;
  static const Color border = CommonTokens.appBorder;
  static const Color surface = CommonTokens.appSurface;
  static const Color background = CommonTokens.pageBackground;
}
