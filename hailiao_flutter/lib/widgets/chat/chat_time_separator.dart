import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class ChatTimeSeparator extends StatelessWidget {
  const ChatTimeSeparator({
    super.key,
    required this.label,
    this.trailing,
  });

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CommonTokens.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CommonTokens.sm,
            vertical: CommonTokens.xxs,
          ),
          decoration: BoxDecoration(
            color: ChatUiTokens.timeSeparatorBackground,
            borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
            border: Border.all(color: ChatUiTokens.timeSeparatorBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: ChatUiTokens.timeSeparatorTextStyle.copyWith(
                  color: ChatUiTokens.timeSeparatorText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: CommonTokens.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
