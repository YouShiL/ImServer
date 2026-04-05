import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: CommonTokens.secondaryButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: CommonTokens.secondaryButtonBackground,
          foregroundColor: isDisabled
              ? CommonTokens.secondaryButtonTextDisabled
              : CommonTokens.secondaryButtonText,
          disabledForegroundColor: CommonTokens.secondaryButtonTextDisabled,
          side: BorderSide(
            color: isDisabled
                ? CommonTokens.secondaryButtonTextDisabled
                : CommonTokens.secondaryButtonBorder,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: CommonTokens.space20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              CommonTokens.secondaryButtonRadius,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: CommonTokens.buttonIconGap),
            ],
            Text(
              label,
              style: CommonTokens.buttonSecondaryTextStyle.copyWith(
                color: isDisabled
                    ? CommonTokens.secondaryButtonTextDisabled
                    : CommonTokens.secondaryButtonText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
