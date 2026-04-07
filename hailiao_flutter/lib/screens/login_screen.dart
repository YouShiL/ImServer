import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/theme/auth_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_primary_button.dart';
import 'package:hailiao_flutter/widgets/common/app_secondary_button.dart';
import 'package:hailiao_flutter/widgets/common/auth_brand_header.dart';
import 'package:hailiao_flutter/widgets/common/auth_im_text_field.dart';
import 'package:hailiao_flutter/widgets/common/auth_page_scaffold.dart';
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

  bool get _canAttemptLogin {
    final String phone = _phoneController.text.trim();
    final String pwd = _passwordController.text;
    return phone.length == 11 && pwd.length >= 6;
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onCredentialsChanged);
    _passwordController.addListener(_onCredentialsChanged);
  }

  void _onCredentialsChanged() {
    setState(() {});
  }

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
    _phoneController.removeListener(_onCredentialsChanged);
    _passwordController.removeListener(_onCredentialsChanged);
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
      return;
    }

    if (error.isNotEmpty && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

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
            AppPrimaryButton(
              label: '登录',
              isLoading: authProvider.isLoading,
              onPressed: authProvider.isLoading || !_canAttemptLogin
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      await _handleLogin();
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
            const SizedBox(height: CommonTokens.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '没有账号？',
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
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    '注册',
                    style: AuthUiTokens.authLinkText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CommonTokens.brandBlue.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
