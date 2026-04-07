import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/theme/auth_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_primary_button.dart';
import 'package:hailiao_flutter/widgets/common/auth_brand_header.dart';
import 'package:hailiao_flutter/widgets/common/auth_im_text_field.dart';
import 'package:hailiao_flutter/widgets/common/auth_page_scaffold.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;

  bool get _canSubmit {
    final String nickname = _nicknameController.text;
    final String phone = _phoneController.text;
    final String pwd = _passwordController.text;
    return nickname.length >= 2 &&
        phone.length == 11 &&
        pwd.length >= 6 &&
        _agreedToTerms;
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onFieldsChanged);
    _passwordController.addListener(_onFieldsChanged);
    _nicknameController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onFieldsChanged);
    _passwordController.removeListener(_onFieldsChanged);
    _nicknameController.removeListener(_onFieldsChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.register(
      _phoneController.text,
      _passwordController.text,
      _nicknameController.text,
    );
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    final String msg = authProvider.error ?? '注册失败，请稍后重试';
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    final TextStyle agreementStyle = CommonTokens.bodySmall.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      color: CommonTokens.textSecondary,
      height: 1.35,
    );
    final TextStyle agreementLinkStyle = agreementStyle.copyWith(
      color: CommonTokens.brandBlue.withValues(alpha: 0.82),
      fontWeight: FontWeight.w500,
    );

    return AuthPageScaffold(
      wrapChildInSurface: false,
      hero: const AuthBrandHeader(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FormField<String>(
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return '请输入昵称';
                }
                if (value.length < 2) {
                  return '昵称至少需要 2 个字';
                }
                return null;
              },
              builder: (FormFieldState<String> state) => AuthImTextField(
                controller: _nicknameController,
                hintText: '昵称',
                prefixIcon: Icons.person_outline_rounded,
                errorText: state.errorText,
                onChanged: (_) => state.didChange(_nicknameController.text),
              ),
            ),
            const SizedBox(height: CommonTokens.space12),
            FormField<String>(
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return '请输入手机号';
                }
                if (value.length != 11) {
                  return '请输入正确的手机号';
                }
                return null;
              },
              builder: (FormFieldState<String> state) => AuthImTextField(
                controller: _phoneController,
                hintText: '手机号',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_iphone_rounded,
                errorText: state.errorText,
                onChanged: (_) => state.didChange(_phoneController.text),
              ),
            ),
            const SizedBox(height: CommonTokens.space12),
            FormField<String>(
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6) {
                  return '密码长度至少 6 位';
                }
                return null;
              },
              builder: (FormFieldState<String> state) => AuthImTextField(
                controller: _passwordController,
                hintText: '密码',
                obscureText: !_isPasswordVisible,
                prefixIcon: Icons.lock_outline_rounded,
                errorText: state.errorText,
                onChanged: (_) => state.didChange(_passwordController.text),
                suffix: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 20,
                    color: CommonTokens.textTertiary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: CommonTokens.space24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '已有账号？',
                  style: AuthUiTokens.authFooterText.copyWith(
                    fontSize: 14,
                    color: CommonTokens.textSecondary,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: CommonTokens.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: CommonTokens.space8,
                      vertical: CommonTokens.space4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    '登录',
                    style: AuthUiTokens.authLinkText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CommonTokens.brandBlue.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CommonTokens.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Checkbox(
                  value: _agreedToTerms,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: CommonTokens.textTertiary),
                  onChanged: (bool? value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                ),
                const SizedBox(width: CommonTokens.space4),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 0,
                    runSpacing: CommonTokens.space4,
                    children: <Widget>[
                      Text(
                        '我已阅读并同意 ',
                        style: agreementStyle,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/user-agreement');
                        },
                        child: Text(
                          '《用户协议》',
                          style: agreementLinkStyle,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/privacy-policy');
                        },
                        child: Text(
                          '《隐私政策》',
                          style: agreementLinkStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CommonTokens.space16),
            AppPrimaryButton(
              label: '注册',
              isLoading: authProvider.isLoading,
              onPressed: authProvider.isLoading || !_canSubmit
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      if (!_agreedToTerms) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('请先阅读并同意用户协议与隐私政策'),
                          ),
                        );
                        return;
                      }
                      await _handleRegister();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
