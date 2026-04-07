import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

/// 微信式搜索条：轻灰底、细轮廓，偏「搜索入口」而非厚重输入框。
class WxSearchBar extends StatelessWidget {
  const WxSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffix,
    this.showClear = false,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffix;
  final bool showClear;
  final VoidCallback? onClear;

  /// 会话顶栏等场景：轻、贴。
  static const double height = 34;
  static const double radius = 16;

  @override
  Widget build(BuildContext context) {
    final Widget prefix = prefixIcon ??
        Icon(
          Icons.search_rounded,
          size: 16,
          color: CommonTokens.textTertiary,
        );

    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    );

    Widget? suffixIcon = suffix;
    if (showClear && onClear != null) {
      suffixIcon = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (suffix case final Widget w) w,
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: CommonTokens.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            onPressed: onClear,
          ),
        ],
      );
    }

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        autofocus: autofocus,
        onTap: onTap,
        textAlignVertical: TextAlignVertical.center,
        style: CommonTokens.body.copyWith(
          color: CommonTokens.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: CommonTokens.caption.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: CommonTokens.textTertiary,
          ),
          filled: true,
          fillColor: CommonTokens.lineSubtle,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          prefixIcon: prefix,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: height,
          ),
          suffixIcon: suffixIcon,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          disabledBorder: border,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
