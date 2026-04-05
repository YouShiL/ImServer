import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/call_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/screens/call_screen.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/services/call_signal_bridge.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/profile_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_empty_state.dart';
import 'package:hailiao_flutter/widgets/common/app_list_item.dart';
import 'package:hailiao_flutter/widgets/common/app_primary_button.dart';
import 'package:hailiao_flutter/widgets/common/app_secondary_button.dart';
import 'package:hailiao_flutter/widgets/group/group_section_card.dart';
import 'package:hailiao_flutter/widgets/profile/profile_header_card.dart';
import 'package:provider/provider.dart';

abstract class UserDetailApi {
  Future<ResponseDTO<UserDTO>> getUserById(int userId);
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId);
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  });
}

class ApiUserDetailApi implements UserDetailApi {
  const ApiUserDetailApi();
  @override
  Future<ResponseDTO<UserDTO>> getUserById(int userId) =>
      ApiService.getUserById(userId);
  @override
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId) =>
      ApiService.getUserOnlineInfo(userId);
  @override
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) => ApiService.createReport(
        targetId,
        targetType,
        reason,
        evidence: evidence,
      );
}

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, UserDetailApi? api})
    : api = api ?? const ApiUserDetailApi();
  final UserDetailApi api;
  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _initialized = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _userId;
  UserDTO? _user;
  String? _error;
  String? _statusText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    context.read<BlacklistProvider>().loadBlacklist();
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) _userId = args;
    if (args is Map<String, dynamic>) {
      _userId = args['userId'] as int?;
      final Object? user = args['user'];
      if (user is UserDTO) _user = user;
    }
    _loadUserDetail();
  }

  Future<void> _loadUserDetail() async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
        _error = '缺少用户信息。';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await widget.api.getUserById(_userId!);
      if (!mounted) return;
      if (response.isSuccess && response.data != null) {
        _user = response.data;
        await _loadPresence(_userId!);
      } else {
        _error = response.message;
      }
    } catch (_) {
      if (mounted) _error = '加载用户资料失败，请稍后重试。';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPresence(int userId) async {
    try {
      final response = await widget.api.getUserOnlineInfo(userId);
      if (!mounted || !response.isSuccess || response.data == null) return;
      final Map<String, dynamic> data = response.data!;
      final bool isOnline = data['isOnline'] == true;
      final String? lastOnlineAt = data['lastOnlineAt']?.toString();
      setState(() {
        if (_user?.showOnlineStatus == false) {
          _statusText = '在线状态已隐藏';
        } else if (isOnline) {
          _statusText = '在线';
        } else if (_user?.showLastOnline == true &&
            lastOnlineAt != null &&
            lastOnlineAt.isNotEmpty &&
            lastOnlineAt != 'null') {
          _statusText = '最近在线：$lastOnlineAt';
        } else {
          _statusText = '离线';
        }
      });
    } catch (_) {}
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showComingSoon(String title) => _showSnack('$title 暂未开放');

  FriendDTO? _findFriend(FriendProvider provider, UserDTO user) {
    for (final FriendDTO friend in provider.friends) {
      if (friend.friendId == user.id) return friend;
    }
    return null;
  }

  String _displayName(UserDTO user, {FriendDTO? friend}) {
    final String remark = (friend?.remark ?? '').trim();
    final String nickname = (user.nickname ?? '').trim();
    final String userId = (user.userId ?? '').trim();
    if (remark.isNotEmpty) return remark;
    if (nickname.isNotEmpty) return nickname;
    if (userId.isNotEmpty) return userId;
    return '未设置昵称';
  }

  String _value(String? value, {String fallback = '未设置'}) {
    final String trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _genderLabel(int? gender) {
    if (gender == 1) return '男';
    if (gender == 2) return '女';
    return '未设置';
  }

  Widget _icon(IconData icon, {Color? color}) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ProfileUiTokens.actionSoftBackground,
          borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
          border: Border.all(color: ProfileUiTokens.actionSoftBorder),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: color ?? ProfileUiTokens.actionSoftIcon),
      );

  Future<void> _sendFriendRequest() async {
    if (_user?.id == null || _isSubmitting) return;
    final remarkController = TextEditingController(text: _user?.nickname ?? _user?.userId ?? '');
    final messageController = TextEditingController(text: '你好，我想加你为好友。');
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('添加好友'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: remarkController, decoration: const InputDecoration(labelText: '备注')),
            const SizedBox(height: CommonTokens.space12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '验证消息', alignLabelWithHint: true),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('发送申请')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    final provider = context.read<FriendProvider>();
    final bool success = await provider.addFriend(
      _user!.id!,
      remarkController.text.trim(),
      message: messageController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showSnack(success ? '好友申请已发送' : (provider.error ?? '发送好友申请失败'));
  }

  Future<void> _toggleBlacklist(bool blocked) async {
    if (_user?.id == null || _isSubmitting) return;
    final provider = context.read<BlacklistProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(blocked ? '解除黑名单' : '加入黑名单'),
        content: Text(blocked
            ? '解除后，你们可以重新搜索彼此并恢复联系。'
            : '加入后，你们将无法继续发送好友申请或进行正常联系。'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('确认')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    final bool success = blocked
        ? await provider.removeFromBlacklist(_user!.id!)
        : await provider.addToBlacklist(_user!.id!);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showSnack(success ? (blocked ? '已解除黑名单' : '已加入黑名单') : (provider.error ?? (blocked ? '解除黑名单失败' : '加入黑名单失败')));
  }

  Future<void> _reportUser() async {
    if (_user?.id == null || _isSubmitting) return;
    final List<String> reasons = <String>['骚扰或谩骂', '诈骗或虚假信息', '不当内容', '其他'];
    String selectedReason = reasons.first;
    final TextEditingController evidenceController = TextEditingController();
    String? error;
    bool isSubmitting = false;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          Future<void> submit() async {
            setDialogState(() {
              isSubmitting = true;
              error = null;
            });
            try {
              final response = await widget.api.createReport(
                _user!.id!,
                1,
                selectedReason,
                evidence: evidenceController.text.trim(),
              );
              if (!mounted) return;
              if (response.isSuccess) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                _showSnack('举报已提交');
              } else {
                setDialogState(() {
                  error = response.message;
                  isSubmitting = false;
                });
              }
            } catch (_) {
              setDialogState(() {
                error = '提交举报失败';
                isSubmitting = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('举报用户'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    decoration: const InputDecoration(labelText: '举报原因'),
                    items: reasons
                        .map((String reason) => DropdownMenuItem<String>(value: reason, child: Text(reason)))
                        .toList(),
                    onChanged: isSubmitting ? null : (String? value) {
                      if (value != null) setDialogState(() => selectedReason = value);
                    },
                  ),
                  const SizedBox(height: CommonTokens.space12),
                  TextField(
                    controller: evidenceController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '补充说明',
                      hintText: '可以简单描述问题背景',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: CommonTokens.space12),
                    Text(error!, style: const TextStyle(color: CommonTokens.danger, fontSize: 13)),
                  ],
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(), child: const Text('取消')),
              ElevatedButton(onPressed: isSubmitting ? null : submit, child: Text(isSubmitting ? '提交中...' : '提交举报')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateFriendRemark(FriendDTO friend) async {
    final TextEditingController controller = TextEditingController(text: friend.remark ?? friend.friendUserInfo?.nickname ?? '');
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('修改备注'),
        content: TextField(
          controller: controller,
          maxLength: 20,
          decoration: const InputDecoration(labelText: '备注名称', hintText: '请输入新的备注'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('保存')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    final provider = context.read<FriendProvider>();
    final bool success = await provider.updateFriendRemark(friend.friendId!, controller.text.trim());
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showSnack(success ? '备注已更新' : (provider.error ?? '备注更新失败'));
  }

  Future<void> _deleteFriend(FriendDTO friend) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除好友'),
        content: const Text('删除后，你们的联系人关系将被解除，后续需要重新发起好友申请。'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('确认删除')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    final provider = context.read<FriendProvider>();
    final bool success = await provider.deleteFriend(friend.friendId!);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      _showSnack('已删除好友');
      Navigator.pop(context);
      return;
    }
    _showSnack(provider.error ?? '删除好友失败');
  }

  void _openChat() {
    if (_user?.id == null) return;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: <String, dynamic>{'targetId': _user!.id, 'type': 1, 'title': _displayName(_user!, friend: null)},
    );
  }

  Future<void> _startCall(CallMediaType mediaType, {FriendDTO? friend}) async {
    final UserDTO? user = _user;
    if (user?.id == null) {
      return;
    }
    final CallSignalBridge bridge = CallSignalBridge.instance;
    final String name = _displayName(user!, friend: friend);
    final CallProvider provider = CallProvider(
      callType: mediaType,
      name: name,
      stage: CallStage.calling,
      avatarUrl: user.avatar,
      subtitle: _statusText,
      isMuted: false,
      isSpeakerOn: mediaType == CallMediaType.audio,
      isCameraEnabled: mediaType == CallMediaType.video,
      isFrontCamera: true,
    );
    bridge.onOutgoingStarted(provider);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CallScreen(
          name: name,
          mediaType: mediaType,
          stage: CallStage.calling,
          avatarUrl: user.avatar,
          subtitle: _statusText,
          provider: provider,
          disposeProvidedProvider: true,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool showDivider = true}) {
    return AppListItem(
      leading: _icon(icon),
      title: Text(label, style: ProfileUiTokens.infoValueText.copyWith(fontWeight: FontWeight.w600)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          value,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: ProfileUiTokens.infoLabelText.copyWith(color: CommonTokens.textSecondary),
        ),
      ),
      showDivider: showDivider,
      dividerIndent: 48,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FriendProvider friendProvider = context.watch<FriendProvider>();
    final BlacklistProvider blacklistProvider = context.watch<BlacklistProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ProfileUiTokens.pageBackground,
        appBar: AppBar(title: const Text('个人资料')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: ProfileUiTokens.pageBackground,
        appBar: AppBar(title: const Text('个人资料')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center, style: CommonTokens.body.copyWith(color: CommonTokens.textSecondary)),
          ),
        ),
      );
    }
    if (_user == null) {
      return Scaffold(
        backgroundColor: ProfileUiTokens.pageBackground,
        appBar: AppBar(title: const Text('个人资料')),
        body: const Center(
          child: AppEmptyState(
            icon: Icons.person_off_outlined,
            text: '暂无用户资料',
            detail: '稍后再试，或返回上一页重新进入。',
          ),
        ),
      );
    }

    final UserDTO user = _user!;
    final FriendDTO? currentFriend = _findFriend(friendProvider, user);
    final bool isBlocked = user.id != null && blacklistProvider.isBlocked(user.id!);
    final bool isSelf = authProvider.user?.id != null && authProvider.user!.id == user.id;
    final List<String> meta = <String>[
      if ((currentFriend?.remark ?? '').trim().isNotEmpty) '备注 ${currentFriend!.remark!.trim()}',
      if ((user.region ?? '').trim().isNotEmpty) user.region!.trim(),
      if ((user.prettyNumber ?? '').trim().isNotEmpty) '靓号 ${user.prettyNumber!.trim()}',
      if (user.isVip == true) 'VIP',
      if (user.needFriendVerification == true) '添加需验证',
    ];

    return Scaffold(
      backgroundColor: ProfileUiTokens.pageBackground,
      appBar: AppBar(title: const Text('个人资料')),
      body: RefreshIndicator(
        onRefresh: _loadUserDetail,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: CommonTokens.space16, vertical: CommonTokens.space16),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ProfileUiTokens.pageMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ProfileHeaderCard(
                      title: _displayName(user, friend: currentFriend),
                      subtitle: '账号 ${_value(user.userId, fallback: '-')}',
                      description: _value(user.signature, fallback: '这个人很低调，还没有留下个性签名。'),
                      statusText: _statusText,
                      meta: meta,
                    ),
                    const SizedBox(height: ProfileUiTokens.sectionSpacing),
                    GroupSectionCard(
                      title: isSelf ? '资料操作' : '聊天与关系',
                      subtitle: isSelf ? '管理当前账号的常用资料入口。' : '优先处理高频联系与关系管理操作。',
                      child: Column(
                        children: <Widget>[
                          if (isSelf) ...<Widget>[
                            AppPrimaryButton(label: '编辑资料', onPressed: () => _showComingSoon('编辑资料')),
                            const SizedBox(height: CommonTokens.sm),
                            AppSecondaryButton(
                              label: '隐私设置',
                              onPressed: () => _showComingSoon('隐私设置'),
                              leading: Icon(Icons.lock_outline_rounded, size: 18, color: CommonTokens.secondaryButtonText),
                            ),
                          ] else ...<Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: AppPrimaryButton(
                                    label: currentFriend != null ? '发消息' : '添加好友',
                                    onPressed: _isSubmitting ? null : (currentFriend != null ? _openChat : _sendFriendRequest),
                                    isLoading: _isSubmitting,
                                  ),
                                ),
                                const SizedBox(width: CommonTokens.sm),
                                Expanded(
                                  child: AppSecondaryButton(
                                    label: isBlocked ? '解除拉黑' : '加入黑名单',
                                    onPressed: _isSubmitting ? null : () => _toggleBlacklist(isBlocked),
                                    leading: Icon(
                                      isBlocked ? Icons.shield_outlined : Icons.block_outlined,
                                      size: 18,
                                      color: CommonTokens.secondaryButtonText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (currentFriend != null) ...<Widget>[
                              const SizedBox(height: CommonTokens.sm),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: AppSecondaryButton(
                                      label: '语音通话',
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _startCall(
                                                CallMediaType.audio,
                                                friend: currentFriend,
                                              ),
                                      leading: Icon(
                                        Icons.call_outlined,
                                        size: 18,
                                        color: CommonTokens.secondaryButtonText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: CommonTokens.sm),
                                  Expanded(
                                    child: AppSecondaryButton(
                                      label: '视频通话',
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _startCall(
                                                CallMediaType.video,
                                                friend: currentFriend,
                                              ),
                                      leading: Icon(
                                        Icons.videocam_outlined,
                                        size: 18,
                                        color: CommonTokens.secondaryButtonText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: CommonTokens.md),
                            AppListItem(
                              leading: _icon(Icons.push_pin_outlined),
                              title: const Text('置顶聊天'),
                              subtitle: const Text('后续可与会话页统一接入。'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _showComingSoon('置顶聊天'),
                              dividerIndent: 48,
                            ),
                            AppListItem(
                              leading: _icon(Icons.notifications_none_rounded),
                              title: const Text('消息免打扰'),
                              subtitle: const Text('减少不必要的打扰，保留重要联系。'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _showComingSoon('消息免打扰'),
                              dividerIndent: 48,
                            ),
                            if (currentFriend != null)
                              AppListItem(
                                leading: _icon(Icons.edit_note_rounded),
                                title: const Text('修改备注'),
                                subtitle: const Text('让联系人更容易识别。'),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: _isSubmitting ? null : () => _updateFriendRemark(currentFriend),
                                dividerIndent: 48,
                              ),
                            AppListItem(
                              leading: _icon(Icons.flag_outlined, color: ProfileUiTokens.dangerText),
                              title: const Text('举报用户'),
                              subtitle: const Text('发现违规行为时可提交说明。'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: _reportUser,
                              showDivider: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: ProfileUiTokens.sectionSpacing),
                    GroupSectionCard(
                      title: '基本资料',
                      subtitle: '展示当前用户已公开或建立关系后可见的信息。',
                      child: Column(
                        children: <Widget>[
                          _buildInfoRow('昵称', _value(user.nickname), Icons.badge_outlined),
                          _buildInfoRow('备注', _value(currentFriend?.remark), Icons.drive_file_rename_outline_rounded),
                          _buildInfoRow('性别', _genderLabel(user.gender), Icons.wc_rounded),
                          _buildInfoRow('地区', _value(user.region), Icons.location_on_outlined),
                          _buildInfoRow('个性签名', _value(user.signature), Icons.short_text_rounded),
                          _buildInfoRow(
                            '手机号',
                            user.allowSearchByPhone == false ? '未公开' : _value(user.phone, fallback: '未公开'),
                            Icons.phone_outlined,
                          ),
                          _buildInfoRow('最近登录', _value(user.lastLoginAt, fallback: '暂无记录'), Icons.schedule_rounded, showDivider: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: ProfileUiTokens.sectionSpacing),
                    GroupSectionCard(
                      title: '账号与更多',
                      subtitle: '围绕账号资料、隐私与后续扩展能力的轻量入口。',
                      child: Column(
                        children: <Widget>[
                          AppListItem(
                            leading: _icon(Icons.perm_identity_outlined),
                            title: const Text('账号信息'),
                            subtitle: Text('账号 ${_value(user.userId, fallback: '-')}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showComingSoon('账号信息'),
                            dividerIndent: 48,
                          ),
                          AppListItem(
                            leading: _icon(Icons.privacy_tip_outlined),
                            title: const Text('隐私相关'),
                            subtitle: const Text('查看资料可见范围与搜索限制。'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showComingSoon('隐私相关'),
                            dividerIndent: 48,
                          ),
                          AppListItem(
                            leading: _icon(Icons.history_toggle_off_rounded),
                            title: const Text('查找聊天记录'),
                            subtitle: const Text('后续可与聊天页搜索能力统一接入。'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showComingSoon('查找聊天记录'),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ProfileUiTokens.sectionSpacing),
                    GroupSectionCard(
                      title: '危险操作',
                      subtitle: isSelf ? '当前账号仅展示危险区样式，不提供自我删除类操作。' : '这些操作通常不可恢复，请确认后继续。',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isSelf ? '这里预留更高风险的账号与关系管理能力入口。' : '删除好友后，双方的联系人关系将被解除，后续需要重新发起好友申请。',
                            style: ProfileUiTokens.sectionSubtitleText,
                          ),
                          const SizedBox(height: CommonTokens.md),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isSelf || currentFriend == null || _isSubmitting ? null : () => _deleteFriend(currentFriend),
                              icon: const Icon(Icons.person_remove_alt_1_rounded),
                              label: Text(isSelf ? '当前暂无操作' : '删除好友'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: CommonTokens.space16, vertical: CommonTokens.space12),
                                side: const BorderSide(color: ProfileUiTokens.dangerBorder),
                                foregroundColor: ProfileUiTokens.dangerText,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CommonTokens.radiusMd)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
