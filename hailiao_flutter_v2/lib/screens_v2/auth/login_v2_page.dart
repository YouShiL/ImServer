import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter_v2/screens_v2/auth/register_v2_page.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:provider/provider.dart';

class LoginV2Page extends StatefulWidget {
  const LoginV2Page({super.key});

  @override
  State<LoginV2Page> createState() => _LoginV2PageState();
}

class _LoginV2PageState extends State<LoginV2Page> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _handledLogoutNotice = false;

  bool get _canAttemptLogin {
    return _phoneController.text.trim().length == 11 &&
        _passwordController.text.length >= 6;
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_refresh);
    _passwordController.addListener(_refresh);
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
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('登录提示'),
            content: Text(notice),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('知道了'),
              ),
            ],
          );
        },
      );
    });
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_refresh);
    _passwordController.removeListener(_refresh);
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      final String? notice = authProvider.loginNotice;
      if (notice != null && notice.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(notice)));
      }
      return;
    }

    final String message = authProvider.error ?? '登录失败，请稍后重试';
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: ChatV2Tokens.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 24),
                  Text(
                    '登录',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '使用旧工程已稳定的账号密码链路进入 V2 主壳',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: '手机号',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            final String phone = (value ?? '').trim();
                            if (phone.isEmpty) {
                              return '请输入手机号';
                            }
                            if (phone.length != 11) {
                              return '请输入正确的手机号';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: '密码',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (String? value) {
                            final String password = value ?? '';
                            if (password.isEmpty) {
                              return '请输入密码';
                            }
                            if (password.length < 6) {
                              return '密码长度至少 6 位';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: authProvider.isLoading || !_canAttemptLogin
                        ? null
                        : _handleLogin,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登录'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('没有账号？'),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterV2Page(),
                                  ),
                                );
                              },
                        child: const Text('去注册'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
