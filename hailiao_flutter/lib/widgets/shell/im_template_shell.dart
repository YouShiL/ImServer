import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';

/// IM 资料/群组等页统一模板：间距、卡片、弹窗形态（不含业务状态）。
abstract final class ImTemplateShell {
  ImTemplateShell._();

  static const double pagePaddingH = ImDesignTokens.spaceLg;
  static const double pagePaddingV = ImDesignTokens.spaceLg;
  static const double sectionGap = ImDesignTokens.spaceXl;
  static const double cardRadius = UiTokens.radiusLarge;
  static const double cardInnerPadding = ImDesignTokens.spaceLg;
  static const double elementGapSm = ImDesignTokens.spaceSm;
  static const double elementGapMd = ImDesignTokens.spaceMd;

  static const double dialogCornerRadius = ImDesignTokens.imDialogRadius;
  static const double dialogPadding = ImDesignTokens.dialogPadding;

  static const ShapeBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(
      Radius.circular(ImDesignTokens.imDialogRadius),
    ),
  );

  static const EdgeInsets dialogInsetPadding = EdgeInsets.symmetric(
    horizontal: ImDesignTokens.spaceXl,
    vertical: ImDesignTokens.spaceXl,
  );

  /// 弹窗内容区统一内边距（操作面板感，非厚表单框）。
  static const EdgeInsets dialogTitlePadding = EdgeInsets.fromLTRB(
    dialogPadding,
    dialogPadding,
    dialogPadding,
    ImDesignTokens.spaceSm,
  );

  static const EdgeInsets dialogContentPadding = EdgeInsets.fromLTRB(
    dialogPadding,
    ImDesignTokens.spaceSm,
    dialogPadding,
    ImDesignTokens.spaceSm,
  );

  static const EdgeInsets dialogActionsPadding = EdgeInsets.fromLTRB(
    dialogPadding,
    ImDesignTokens.spaceSm,
    dialogPadding,
    dialogPadding,
  );

  static TextStyle pageTitleText(BuildContext context) =>
      CommonTokens.title.copyWith(fontSize: 17, fontWeight: FontWeight.w700);

  static TextStyle pageSubtitleText(BuildContext context) =>
      CommonTokens.bodySmall.copyWith(
        color: CommonTokens.textSecondary,
        fontWeight: FontWeight.w400,
        fontSize: 13,
      );

  static TextStyle sectionHeadingText(BuildContext context) =>
      CommonTokens.subtitle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );

  static TextStyle bodyPrimaryText(BuildContext context) =>
      CommonTokens.body.copyWith(fontSize: 15, fontWeight: FontWeight.w500);

  static TextStyle bodyMutedText(BuildContext context) =>
      CommonTokens.metaTextStyle;

  /// 统一输入框高度与圆角（弹窗内）。
  static InputDecoration dialogFieldDecoration({
    required String label,
    String? hint,
    bool alignLabelWithHint = false,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(ImDesignTokens.radiusSm),
      borderSide: const BorderSide(color: UiTokens.lineSubtle),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: UiTokens.backgroundGray,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ImDesignTokens.spaceLg,
        vertical: ImDesignTokens.spaceMd,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ImDesignTokens.radiusSm),
        borderSide: const BorderSide(color: UiTokens.primaryBlue, width: 1.5),
      ),
    );
  }
}

/// 白底卡片：统一圆角 16、内边距 16、极轻阴影（无嵌套「卡片套卡片」）。
class ImShellCard extends StatelessWidget {
  const ImShellCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ImTemplateShell.cardInnerPadding),
    this.margin,
    this.backgroundColor,
    this.showShadow = true,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool showShadow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? UiTokens.cardWhite,
        borderRadius: BorderRadius.circular(ImTemplateShell.cardRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : null,
        boxShadow: showShadow ? UiTokens.shadowLight : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// 弹窗标题样式（与 [AlertDialog.title] 配合）。
class ImDialogTitle extends StatelessWidget {
  const ImDialogTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: CommonTokens.title.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: UiTokens.textPrimary,
      ),
    );
  }
}
