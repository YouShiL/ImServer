import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/call_ui_tokens.dart';

class CallControlButton extends StatelessWidget {
  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.destructive = false,
    this.enabled = true,
    this.dark = false,
    this.size,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool destructive;
  final bool enabled;
  final bool dark;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final double buttonSize = size ??
        (destructive
            ? CallUiTokens.controlButtonSize
            : CallUiTokens.smallControlButtonSize);
    final Color background = destructive
        ? CallUiTokens.endCallButtonBackground
        : active
            ? CallUiTokens.controlButtonActiveBackground
            : dark
                ? CallUiTokens.controlButtonBackground
                : CallUiTokens.controlButtonBackgroundLight;
    final Color border = destructive
        ? Colors.transparent
        : active
            ? CallUiTokens.controlButtonActiveBorder
            : dark
                ? CallUiTokens.controlButtonBorder
                : CallUiTokens.controlButtonBorderLight;
    final Color iconColor = destructive
        ? CallUiTokens.endCallIconColor
        : dark
            ? CallUiTokens.controlIconColor
            : CallUiTokens.controlIconColorLight;
    final Color labelColor = destructive
        ? (dark ? Colors.white : CallUiTokens.callTextPrimary)
        : dark
            ? Colors.white.withValues(alpha: 0.92)
            : CallUiTokens.callTextPrimary;

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(buttonSize / 2),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: buttonSize),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: destructive ? null : Border.all(color: border),
                boxShadow: destructive
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x2AE04F5F),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: CallUiTokens.controlLabelGap),
            Text(
              label,
              textAlign: TextAlign.center,
              style: CallUiTokens.callWeakTextStyle.copyWith(
                color: labelColor,
                fontWeight: destructive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
