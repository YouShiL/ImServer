import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

/// 认证页无边框、浅灰填充的 IM 风格输入框（登录 / 注册共用）。
class AuthImTextField extends StatelessWidget {
  const AuthImTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    required this.prefixIcon,
    this.suffix,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final Widget? suffix;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  static const double fieldHeight = 40;
  static const double fieldRadius = 20;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder shape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide.none,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: fieldHeight,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.center,
            style: CommonTokens.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: CommonTokens.brandBlue,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: CommonTokens.caption.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: CommonTokens.textTertiary,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: CommonTokens.space12,
                  end: CommonTokens.space4,
                ),
                child: Icon(
                  prefixIcon,
                  size: 18,
                  color: CommonTokens.textTertiary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: fieldHeight,
              ),
              suffixIcon: suffix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: suffix,
                    ),
              suffixIconConstraints: const BoxConstraints(
                minHeight: fieldHeight,
                minWidth: 40,
              ),
              filled: true,
              fillColor: CommonTokens.lineSubtle,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: CommonTokens.space4,
                vertical: CommonTokens.space8,
              ),
              border: shape,
              enabledBorder: shape,
              focusedBorder: shape,
              disabledBorder: shape,
              errorBorder: shape,
              focusedErrorBorder: shape,
            ),
          ),
        ),
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: CommonTokens.space12,
              top: CommonTokens.space4,
            ),
            child: Text(
              errorText!,
              style: CommonTokens.caption.copyWith(
                color: CommonTokens.danger,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
