import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter_v2/screens_v2/profile/edit_profile_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/profile/settings_v2_page.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/primary_page_scaffold_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/profile/profile_action_tile_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/profile/profile_header_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/profile/profile_section_v2.dart';
import 'package:provider/provider.dart';

class ProfileV2Page extends StatelessWidget {
  const ProfileV2Page({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final UserDTO? user = auth.user;
    final String displayName =
        user?.nickname?.trim().isNotEmpty == true ? user!.nickname!.trim() : '未登录用户';
    final String accountId = user?.userCode?.trim().isNotEmpty == true
        ? 'ID: ${user!.userCode!.trim()}'
        : auth.messagingUserId != null
            ? 'ID: ${auth.messagingUserId}'
            : 'ID: 暂无账号信息';

    return PrimaryPageScaffoldV2(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0),
        children: <Widget>[
          ProfileHeaderV2(
            displayName: displayName,
            subtitle: accountId,
          ),
          const SizedBox(height: 12),
          ProfileSectionV2(
            title: '账号',
            children: <Widget>[
              ProfileActionTileV2(
                title: '个人信息',
                subtitle: user?.phone?.trim().isNotEmpty == true
                    ? '手机号 ${user!.phone!.trim()}'
                    : '昵称、签名与性别',
                leading: Icons.badge_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditProfileV2Page(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProfileSectionV2(
            title: '更多',
            children: <Widget>[
              ProfileActionTileV2(
                title: '系统设置',
                subtitle: '通知、隐私与主题设置',
                leading: Icons.settings_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsV2Page(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ProfileActionTileV2(
                title: '关于',
                subtitle: '应用信息与版本说明占位',
                leading: Icons.info_outline,
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
        ],
      ),
    );
  }
}
