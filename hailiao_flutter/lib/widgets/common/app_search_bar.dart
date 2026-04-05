import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = '搜索',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      style: CommonTokens.body,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: CommonTokens.secondary,
        prefixIcon: const Icon(
          Icons.search,
          color: CommonTokens.textSecondary,
        ),
        filled: true,
        fillColor: CommonTokens.searchBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CommonTokens.space16,
          vertical: CommonTokens.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CommonTokens.radiusLg),
          borderSide: const BorderSide(color: CommonTokens.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CommonTokens.radiusLg),
          borderSide: const BorderSide(color: CommonTokens.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CommonTokens.radiusLg),
          borderSide: const BorderSide(color: CommonTokens.brandBlue),
        ),
      ),
    );
  }
}
