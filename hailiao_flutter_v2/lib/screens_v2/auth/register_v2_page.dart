import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:provider/provider.dart';

class RegisterV2Page extends StatefulWidget {
  const RegisterV2Page({super.key});

  @override
  State<RegisterV2Page> createState() => _RegisterV2PageState();
}

class _RegisterV2PageState extends State<RegisterV2Page> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreedToTerms = true;

  bool get _canSubmit {
    return _nicknameController.text.trim().length >= 2 &&
        _phoneController.text.trim().length == 11 &&
        _passwordController.text.length >= 6 &&
        _agreedToTerms;
  }

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_refresh);
    _phoneController.addListener(_refresh);
    _passwordController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_refresh);
    _phoneController.removeListener(_refresh);
    _passwordController.removeListener(_refresh);
    _nicknameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('请先同意相关协议')));
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.register(
      _phoneController.text.trim(),
      _passwordController.text,
      _nicknameController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('注册成功')));
      Navigator.of(context).pop();
      return;
    }

    final String message = authProvider.error ?? '注册失败，请稍后重试';
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: ChatV2Tokens.pageBackground,
      appBar: AppBar(
        title: const Text('注册'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? value) {
                        final String nickname = (value ?? '').trim();
                        if (nickname.isEmpty) {
                          return '请输入昵称';
                        }
                        if (nickname.length < 2) {
                          return '昵称至少 2 个字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _agreedToTerms,
                      onChanged: authProvider.isLoading
                          ? null
                          : (bool? value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                      title: const Text(
                        '我已阅读并同意用户协议与隐私政策',
                        style: TextStyle(fontSize: 13),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: authProvider.isLoading || !_canSubmit
                          ? null
                          : _handleRegister,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('注册'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
