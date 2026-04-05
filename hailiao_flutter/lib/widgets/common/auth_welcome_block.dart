import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/auth_ui_tokens.dart';

class AuthWelcomeBlock extends StatelessWidget {
  const AuthWelcomeBlock({
    super.key,
    required this.title,
    required this.subtitle,
    this.helper,
  });

  final String title;
  final String subtitle;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AuthUiTokens.heroBlockMaxWidth),
      child: Column(
        children: <Widget>[
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AuthUiTokens.brandBlue,
              borderRadius: BorderRadius.circular(AuthUiTokens.heroRadius),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: AuthUiTokens.heroIconSize,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AuthUiTokens.title,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AuthUiTokens.subtitle,
          ),
          if ((helper ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AuthUiTokens.helperBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AuthUiTokens.helperBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: AuthUiTokens.helperIcon,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      helper!,
                      textAlign: TextAlign.center,
                      style: AuthUiTokens.helperText.copyWith(
                        color: AuthUiTokens.subtitleText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
