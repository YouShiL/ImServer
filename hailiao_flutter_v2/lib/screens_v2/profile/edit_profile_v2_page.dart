import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

/// 当前登录用户资料编辑（昵称 / 签名 / 性别）；提交走 [AuthProvider.updateUserInfo]。
/// 头像仅展示与占位，不扩展上传链路。
class EditProfileV2Page extends StatefulWidget {
  const EditProfileV2Page({super.key});

  @override
  State<EditProfileV2Page> createState() => _EditProfileV2PageState();
}

class _EditProfileV2PageState extends State<EditProfileV2Page> {
  final TextEditingController _nickname = TextEditingController();
  final TextEditingController _signature = TextEditingController();
  int? _gender;
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nickname.dispose();
    _signature.dispose();
    super.dispose();
  }

  void _seedFromUser(UserDTO? user) {
    if (user == null || _seeded) {
      return;
    }
    _seeded = true;
    _nickname.text = (user.nickname ?? '').trim();
    _signature.text = (user.signature ?? '').trim();
    final int? g = user.gender;
    _gender = (g == 1 || g == 2) ? g : null;
  }

  String? _avatarUrl(UserDTO? u) {
    final String? raw = u?.avatar?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final String base = ApiService.baseUrl;
    if (base.endsWith('/')) {
      return '${base.substring(0, base.length - 1)}$raw';
    }
    return '$base$raw';
  }

  int _genderSubmit() {
    if (_gender == 1 || _gender == 2) {
      return _gender!;
    }
    return 0;
  }

  Future<void> _save() async {
    final String nick = _nickname.text.trim();
    if (nick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('昵称不能为空')),
      );
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    final UserDTO? before = auth.user;
    if (before == null) {
      return;
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'nickname': nick,
      'signature': _signature.text.trim(),
      'gender': _genderSubmit(),
    };

    setState(() {
      _saving = true;
    });
    final bool ok = await auth.updateUserInfo(body);
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final String msg = auth.error?.trim().isNotEmpty == true
          ? auth.error!.trim()
          : '保存失败';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final UserDTO? user = auth.user;
    _seedFromUser(user);

    return SecondaryPageScaffoldV2(
      title: '编辑资料',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _avatarUrl(user) != null
                      ? Image.network(
                          _avatarUrl(user)!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (BuildContext c, Object e, StackTrace? s) =>
                                  _avatarPlaceholder(),
                        )
                      : _avatarPlaceholder(),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('头像上传功能开发中')),
                    );
                  },
                  child: const Text('更换头像'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '昵称',
            style: ChatV2Tokens.headerSubtitle,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nickname,
            decoration: const InputDecoration(
              filled: true,
              fillColor: ChatV2Tokens.surface,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '个性签名',
            style: ChatV2Tokens.headerSubtitle,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _signature,
            maxLines: 3,
            decoration: const InputDecoration(
              filled: true,
              fillColor: ChatV2Tokens.surface,
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '性别',
            style: ChatV2Tokens.headerSubtitle,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ChatV2Tokens.surface,
              border: Border.all(color: ChatV2Tokens.divider),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _gender,
                isExpanded: true,
                items: const <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('保密'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 1,
                    child: Text('男'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 2,
                    child: Text('女'),
                  ),
                ],
                onChanged: (int? v) {
                  setState(() {
                    _gender = v;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving || user == null ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: ChatV2Tokens.accent,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 88,
      height: 88,
      color: ChatV2Tokens.surfaceSoft,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 48, color: ChatV2Tokens.textSecondary),
    );
  }
}
