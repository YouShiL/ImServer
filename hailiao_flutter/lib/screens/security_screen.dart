import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/settings_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_empty_state.dart';
import 'package:hailiao_flutter/widgets/common/app_list_item.dart';
import 'package:hailiao_flutter/widgets/common/wx_list_group.dart';
import 'package:hailiao_flutter/widgets/common/wx_section_title.dart';
import 'package:provider/provider.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isUpdatingLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadSessions();
    });
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }
    final String normalized =
        value.replaceFirst('T', ' ').split('.').first.trim();
    if (normalized.length >= 19) {
      return normalized.substring(0, 19);
    }
    if (normalized.length == 16) {
      return '$normalized:00';
    }
    return normalized;
  }

  String _formatDeviceType(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'windows':
        return 'Windows';
      case 'macos':
        return 'macOS';
      case 'linux':
        return 'Linux';
      case 'web':
        return 'Web';
      default:
        return '未知设备';
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showComingSoon(String title) {
    _showSnack('$title 暂未开放');
  }

  Widget _settingIcon(IconData icon, {Color? color}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: SettingsUiTokens.settingIconBackground,
        borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 18,
        color: color ?? SettingsUiTokens.settingIconColor,
      ),
    );
  }

  Future<void> _toggleDeviceLock(bool value) async {
    setState(() {
      _isUpdatingLock = true;
    });

    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.updateUserInfo(<String, dynamic>{
      'deviceLock': value,
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingLock = false;
    });

    _showSnack(
      success
          ? (value ? '设备锁已开启' : '设备锁已关闭')
          : (authProvider.error ?? '设备锁更新失败'),
    );
  }

  Future<void> _terminateOtherSessions() async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.terminateOtherSessions();
    if (!mounted) {
      return;
    }
    _showSnack(success ? '其他设备已下线' : (authProvider.error ?? '操作失败'));
  }

  Future<void> _removeSession(UserSessionDTO session) async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.revokeSession(session.sessionId ?? '');

    if (!mounted) {
      return;
    }

    if (success && session.currentSession == true) {
      await authProvider.logout();
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    _showSnack(success ? '设备已下线' : (authProvider.error ?? '下线失败'));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _buildSessionMeta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CommonTokens.xxs),
      child: Text(
        '$label$value',
        style: SettingsUiTokens.metaTextStyle.copyWith(
          color: SettingsUiTokens.metaText,
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CommonTokens.space8,
        vertical: CommonTokens.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
      ),
      child: Text(
        label,
        style: CommonTokens.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSessionTile(UserSessionDTO session) {
    final bool isCurrent = session.currentSession == true;
    final bool isActive = session.active == true;
    final Color chipBackground = isCurrent
        ? SettingsUiTokens.successBackground
        : (isActive
            ? SettingsUiTokens.infoChipBackground
            : SettingsUiTokens.warningBackground);
    final Color chipText = isCurrent
        ? SettingsUiTokens.successText
        : (isActive
            ? CommonTokens.brandBlue
            : SettingsUiTokens.warningText);

    return AppListItem(
      leading: _settingIcon(Icons.devices_other_rounded),
      title: Text(
        session.deviceName ?? '未知设备',
        style: CommonTokens.body.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: CommonTokens.xs,
            runSpacing: CommonTokens.xs,
            children: <Widget>[
              _buildStatusChip(
                label: isCurrent ? '当前设备' : (isActive ? '在线' : '已下线'),
                backgroundColor: chipBackground,
                textColor: chipText,
              ),
              _buildStatusChip(
                label: _formatDeviceType(session.deviceType),
                backgroundColor: SettingsUiTokens.infoChipBackground,
                textColor: SettingsUiTokens.infoChipText,
              ),
            ],
          ),
          const SizedBox(height: CommonTokens.xs),
          _buildSessionMeta('登录 IP：', session.loginIp ?? '-'),
          _buildSessionMeta('最近活跃：', _formatTime(session.lastActiveAt)),
          _buildSessionMeta('登录时间：', _formatTime(session.createdAt)),
        ],
      ),
      trailing: isActive
          ? TextButton(
              onPressed: session.sessionId == null
                  ? null
                  : () => _removeSession(session),
              child: Text(isCurrent ? '退出登录' : '下线'),
            )
          : null,
      dividerIndent: 48,
      showDivider: true,
    );
  }

  Widget _buildAccountSection(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const WxSectionTitle(
          '账号与安全',
          subtitle: '管理账号信息、设备保护和登录安全。',
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
        ),
        WxListGroup(
          child: Column(
            children: <Widget>[
          AppListItem(
            leading: _settingIcon(Icons.person_outline_rounded),
            title: const Text('账号信息'),
            subtitle: Text(authProvider.user?.userId ?? '-'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('账号信息'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.lock_outline_rounded),
            title: const Text('密码与安全'),
            subtitle: const Text('管理密码、登录保护和账号安全提醒。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('密码与安全'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.phonelink_lock_outlined),
            title: const Text('设备锁'),
            subtitle: const Text('开启后，新设备登录需要额外确认。'),
            trailing: Switch(
              value: authProvider.user?.deviceLock ?? false,
              onChanged: _isUpdatingLock ? null : _toggleDeviceLock,
            ),
            showDivider: false,
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const WxSectionTitle(
          '消息通知',
          subtitle: '调整提醒方式与通知展示形式。',
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
        ),
        WxListGroup(
          child: Column(
            children: <Widget>[
          AppListItem(
            leading: _settingIcon(Icons.notifications_active_outlined),
            title: const Text('新消息通知'),
            subtitle: const Text('控制系统通知、提醒角标和横幅展示。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('新消息通知'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.volume_up_outlined),
            title: const Text('声音与震动'),
            subtitle: const Text('根据设备场景调整声音和震动反馈。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('声音与震动'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.visibility_outlined),
            title: const Text('预览显示'),
            subtitle: const Text('设置通知预览、锁屏展示和提醒内容。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('预览显示'),
            showDivider: false,
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const WxSectionTitle(
          '隐私',
          subtitle: '管理联系人、黑名单与可见范围。',
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
        ),
        WxListGroup(
          child: Column(
            children: <Widget>[
          AppListItem(
            leading: _settingIcon(Icons.block_outlined),
            title: const Text('黑名单'),
            subtitle: const Text('查看和管理已屏蔽的联系人。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('黑名单'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.person_add_alt_rounded),
            title: const Text('加好友方式'),
            subtitle: const Text('调整搜索方式和好友验证策略。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('加好友方式'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.shield_outlined),
            title: const Text('安全与举报'),
            subtitle: const Text('查看安全说明与问题反馈入口。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('安全与举报'),
            showDivider: false,
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const WxSectionTitle(
          '通用',
          subtitle: '围绕聊天体验、显示效果和本地存储的常用设置。',
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
        ),
        WxListGroup(
          child: Column(
            children: <Widget>[
          AppListItem(
            leading: _settingIcon(Icons.wallpaper_outlined),
            title: const Text('聊天背景'),
            subtitle: const Text('为会话设置统一或个性化背景。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('聊天背景'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.storage_outlined),
            title: const Text('存储与缓存'),
            subtitle: const Text('查看缓存占用并管理本地数据。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('存储与缓存'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.language_outlined),
            title: const Text('显示与语言'),
            subtitle: const Text('调整语言、字体与显示偏好。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('显示与语言'),
            showDivider: false,
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const WxSectionTitle(
          '关于与帮助',
          subtitle: '查看版本信息、获取帮助和提交反馈。',
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
        ),
        WxListGroup(
          child: Column(
            children: <Widget>[
          AppListItem(
            leading: _settingIcon(Icons.info_outline_rounded),
            title: const Text('关于嗨聊'),
            subtitle: const Text('了解产品定位和当前版本信息。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('关于嗨聊'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.feedback_outlined),
            title: const Text('意见反馈'),
            subtitle: const Text('提交建议、问题反馈或体验感受。'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('意见反馈'),
            dividerIndent: 48,
          ),
          AppListItem(
            leading: _settingIcon(Icons.help_outline_rounded),
            title: const Text('帮助中心'),
            subtitle: Text('最近更新：${authProvider.user?.updatedAt ?? '1.0.0'}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showComingSoon('帮助中心'),
            showDivider: false,
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsSection(AuthProvider authProvider) {
    final bool hasOtherActiveSessions = authProvider.sessions.any(
      (UserSessionDTO session) =>
          session.active == true && session.currentSession != true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        WxSectionTitle(
          '登录设备',
          subtitle: '查看当前账号在不同设备上的登录状态与最近活动。',
          trailing: TextButton(
            onPressed: hasOtherActiveSessions ? _terminateOtherSessions : null,
            child: const Text('下线其他设备'),
          ),
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
        ),
        WxListGroup(
          child: authProvider.sessions.isEmpty
              ? const AppEmptyState(
                  icon: Icons.devices_other_outlined,
                  text: '暂无登录设备',
                  detail: '新的登录设备会显示在这里，你可以随时查看并管理。',
                )
              : Column(
                  children: authProvider.sessions
                      .map((UserSessionDTO session) => _buildSessionTile(session))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildDangerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const WxSectionTitle(
          '危险操作',
          subtitle: '这些操作会影响当前账号状态或本地数据，请确认后继续。',
          padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
        ),
        WxListGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '退出登录后需要重新验证账号。清理缓存等更多能力会在后续版本逐步补充。',
                style: SettingsUiTokens.sectionSubtitleText,
              ),
              const SizedBox(height: CommonTokens.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showComingSoon('清理缓存'),
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('清理缓存'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CommonTokens.space16,
                      vertical: CommonTokens.space12,
                    ),
                    side: const BorderSide(color: SettingsUiTokens.dangerBorder),
                    foregroundColor: SettingsUiTokens.dangerText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CommonTokens.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('退出登录'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CommonTokens.danger,
                    foregroundColor: CommonTokens.textOnBrand,
                    padding: const EdgeInsets.symmetric(
                      horizontal: CommonTokens.space16,
                      vertical: CommonTokens.space12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: CommonTokens.bgPrimary,
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: CommonTokens.bgPrimary,
        foregroundColor: CommonTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: authProvider.loadSessions,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: CommonTokens.space16,
            vertical: CommonTokens.space16,
          ),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SettingsUiTokens.pageMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildAccountSection(authProvider),
                    const SizedBox(height: SettingsUiTokens.sectionSpacing),
                    _buildNotificationSection(),
                    const SizedBox(height: SettingsUiTokens.sectionSpacing),
                    _buildPrivacySection(),
                    const SizedBox(height: SettingsUiTokens.sectionSpacing),
                    _buildGeneralSection(),
                    const SizedBox(height: SettingsUiTokens.sectionSpacing),
                    _buildAboutSection(authProvider),
                    const SizedBox(height: SettingsUiTokens.sectionSpacing),
                    _buildSessionsSection(authProvider),
                    const SizedBox(height: SettingsUiTokens.sectionSpacing),
                    _buildDangerSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
