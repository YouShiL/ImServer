import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';
import 'package:hailiao_flutter_v2/screens_v2/auth/auth_gate_v2.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/profile/profile_action_tile_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/profile/profile_section_v2.dart';
import 'package:provider/provider.dart';

/// 系统设置（账号摘要 + 占位项 + 退出登录）。
class SettingsV2Page extends StatelessWidget {
  const SettingsV2Page({super.key});

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

  String _displayName(UserDTO? user) {
    final String n = (user?.nickname ?? '').trim();
    if (n.isNotEmpty) {
      return n;
    }
    return '未设置昵称';
  }

  String _idLine(UserDTO? user, AuthProvider auth) {
    final String? uid = user?.userCode?.trim();
    if (uid != null && uid.isNotEmpty) {
      return '用户 ID: $uid';
    }
    if (auth.messagingUserId != null) {
      return '用户 ID: ${auth.messagingUserId}';
    }
    return '用户 ID: —';
  }

  String? _phoneLine(UserDTO? user) {
    final String? p = user?.phone?.trim();
    if (p == null || p.isEmpty) {
      return null;
    }
    return '手机: $p';
  }

  String _firstChar(String s) {
    final String t = s.trim();
    if (t.isEmpty) {
      return '?';
    }
    return t.substring(0, 1);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定退出当前账号？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) {
      return;
    }
    await context.read<AuthProvider>().logout();
    ApiConversationRepository.resetSessionState();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const AuthGateV2(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final UserDTO? user = auth.user;
    final String name = _displayName(user);
    final String? url = _avatarUrl(user);
    final String letter = _firstChar(name);

    return SecondaryPageScaffoldV2(
      title: '系统设置',
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ChatV2Tokens.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url != null
                          ? Image.network(
                              url,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                                  _avatarPlaceholder(letter),
                            )
                          : _avatarPlaceholder(letter),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ChatV2Tokens.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _idLine(user, auth),
                            style: ChatV2Tokens.headerSubtitle,
                          ),
                          if (_phoneLine(user) != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              _phoneLine(user)!,
                              style: ChatV2Tokens.headerSubtitle,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ProfileSectionV2(
            title: '通用',
            children: <Widget>[
              ProfileActionTileV2(
                title: '通知设置',
                subtitle: '消息提醒与提示音（占位）',
                leading: Icons.notifications_none,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('通知设置：开发中')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProfileSectionV2(
            title: '关于',
            children: <Widget>[
              ProfileActionTileV2(
                title: '关于应用',
                subtitle: '版本信息与说明（占位）',
                leading: Icons.info_outline,
                showDivider: false,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Hailiao Flutter V2',
                    applicationVersion: '0.1.0',
                    applicationLegalese: 'V2 展示层迁移壳',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ChatV2Tokens.surface,
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _confirmLogout(context),
                child: const Text('退出登录'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(String letter) {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFE5E5E5),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ChatV2Tokens.textSecondary,
        ),
      ),
    );
  }
}
