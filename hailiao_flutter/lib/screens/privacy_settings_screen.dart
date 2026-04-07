import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/common/wx_list_group.dart';
import 'package:hailiao_flutter/widgets/common/wx_section_title.dart';
import 'package:provider/provider.dart';

/// 承接原「我的」页中的隐私相关开关，不包含其他业务入口。
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  Future<void> _updatePrivacySetting(
    BuildContext context,
    String key,
    bool value, {
    required String successMessage,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserInfo({key: value});

    if (!context.mounted) {
      return;
    }

    final message = success
        ? successMessage
        : (authProvider.error ?? '设置更新失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final showOnlineStatus = authProvider.user?.showOnlineStatus ?? true;
    final showLastOnline = authProvider.user?.showLastOnline ?? true;
    final allowSearchByPhone = authProvider.user?.allowSearchByPhone ?? true;
    final needFriendVerification =
        authProvider.user?.needFriendVerification ?? true;

    return Scaffold(
      backgroundColor: CommonTokens.bgPrimary,
      appBar: AppBar(
        title: const Text('隐私设置'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: CommonTokens.bgPrimary,
        foregroundColor: CommonTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          WxSectionTitle(
            '可见范围与添加方式',
            padding: const EdgeInsets.only(left: 4, bottom: 8),
          ),
          WxListGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SwitchListTile(
                  title: const Text('显示在线状态'),
                  subtitle: const Text('其他用户可以看到你是否在线'),
                  value: showOnlineStatus,
                  onChanged: (bool value) => _updatePrivacySetting(
                    context,
                    'showOnlineStatus',
                    value,
                    successMessage: '在线状态显示设置已更新',
                  ),
                ),
                Divider(height: 1, thickness: 1, color: CommonTokens.lineSubtle),
                SwitchListTile(
                  title: const Text('显示最后在线时间'),
                  subtitle: const Text('其他用户可以看到你的最后在线时间'),
                  value: showLastOnline,
                  onChanged: (bool value) => _updatePrivacySetting(
                    context,
                    'showLastOnline',
                    value,
                    successMessage: '最后在线时间显示设置已更新',
                  ),
                ),
                Divider(height: 1, thickness: 1, color: CommonTokens.lineSubtle),
                SwitchListTile(
                  title: const Text('允许手机号搜索'),
                  subtitle: const Text('其他用户可以通过手机号搜索到你'),
                  value: allowSearchByPhone,
                  onChanged: (bool value) => _updatePrivacySetting(
                    context,
                    'allowSearchByPhone',
                    value,
                    successMessage: '手机号搜索设置已更新',
                  ),
                ),
                Divider(height: 1, thickness: 1, color: CommonTokens.lineSubtle),
                SwitchListTile(
                  title: const Text('添加好友需要验证'),
                  subtitle: const Text('关闭后，对方可直接成为你的好友'),
                  value: needFriendVerification,
                  onChanged: (bool value) => _updatePrivacySetting(
                    context,
                    'needFriendVerification',
                    value,
                    successMessage: '好友验证设置已更新',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
