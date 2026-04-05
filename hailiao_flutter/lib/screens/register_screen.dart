import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/theme/auth_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_primary_button.dart';
import 'package:hailiao_flutter/widgets/common/app_text_field.dart';
import 'package:hailiao_flutter/widgets/common/auth_agreement_block.dart';
import 'package:hailiao_flutter/widgets/common/auth_page_scaffold.dart';
import 'package:hailiao_flutter/widgets/common/auth_welcome_block.dart';
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

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _showPlaceholder(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title 暂未开放')));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    return AuthPageScaffold(
      hero: const AuthWelcomeBlock(
        title: '嗨聊',
        subtitle: '创建新账号',
        helper: '用手机号快速完成注册，马上开始聊天与群组互动。',
      ),
      child: Padding(
        padding: const EdgeInsets.all(AuthUiTokens.authCardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '手机号注册',
                style: AuthUiTokens.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: CommonTokens.space8),
              Text(
                '填写基础资料即可完成注册，后续可以在个人资料页继续完善信息。',
                style: AuthUiTokens.caption.copyWith(
                  color: AuthUiTokens.subtitleText,
                ),
              ),
              const SizedBox(height: AuthUiTokens.authFormSpacing),
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
                builder: (FormFieldState<String> state) => AppTextField(
                  controller: _nicknameController,
                  hintText: '昵称',
                  prefix: const Icon(
                    Icons.person_outline_rounded,
                    color: CommonTokens.textSecondary,
                  ),
                  errorText: state.errorText,
                  onChanged: state.didChange,
                ),
              ),
              const SizedBox(height: AuthUiTokens.authFormSpacing),
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
                builder: (FormFieldState<String> state) => AppTextField(
                  controller: _phoneController,
                  hintText: '手机号',
                  keyboardType: TextInputType.phone,
                  prefix: const Icon(
                    Icons.phone_iphone_rounded,
                    color: CommonTokens.textSecondary,
                  ),
                  errorText: state.errorText,
                  onChanged: state.didChange,
                ),
              ),
              const SizedBox(height: AuthUiTokens.authFormSpacing),
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
                builder: (FormFieldState<String> state) => AppTextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  hintText: '密码',
                  prefix: const Icon(
                    Icons.lock_outline_rounded,
                    color: CommonTokens.textSecondary,
                  ),
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  errorText: state.errorText,
                  onChanged: state.didChange,
                ),
              ),
              const SizedBox(height: CommonTokens.space12),
              if (authProvider.error != null) _buildError(authProvider.error!),
              AppPrimaryButton(
                label: '注册',
                isLoading: authProvider.isLoading,
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await _handleRegister();
                        }
                      },
              ),
              const SizedBox(height: AuthUiTokens.authAgreementSpacing),
              AuthAgreementBlock(
                prefix: '注册即代表你已阅读并同意',
                onPrimaryTap: () => _showPlaceholder('用户协议'),
                onSecondaryTap: () => _showPlaceholder('隐私政策'),
              ),
              const SizedBox(height: CommonTokens.space8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '已有账号？',
                    style: AuthUiTokens.authFooterText,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      '立即登录',
                      style: AuthUiTokens.authLinkText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: CommonTokens.space8,
        horizontal: CommonTokens.space16,
      ),
      margin: const EdgeInsets.only(bottom: CommonTokens.space16),
      decoration: BoxDecoration(
        color: CommonTokens.dangerSoft,
        borderRadius: BorderRadius.circular(CommonTokens.radiusSm),
        border: Border.all(color: CommonTokens.danger.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: CommonTokens.secondary.copyWith(color: CommonTokens.danger),
      ),
    );
  }
}
