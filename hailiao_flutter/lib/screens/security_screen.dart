import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
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
    final normalized = value.replaceFirst('T', ' ').split('.').first;
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
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
        return '未知';
    }
  }

  Future<void> _toggleDeviceLock(bool value) async {
    setState(() {
      _isUpdatingLock = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserInfo({'deviceLock': value});

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingLock = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (value ? '设备锁已开启' : '设备锁已关闭')
              : (authProvider.error ?? '设备锁更新失败'),
        ),
      ),
    );
  }

  Future<void> _terminateOtherSessions() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.terminateOtherSessions();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '其他设备已下线' : (authProvider.error ?? '操作失败')),
      ),
    );
  }

  Future<void> _removeSession(UserSessionDTO session) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.revokeSession(session.sessionId ?? '');

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '设备已下线' : (authProvider.error ?? '下线失败')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label$value',
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSessionCard(UserSessionDTO session) {
    final isCurrent = session.currentSession == true;
    final isActive = session.active == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.deviceName ?? '未知\u8bbe\u5907',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFFDBEAFE)
                    : (isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isCurrent ? '当前设备' : (isActive ? '在线' : '已下线'),
                style: TextStyle(
                  color: isCurrent
                      ? const Color(0xFF2563EB)
                      : (isActive ? const Color(0xFF15803D) : const Color(0xFF6B7280)),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('设备类型：', _formatDeviceType(session.deviceType)),
              _buildInfoRow('登录 IP：', session.loginIp ?? '-'),
              _buildInfoRow('最近活动：', _formatTime(session.lastActiveAt)),
              _buildInfoRow('登录时间：', _formatTime(session.createdAt)),
            ],
          ),
        ),
        trailing: isActive
            ? TextButton(
                onPressed: session.sessionId == null
                    ? null
                    : () => _removeSession(session),
                child: Text(isCurrent ? '退出' : '下线'),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final deviceLock = authProvider.user?.deviceLock ?? false;
    final hasOtherActiveSessions = authProvider.sessions.any(
      (session) => session.active == true && session.currentSession != true,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('账户与设备')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('设备锁'),
                  subtitle: const Text('开启后，新设备登录会被拦截。'),
                  value: deviceLock,
                  onChanged: _isUpdatingLock ? null : _toggleDeviceLock,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: const Text('上次登录 IP'),
                  subtitle: Text(authProvider.user?.lastLoginIp ?? '-'),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('上次登录时间'),
                  subtitle: Text(_formatTime(authProvider.user?.lastLoginAt)),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: hasOtherActiveSessions
                      ? _terminateOtherSessions
                      : null,
                  child: const Text('下线其他设备'),
                ),
                if (!hasOtherActiveSessions)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '当前没有其他在线设备',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '登录设备',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          if (authProvider.sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '暂无设备记录',
                style: TextStyle(color: Color(0xFF666666)),
              ),
            )
          else
            ...authProvider.sessions.map(_buildSessionCard),
        ],
      ),
    );
  }
}

