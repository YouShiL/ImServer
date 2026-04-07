import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: ImDesignTokens.heightButton,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isDisabled
              ? CommonTokens.primaryButtonBackgroundDisabled
              : CommonTokens.primaryButtonBackground,
          foregroundColor: isDisabled
              ? CommonTokens.primaryButtonTextDisabled
              : CommonTokens.primaryButtonText,
          disabledBackgroundColor: CommonTokens.primaryButtonBackgroundDisabled,
          disabledForegroundColor: CommonTokens.primaryButtonTextDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: CommonTokens.space20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              CommonTokens.primaryButtonRadius,
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CommonTokens.primaryButtonText,
                ),
              )
            : Text(
                label,
                style: CommonTokens.buttonPrimaryTextStyle.copyWith(
                  color: isDisabled
                      ? CommonTokens.primaryButtonTextDisabled
                      : CommonTokens.primaryButtonText,
                ),
              ),
      ),
    );
  }
}
