import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/call_ui_tokens.dart';

class CallStatusHeader extends StatelessWidget {
  const CallStatusHeader({
    super.key,
    required this.title,
    required this.status,
    this.subtitle,
    this.duration,
    this.dark = false,
  });

  final String title;
  final String status;
  final String? subtitle;
  final String? duration;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = dark
        ? CallUiTokens.callTitleTextOnDark
        : CallUiTokens.callTitleText;
    final TextStyle subtitleStyle = (dark
            ? CallUiTokens.callWeakTextStyleOnDark
            : CallUiTokens.callSubtitleTextStyle)
        .copyWith(
      color: dark ? Colors.white.withValues(alpha: 0.72) : null,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
        const SizedBox(height: CallUiTokens.statusSpacing),
        Text(
          status,
          textAlign: TextAlign.center,
          style: CallUiTokens.callStatusTextStyle.copyWith(
            color: dark ? Colors.white.withValues(alpha: 0.95) : null,
          ),
        ),
        if (duration != null && duration!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : CallUiTokens.audioCallAccent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : CallUiTokens.callSoftBorderLight,
              ),
            ),
            child: Text(
              duration!,
              textAlign: TextAlign.center,
              style: CallUiTokens.callDurationTextStyle.copyWith(
                color: dark ? Colors.white.withValues(alpha: 0.9) : null,
              ),
            ),
          ),
        ],
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: CallUiTokens.headerSpacing),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: subtitleStyle,
            ),
          ),
        ],
      ],
    );
  }
}
