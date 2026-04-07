import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/wx_list_group.dart';
import 'package:hailiao_flutter/widgets/common/wx_list_item.dart';
import 'package:hailiao_flutter/widgets/common/wx_section_title.dart';
import 'package:hailiao_flutter/widgets/profile/profile_circle_avatar.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';
import 'package:provider/provider.dart';

/// 「我的」：灰底顶区 + 白底分组列表（微信式节奏）。
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  static const Color _iconWell = Color(0xFFF1F3F5);
  static const EdgeInsets _sectionTitlePadding = EdgeInsets.only(
    left: 4,
    right: 4,
    top: 4,
    bottom: 8,
  );

  static Color _statusColor(bool isOnline) {
    return isOnline ? const Color(0xFF07C160) : CommonTokens.textTertiary;
  }

  static String _statusText(UserDTO? user) {
    if (user == null) {
      return '状态未知';
    }
    if (user.showOnlineStatus == false) {
      return '在线状态已隐藏';
    }
    return (user.onlineStatus ?? 0) == 1 ? '在线' : '离线';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isOnline = (user?.onlineStatus ?? 0) == 1;

    return ColoredBox(
      color: CommonTokens.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ProfileCircleAvatar(
                  title: user == null
                      ? '?'
                      : ProfileDisplayTexts.displayName(user),
                  avatarRaw: user?.avatar,
                  size: 56,
                  fontSize: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user == null
                            ? ProfileDisplayTexts.unset
                            : ProfileDisplayTexts.displayName(user),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CommonTokens.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusColor(isOnline),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _statusText(user),
                              style: CommonTokens.bodySmall.copyWith(
                                color: CommonTokens.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WxSectionTitle(
            '账号与资料',
            padding: _sectionTitlePadding,
          ),
          WxListGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                WxListItem(
                  dense: true,
                  icon: Icons.person_outline_rounded,
                  iconWellColor: _iconWell,
                  title: '个人资料',
                  subtitle: '查看并编辑昵称、签名等',
                  onTap: user?.id == null
                      ? null
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/user-detail',
                            arguments: <String, dynamic>{
                              'userId': user!.id,
                              'user': user,
                            },
                          );
                        },
                ),
                WxListItem(
                  dense: true,
                  icon: Icons.privacy_tip_outlined,
                  iconWellColor: _iconWell,
                  title: '隐私设置',
                  subtitle: '在线状态、搜索与好友验证',
                  onTap: () =>
                      Navigator.pushNamed(context, '/privacy-settings'),
                ),
                WxListItem(
                  dense: true,
                  icon: Icons.security_outlined,
                  iconWellColor: _iconWell,
                  title: '账号与设备',
                  subtitle: '设备锁与登录记录',
                  showDivider: false,
                  onTap: () => Navigator.pushNamed(context, '/security'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          WxSectionTitle(
            '其他',
            padding: _sectionTitlePadding,
          ),
          WxListGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                WxListItem(
                  dense: true,
                  icon: Icons.flag_outlined,
                  iconWellColor: _iconWell,
                  title: '我的举报',
                  onTap: () => Navigator.pushNamed(context, '/report-list'),
                ),
                WxListItem(
                  dense: true,
                  icon: Icons.verified_outlined,
                  iconWellColor: _iconWell,
                  title: '内容审核',
                  subtitle: '你提交内容的审核状态',
                  showDivider: false,
                  onTap: () =>
                      Navigator.pushNamed(context, '/content-audit-list'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          WxSectionTitle(
            '协议',
            padding: _sectionTitlePadding,
          ),
          WxListGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                WxListItem(
                  dense: true,
                  icon: Icons.article_outlined,
                  iconWellColor: _iconWell,
                  title: '用户协议',
                  onTap: () =>
                      Navigator.pushNamed(context, '/user-agreement'),
                ),
                WxListItem(
                  dense: true,
                  icon: Icons.description_outlined,
                  iconWellColor: _iconWell,
                  title: '隐私政策',
                  showDivider: false,
                  onTap: () =>
                      Navigator.pushNamed(context, '/privacy-policy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await authProvider.logout();
                if (!context.mounted) {
                  return;
                }
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: UiTokens.outlinedSecondary(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                '退出登录',
                style: TextStyle(
                  color: UiTokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
