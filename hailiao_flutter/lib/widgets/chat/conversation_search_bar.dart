import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/conversation_ui_tokens.dart';

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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ConversationUiTokens.searchBarMaxWidth,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: ConversationUiTokens.searchBarBackground,
            borderRadius: BorderRadius.circular(CommonTokens.smRadius),
            border: Border.all(color: ConversationUiTokens.searchBarBorder),
            boxShadow: ConversationUiTokens.searchBarShadow,
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
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
                horizontal: CommonTokens.md,
                vertical: CommonTokens.sm,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsetsDirectional.only(start: CommonTokens.xs),
                child: Icon(
                  Icons.search,
                  size: 20,
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
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: ConversationUiTokens.searchBarIcon,
                          ),
                        )
                      : null),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CommonTokens.smRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CommonTokens.smRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CommonTokens.smRadius),
                borderSide: const BorderSide(
                  color: ConversationUiTokens.searchBarFocusedBorder,
                ),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
