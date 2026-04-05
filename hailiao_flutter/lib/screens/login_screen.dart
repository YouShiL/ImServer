﻿import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/theme/auth_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_primary_button.dart';
import 'package:hailiao_flutter/widgets/common/app_secondary_button.dart';
import 'package:hailiao_flutter/widgets/common/app_text_field.dart';
import 'package:hailiao_flutter/widgets/common/auth_agreement_block.dart';
import 'package:hailiao_flutter/widgets/common/auth_page_scaffold.dart';
import 'package:hailiao_flutter/widgets/common/auth_welcome_block.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _handledLogoutNotice = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledLogoutNotice) {
      return;
    }
    _handledLogoutNotice = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final String? notice = context.read<AuthProvider>().consumeLogoutNotice();
      if (notice == null || notice.isEmpty) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('下线提示'),
          content: Text(notice),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({
    bool replaceExistingSession = false,
  }) async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.login(
      _phoneController.text,
      _passwordController.text,
      replaceExistingSession: replaceExistingSession,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      if (authProvider.loginNotice != null &&
          authProvider.loginNotice!.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('登录提示'),
            content: Text(authProvider.loginNotice!),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
        if (!mounted) {
          return;
        }
      }
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    final String error = authProvider.error ?? '';
    if (error.contains('设备锁已开启')) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('设备锁提示'),
          content: const Text('这个账户已开启设备锁。是否下线其他设备并继续登录当前设备？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('继续登录'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await _handleLogin(replaceExistingSession: true);
      }
    }
  }

  void _showPlaceholder(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title 暂未开放')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    return AuthPageScaffold(
      hero: const AuthWelcomeBlock(
        title: '嗨聊',
        subtitle: '欢迎回来',
        helper: '高效、安全地连接每一次聊天',
      ),
      child: Padding(
        padding: const EdgeInsets.all(AuthUiTokens.authCardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '手机号登录',
                style: AuthUiTokens.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: CommonTokens.space8),
              Text(
                '使用手机号和密码快速进入，继续刚才的会话与联系人。',
                style: AuthUiTokens.caption.copyWith(
                  color: AuthUiTokens.subtitleText,
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
                label: '登录',
                isLoading: authProvider.isLoading,
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await _handleLogin();
                        }
                      },
              ),
              if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) ...<Widget>[
                const SizedBox(height: AuthUiTokens.authFormSpacing),
                Row(
                  children: const <Widget>[
                    Expanded(
                      child: Divider(color: CommonTokens.dividerColor),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: CommonTokens.space16,
                      ),
                      child: Text('或', style: CommonTokens.caption),
                    ),
                    Expanded(
                      child: Divider(color: CommonTokens.dividerColor),
                    ),
                  ],
                ),
                const SizedBox(height: AuthUiTokens.authFormSpacing),
                AppSecondaryButton(
                  label: '扫码登录',
                  leading: const Icon(
                    Icons.qr_code_rounded,
                    color: CommonTokens.brandBlue,
                  ),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('扫码登录'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text('请使用手机客户端嗨聊扫码登录'),
                            const SizedBox(height: CommonTokens.lg),
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: CommonTokens.borderColor,
                                ),
                                borderRadius: BorderRadius.circular(
                                  CommonTokens.radiusMd,
                                ),
                              ),
                              child: const Center(
                                child: Text('二维码占位'),
                              ),
                            ),
                            const SizedBox(height: CommonTokens.md),
                            Text(
                              '扫码后会自动完成登录',
                              style: AuthUiTokens.caption.copyWith(
                                color: AuthUiTokens.tertiaryText,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: AuthUiTokens.authAgreementSpacing),
              AuthAgreementBlock(
                onPrimaryTap: () => _showPlaceholder('用户协议'),
                onSecondaryTap: () => _showPlaceholder('隐私政策'),
              ),
              const SizedBox(height: CommonTokens.space8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '还没有账号？',
                    style: AuthUiTokens.authFooterText,
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AuthUiTokens.secondaryButtonText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: CommonTokens.space8,
                        vertical: CommonTokens.space4,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      '立即注册',
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
