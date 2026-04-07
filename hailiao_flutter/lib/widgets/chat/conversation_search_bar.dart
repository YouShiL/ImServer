import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/conversation_ui_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';

class ConversationSearchBar extends StatelessWidget {
  const ConversationSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.showClear = false,
    this.enabled = true,
    this.trailing,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool showClear;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ConversationUiTokens.searchBarHeight,
      child: Container(
        decoration: BoxDecoration(
          color: ConversationUiTokens.searchBarBackground,
          borderRadius: BorderRadius.circular(ImDesignTokens.radiusMd),
          border: Border.all(color: UiTokens.lineSubtle),
          boxShadow: ConversationUiTokens.searchBarShadow,
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          enabled: enabled,
          textAlignVertical: TextAlignVertical.center,
          style: CommonTokens.body,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: CommonTokens.bodySmall.copyWith(
              color: ConversationUiTokens.searchBarHintText,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ImDesignTokens.spaceLg,
              vertical: ImDesignTokens.spaceSm,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: ImDesignTokens.spaceSm,
              ),
              child: Icon(
                Icons.search,
                size: ImDesignTokens.iconSm,
                color: ConversationUiTokens.searchBarIcon,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: ConversationUiTokens.searchBarHeight,
              minHeight: ConversationUiTokens.searchBarHeight,
            ),
            suffixIcon: trailing ??
                (showClear
                    ? IconButton(
                        onPressed: onClear,
                        icon: Icon(
                          Icons.close,
                          size: ImDesignTokens.iconSm,
                          color: ConversationUiTokens.searchBarIcon,
                        ),
                      )
                    : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ImDesignTokens.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ImDesignTokens.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ImDesignTokens.radiusMd),
              borderSide: const BorderSide(
                color: ConversationUiTokens.searchBarFocusedBorder,
                width: 1.5,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
