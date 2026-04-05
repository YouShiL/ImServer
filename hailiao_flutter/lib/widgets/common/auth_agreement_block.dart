import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/auth_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

class AuthAgreementBlock extends StatelessWidget {
  const AuthAgreementBlock({
    super.key,
    this.prefix = '登录即代表你已阅读并同意',
    this.primaryLabel = '用户协议',
    this.secondaryLabel = '隐私政策',
    this.onPrimaryTap,
    this.onSecondaryTap,
  });

  final String prefix;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CommonTokens.xxs,
      runSpacing: CommonTokens.xxs,
      children: <Widget>[
        Text(
          prefix,
          style: AuthUiTokens.agreementTextStyle.copyWith(
            color: AuthUiTokens.agreementText,
          ),
        ),
        _AgreementLink(
          label: primaryLabel,
          onTap: onPrimaryTap,
        ),
        Text(
          '与',
          style: AuthUiTokens.agreementTextStyle.copyWith(
            color: AuthUiTokens.agreementText,
          ),
        ),
        _AgreementLink(
          label: secondaryLabel,
          onTap: onSecondaryTap,
        ),
      ],
    );
  }
}

class _AgreementLink extends StatelessWidget {
  const _AgreementLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: AuthUiTokens.agreementTextStyle.copyWith(
            color: AuthUiTokens.agreementLinkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
