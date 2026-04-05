import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: CommonTokens.body,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: CommonTokens.secondary,
        prefixIcon: prefix == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: CommonTokens.space12,
                  end: CommonTokens.space8,
                ),
                child: prefix,
              ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
        suffixIcon: suffix,
        errorText: errorText,
        filled: true,
        fillColor: CommonTokens.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CommonTokens.space16,
          vertical: CommonTokens.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
          borderSide: const BorderSide(color: CommonTokens.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
          borderSide: const BorderSide(color: CommonTokens.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
          borderSide: const BorderSide(color: CommonTokens.brandBlue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
          borderSide: const BorderSide(color: CommonTokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
          borderSide: const BorderSide(color: CommonTokens.danger),
        ),
      ),
    );
  }
}
