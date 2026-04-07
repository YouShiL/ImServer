import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

/// 产品级 UI 设计 Token（圆角 / 间距 / 色板 / 阴影 / 三类按钮）。
abstract final class UiTokens {
  UiTokens._();

  // --- Radius ---
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusDialog = 20;

  // --- Spacing ---
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;

  // --- Colors ---
  /// 全应用唯一主色（主按钮 / 强调链接 / 焦点边框）。
  static const Color primaryBlue = Color(0xFF5C7CFA);
  static const Color primaryBluePressed = Color(0xFF4B68D6);

  static const Color backgroundGray = Color(0xFFF7F7F7);

  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF666666);
  static const Color dangerRed = Color(0xFFD94B4B);

  static const Color lineSubtle = Color(0xFFEEEEEE);

  /// 极轻阴影（卡片浮起）。
  static const List<BoxShadow> shadowLight = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D0E1726),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// 筛选 Chip 选中淡色底（主色透明叠层）。
  static Color chipSelectedBackground() =>
      primaryBlue.withValues(alpha: 0.12);

  /// 屏幕内表单/资料页输入框（与弹窗视觉一致，略浅底）。
  static InputDecoration screenFieldDecoration({
    required String label,
    String? hint,
    bool alignLabelWithHint = false,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSmall),
      borderSide: const BorderSide(color: lineSubtle),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: backgroundGray,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: space16,
        vertical: space16,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }

  /// 白底分组容器（Messenger / 设置列表式：一组一项圆角容器）。
  static BoxDecoration groupedListDecoration() {
    return BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(radiusLarge),
      boxShadow: shadowLight,
    );
  }

  // --- Buttons（仅三类：主色填充 / 描边次要 / 红色危险）---
  static ButtonStyle filledPrimary({EdgeInsetsGeometry? padding}) {
    return FilledButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFB8C7F4),
      disabledForegroundColor: Colors.white70,
      minimumSize: const Size(0, ImDesignTokens.heightButton),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: ImDesignTokens.spaceLg,
            vertical: ImDesignTokens.spaceSm,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ImDesignTokens.radiusMd),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }

  static ButtonStyle outlinedSecondary({EdgeInsetsGeometry? padding}) {
    return OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      disabledForegroundColor: textSecondary.withValues(alpha: 0.45),
      side: const BorderSide(color: lineSubtle),
      minimumSize: const Size(0, ImDesignTokens.heightButton),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: ImDesignTokens.spaceLg,
            vertical: ImDesignTokens.spaceSm,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ImDesignTokens.radiusMd),
      ),
    );
  }

  static ButtonStyle filledDanger({EdgeInsetsGeometry? padding}) {
    return FilledButton.styleFrom(
      backgroundColor: dangerRed,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE8A0A0),
      disabledForegroundColor: Colors.white70,
      minimumSize: const Size(0, ImDesignTokens.heightButton),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: ImDesignTokens.spaceLg,
            vertical: ImDesignTokens.spaceSm,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ImDesignTokens.radiusMd),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }
}
