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
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/theme/empty_state_ux_strings.dart';
import 'package:hailiao_flutter/theme/feedback_ux_strings.dart';
import 'package:hailiao_flutter/theme/profile_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/app_empty_state.dart';
import 'package:hailiao_flutter/widgets/common/im_dialog.dart';
import 'package:hailiao_flutter/widgets/common/wx_list_group.dart';
import 'package:hailiao_flutter/widgets/common/wx_list_item.dart';
import 'package:hailiao_flutter/widgets/common/wx_section_title.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';
import 'package:hailiao_flutter/widgets/common/badge_tag.dart';
import 'package:hailiao_flutter/widgets/profile/profile_circle_avatar.dart';
import 'package:hailiao_flutter/widgets/chat/open_chat_history_search.dart';
import 'package:hailiao_flutter/widgets/shell/im_template_shell.dart';
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
  /// 正在请求 [getUserById]；有路由快照时不阻塞整页，仅用于顶栏轻量进度。
  bool _isFetchingDetail = false;
  bool _isSubmitting = false;
  int? _userId;
  UserDTO? _user;
  String? _error;
  /// 已有快照时接口失败不清空 [_user]，在此展示提示。
  String? _refreshFailedMessage;
  String? _statusText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) _userId = args;
    if (args is Map<String, dynamic>) {
      _userId = args['userId'] as int?;
      final Object? user = args['user'];
      if (user is UserDTO) _user = user;
    }

    if (_userId != null && _user == null) {
      _isFetchingDetail = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BlacklistProvider>().loadBlacklist();
    });

    _loadUserDetail();
  }

  Future<void> _loadUserDetail() async {
    if (_userId == null) {
      setState(() {
        _isFetchingDetail = false;
        _error = EmptyStateUxStrings.userTargetMissingMessage;
      });
      return;
    }
    final bool hadRenderableUser = _user != null;
    setState(() {
      _isFetchingDetail = true;
      if (!hadRenderableUser) {
        _error = null;
      }
      _refreshFailedMessage = null;
    });
    try {
      final response = await widget.api.getUserById(_userId!);
      if (!mounted) return;
      if (response.isSuccess && response.data != null) {
        setState(() {
          _user = response.data;
          _error = null;
          _refreshFailedMessage = null;
        });
        await _loadPresence(_userId!);
      } else {
        if (hadRenderableUser) {
          final String msg = response.message.trim();
          setState(() {
            _refreshFailedMessage =
                msg.isEmpty ? '资料刷新失败，请下拉重试' : msg;
          });
        } else {
          setState(() => _error = response.message);
        }
      }
    } catch (_) {
      if (!mounted) return;
      if (hadRenderableUser) {
        setState(() {
          _refreshFailedMessage = '加载用户资料失败，请稍后重试。';
        });
      } else {
        setState(() => _error = '加载用户资料失败，请稍后重试。');
      }
    } finally {
      if (mounted) setState(() => _isFetchingDetail = false);
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

  Future<void> _sendFriendRequest() async {
    if (_user?.id == null || _isSubmitting) return;
    final remarkController = TextEditingController(text: _user?.nickname ?? _user?.userId ?? '');
    final messageController = TextEditingController(text: '你好，我想加你为好友。');
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: ImTemplateShell.dialogShape,
        insetPadding: ImTemplateShell.dialogInsetPadding,
        title: const ImDialogTitle('添加好友'),
        titlePadding: ImTemplateShell.dialogTitlePadding,
        contentPadding: ImTemplateShell.dialogContentPadding,
        actionsPadding: ImTemplateShell.dialogActionsPadding,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: remarkController,
              decoration:
                  ImTemplateShell.dialogFieldDecoration(label: '备注'),
            ),
            const SizedBox(height: ImTemplateShell.elementGapMd),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: ImTemplateShell.dialogFieldDecoration(
                label: '验证消息',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(FeedbackUxStrings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(FeedbackUxStrings.buttonSendRequest),
          ),
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
    _showSnack(
      success
          ? FeedbackUxStrings.snackFriendRequestSent
          : FeedbackUxStrings.messageOrFallback(
              provider.error,
              FeedbackUxStrings.fallbackSendFriendRequestFailed,
            ),
    );
  }

  Future<void> _toggleBlacklist(bool blocked) async {
    if (_user?.id == null || _isSubmitting) return;
    final provider = context.read<BlacklistProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: ImTemplateShell.dialogShape,
        insetPadding: ImTemplateShell.dialogInsetPadding,
        title: ImDialogTitle(
          blocked
              ? FeedbackUxStrings.dialogTitleRemoveBlacklist
              : FeedbackUxStrings.dialogTitleAddBlacklist,
        ),
        titlePadding: ImTemplateShell.dialogTitlePadding,
        contentPadding: ImTemplateShell.dialogContentPadding,
        actionsPadding: ImTemplateShell.dialogActionsPadding,
        content: Text(blocked
            ? '解除后，你们可以重新搜索彼此并恢复联系。'
            : '加入后，你们将无法继续发送好友申请或进行正常联系。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(FeedbackUxStrings.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: blocked ? null : CommonTokens.danger,
              foregroundColor: blocked ? null : Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              blocked
                  ? FeedbackUxStrings.dialogActionRemoveBlacklist
                  : FeedbackUxStrings.dialogActionAddBlacklist,
            ),
          ),
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
    _showSnack(
      success
          ? (blocked
              ? FeedbackUxStrings.snackUnblocked
              : FeedbackUxStrings.snackBlocked)
          : FeedbackUxStrings.messageOrFallback(
              provider.error,
              FeedbackUxStrings.fallbackOperationFailed,
            ),
    );
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
                  error = FeedbackUxStrings.messageOrFallback(
                    response.message,
                    FeedbackUxStrings.fallbackOperationFailed,
                  );
                  isSubmitting = false;
                });
              }
            } catch (_) {
              setDialogState(() {
                error = FeedbackUxStrings.fallbackOperationFailed;
                isSubmitting = false;
              });
            }
          }

          return AlertDialog(
            shape: ImTemplateShell.dialogShape,
            insetPadding: ImTemplateShell.dialogInsetPadding,
            title: const ImDialogTitle('举报用户'),
            titlePadding: ImTemplateShell.dialogTitlePadding,
            contentPadding: ImTemplateShell.dialogContentPadding,
            actionsPadding: ImTemplateShell.dialogActionsPadding,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    decoration: ImTemplateShell.dialogFieldDecoration(
                      label: '举报原因',
                    ),
                    items: reasons
                        .map((String reason) => DropdownMenuItem<String>(value: reason, child: Text(reason)))
                        .toList(),
                    onChanged: isSubmitting ? null : (String? value) {
                      if (value != null) setDialogState(() => selectedReason = value);
                    },
                  ),
                  const SizedBox(height: ImTemplateShell.elementGapMd),
                  TextField(
                    controller: evidenceController,
                    maxLines: 4,
                    decoration: ImTemplateShell.dialogFieldDecoration(
                      label: '补充说明',
                      hint: '可以简单描述问题背景',
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
              TextButton(
            onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text(FeedbackUxStrings.actionCancel),
          ),
              FilledButton(
                onPressed: isSubmitting ? null : submit,
                child: Text(
                  isSubmitting
                      ? FeedbackUxStrings.buttonSubmittingInProgress
                      : '提交举报',
                ),
              ),
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
        shape: ImTemplateShell.dialogShape,
        insetPadding: ImTemplateShell.dialogInsetPadding,
        title: const ImDialogTitle('修改备注'),
        titlePadding: ImTemplateShell.dialogTitlePadding,
        contentPadding: ImTemplateShell.dialogContentPadding,
        actionsPadding: ImTemplateShell.dialogActionsPadding,
        content: TextField(
          controller: controller,
          maxLength: 20,
          decoration: ImTemplateShell.dialogFieldDecoration(
            label: '备注名称',
            hint: '请输入新的备注',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(FeedbackUxStrings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(FeedbackUxStrings.buttonSave),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    final provider = context.read<FriendProvider>();
    final bool success = await provider.updateFriendRemark(friend.friendId!, controller.text.trim());
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showSnack(
      success
          ? '备注已更新'
          : FeedbackUxStrings.messageOrFallback(
              provider.error,
              FeedbackUxStrings.fallbackOperationFailed,
            ),
    );
  }

  Future<void> _deleteFriend(FriendDTO friend) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => ImDialog(
        title: FeedbackUxStrings.dialogTitleDeleteFriend,
        message: '删除后，你们的联系人关系将被解除，后续需要重新发起好友申请。',
        cancelLabel: FeedbackUxStrings.actionCancel,
        confirmLabel: FeedbackUxStrings.dialogActionDeleteFriend,
        destructive: true,
        onCancel: () => Navigator.of(context).pop(false),
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    final provider = context.read<FriendProvider>();
    final bool success = await provider.deleteFriend(friend.friendId!);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      _showSnack(FeedbackUxStrings.snackDeletedFriend);
      Navigator.pop(context);
      return;
    }
    _showSnack(
      FeedbackUxStrings.messageOrFallback(
        provider.error,
        FeedbackUxStrings.fallbackDeleteFriendFailed,
      ),
    );
  }

  void _openChat() {
    if (_user?.id == null) return;
    FriendDTO? asFriend;
    for (final FriendDTO f in context.read<FriendProvider>().friends) {
      if (f.friendId == _user!.id) {
        asFriend = f;
        break;
      }
    }
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: <String, dynamic>{
        'targetId': _user!.id,
        'type': 1,
        'title': ProfileDisplayTexts.singleChatDisplayTitle(
          peer: _user!,
          friendRemark: asFriend?.remark,
          nameFallback: null,
        ),
      },
    );
  }

  Future<void> _startCall(CallMediaType mediaType, {FriendDTO? friend}) async {
    final UserDTO? user = _user;
    if (user?.id == null) {
      return;
    }
    final CallSignalBridge bridge = CallSignalBridge.instance;
    final String name =
        ProfileDisplayTexts.displayName(user!, friendRemark: friend?.remark);
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

  Widget _buildWxProfileTop(
    UserDTO user,
    FriendDTO? currentFriend,
    List<String> meta,
  ) {
    final String displayName = ProfileDisplayTexts.singleChatDisplayTitle(
      peer: user,
      friendRemark: currentFriend?.remark,
      nameFallback: null,
    );
    final String sig = ProfileDisplayTexts.fieldValue(user.signature);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProfileCircleAvatar(
            title: displayName,
            avatarRaw: user.avatar,
            size: 64,
            fontSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '账号 ${ProfileDisplayTexts.accountIdLine(user.userId)}',
                  style: CommonTokens.bodySmall.copyWith(
                    color: CommonTokens.textTertiary,
                  ),
                ),
                if ((_statusText ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: (_statusText ?? '').startsWith('在线')
                              ? CommonTokens.success
                              : CommonTokens.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _statusText!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CommonTokens.bodySmall.copyWith(
                            color: CommonTokens.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (sig.isNotEmpty && sig != '-') ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    sig,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CommonTokens.bodySmall.copyWith(
                      color: CommonTokens.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: meta
                        .map(
                          (String item) => BadgeTag(
                            label: item,
                            backgroundColor:
                                ProfileUiTokens.heroMetaChipBackground,
                            textColor: ProfileUiTokens.heroMetaChipText,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: ImDesignTokens.heightItem,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ImDesignTokens.spaceLg,
            ),
            child: Row(
              children: <Widget>[
                WxListItem.circleIcon(icon),
                SizedBox(width: ImDesignTokens.spaceMd),
                Expanded(
                  child: Text(
                    label,
                    style: ProfileUiTokens.infoLabelText.copyWith(
                      color: ImDesignTokens.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    style: ProfileUiTokens.infoValueText.copyWith(
                      color: ImDesignTokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: ImDesignTokens.border,
            indent: WxListItem.defaultDividerIndent,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final FriendProvider friendProvider = context.watch<FriendProvider>();
    final BlacklistProvider blacklistProvider = context.watch<BlacklistProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();
    if (_error != null && _user == null) {
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
    if (_user == null && _isFetchingDetail) {
      return Scaffold(
        backgroundColor: ProfileUiTokens.pageBackground,
        appBar: AppBar(title: const Text('个人资料')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_user == null) {
      return Scaffold(
        backgroundColor: ProfileUiTokens.pageBackground,
        appBar: AppBar(title: const Text('个人资料')),
        body: const Center(
          child: AppEmptyState(
            icon: Icons.person_off_outlined,
            text: EmptyStateUxStrings.userProfileNotLoadedTitle,
            detail: EmptyStateUxStrings.userProfileNotLoadedDetail,
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
      backgroundColor: UiTokens.backgroundGray,
      appBar: AppBar(
        title: const Text('个人资料'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: UiTokens.backgroundGray,
        foregroundColor: UiTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: _isFetchingDetail
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserDetail,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: ImTemplateShell.pagePaddingH,
            vertical: ImTemplateShell.pagePaddingV,
          ),
          children: <Widget>[
            if ((_refreshFailedMessage ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: CommonTokens.space12),
                child: Material(
                  color: CommonTokens.softSurface,
                  borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CommonTokens.space12,
                      vertical: CommonTokens.space12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 20,
                          color: CommonTokens.textSecondary,
                        ),
                        const SizedBox(width: CommonTokens.space8),
                        Expanded(
                          child: Text(
                            _refreshFailedMessage!.trim(),
                            style: CommonTokens.bodySmall.copyWith(
                              color: CommonTokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ProfileUiTokens.pageMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    WxListGroup(
                      child: _buildWxProfileTop(user, currentFriend, meta),
                    ),
                    WxSectionTitle(
                      isSelf ? '资料操作' : '聊天与关系',
                      subtitle: isSelf ? '个人信息与常用入口' : null,
                    ),
                    if (isSelf)
                      WxListGroup(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            WxListItem(
                              icon: Icons.edit_outlined,
                              title: '编辑资料',
                              onTap: () {
                                Navigator.pushNamed(context, '/edit-profile').then((_) {
                                  if (mounted) {
                                    _loadUserDetail();
                                  }
                                });
                              },
                            ),
                            WxListItem(
                              icon: Icons.lock_outline_rounded,
                              title: '隐私设置',
                              showDivider: false,
                              onTap: () {
                                Navigator.pushNamed(context, '/privacy-settings').then((_) {
                                  if (mounted) {
                                    _loadUserDetail();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else ...<Widget>[
                      WxListGroup(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (isBlocked) ...<Widget>[
                              WxListItem(
                                icon: Icons.block_outlined,
                                title: '解除拉黑',
                                onTap: _isSubmitting
                                    ? null
                                    : () => _toggleBlacklist(true),
                              ),
                              WxListItem(
                                icon: Icons.chat_bubble_outline,
                                title: '发送消息',
                                showDivider: false,
                                onTap: _isSubmitting ? null : _openChat,
                              ),
                            ] else ...<Widget>[
                              WxListItem(
                                icon: currentFriend != null
                                    ? Icons.chat_bubble_outline
                                    : Icons.person_add_alt_1_outlined,
                                title: currentFriend != null ? '发送消息' : '添加好友',
                                onTap: _isSubmitting
                                    ? null
                                    : (currentFriend != null
                                        ? _openChat
                                        : _sendFriendRequest),
                              ),
                              WxListItem(
                                icon: Icons.block_outlined,
                                title: '加入黑名单',
                                showDivider: currentFriend != null && !isBlocked,
                                onTap: _isSubmitting
                                    ? null
                                    : () => _toggleBlacklist(false),
                              ),
                              if (currentFriend != null && !isBlocked) ...<Widget>[
                                WxListItem(
                                  icon: Icons.call_outlined,
                                  title: '语音通话',
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _startCall(
                                            CallMediaType.audio,
                                            friend: currentFriend,
                                          ),
                                ),
                                WxListItem(
                                  icon: Icons.videocam_outlined,
                                  title: '视频通话',
                                  showDivider: false,
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _startCall(
                                            CallMediaType.video,
                                            friend: currentFriend,
                                          ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      WxSectionTitle('会话与其他'),
                      WxListGroup(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (currentFriend != null)
                              WxListItem(
                                icon: Icons.edit_note_rounded,
                                title: '修改备注',
                                onTap: _isSubmitting
                                    ? null
                                    : () => _updateFriendRemark(currentFriend),
                              ),
                            WxListItem(
                              icon: Icons.push_pin_outlined,
                              title: '置顶聊天',
                              onTap: () => _showComingSoon('置顶聊天'),
                            ),
                            WxListItem(
                              icon: Icons.notifications_none_rounded,
                              title: '消息免打扰',
                              showDivider: false,
                              onTap: () => _showComingSoon('消息免打扰'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    WxSectionTitle('基本资料', subtitle: '资料信息（展示）'),
                    WxListGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildInfoRow(
                            '昵称',
                            ProfileDisplayTexts.fieldValue(user.nickname),
                            Icons.badge_outlined,
                          ),
                          _buildInfoRow(
                            '性别',
                            ProfileDisplayTexts.genderLabel(user.gender),
                            Icons.wc_rounded,
                          ),
                          _buildInfoRow(
                            '地区',
                            ProfileDisplayTexts.fieldValue(user.region),
                            Icons.location_on_outlined,
                          ),
                          _buildInfoRow(
                            '生日',
                            ProfileDisplayTexts.birthdayLabel(user.birthday),
                            Icons.cake_outlined,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    WxSectionTitle('更多资料'),
                    WxListGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildInfoRow(
                            '个性签名',
                            ProfileDisplayTexts.fieldValue(user.signature),
                            Icons.short_text_rounded,
                          ),
                          _buildInfoRow(
                            '备注',
                            ProfileDisplayTexts.fieldValue(
                              currentFriend?.remark,
                            ),
                            Icons.drive_file_rename_outline_rounded,
                          ),
                          _buildInfoRow(
                            '手机号',
                            user.allowSearchByPhone == false
                                ? '未公开'
                                : ProfileDisplayTexts.fieldValue(
                                    user.phone,
                                    emptyLabel: '未公开',
                                  ),
                            Icons.phone_outlined,
                          ),
                          _buildInfoRow(
                            '最近登录',
                            ProfileDisplayTexts.fieldValue(user.lastLoginAt),
                            Icons.schedule_rounded,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    WxSectionTitle('账号与更多', subtitle: '更多'),
                    WxListGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          WxListItem(
                            icon: Icons.perm_identity_outlined,
                            title: '账号信息',
                            subtitle:
                                '账号 ${ProfileDisplayTexts.accountIdLine(user.userId)}',
                            onTap: () => _showComingSoon('账号信息'),
                          ),
                          WxListItem(
                            icon: Icons.privacy_tip_outlined,
                            title: '隐私设置',
                            subtitle: '查看资料可见范围与搜索限制。',
                            showDivider: !isSelf,
                            onTap: () {
                              if (isSelf) {
                                Navigator.pushNamed(context, '/privacy-settings');
                                return;
                              }
                              _showComingSoon('隐私设置');
                            },
                          ),
                          if (!isSelf)
                            WxListItem(
                              icon: Icons.flag_outlined,
                              title: '举报用户',
                              subtitle: '遇到问题再使用',
                              onTap: _reportUser,
                            ),
                          if (!isSelf && _userId != null)
                            WxListItem(
                              icon: Icons.search_rounded,
                              title: '搜索聊天记录',
                              subtitle: '在与对方的会话中查找历史消息',
                              showDivider: false,
                              onTap: () => openChatHistorySearch(
                                context,
                                targetId: _userId!,
                                type: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                    WxSectionTitle(
                      '危险操作',
                      subtitle: isSelf ? null : '请谨慎操作',
                    ),
                    if (!isSelf && currentFriend != null)
                      Padding(
                        padding: EdgeInsets.only(
                          left: ImDesignTokens.spaceLg,
                          right: ImDesignTokens.spaceLg,
                          bottom: ImDesignTokens.spaceSm,
                        ),
                        child: Text(
                          '删除好友将解除联系人关系，需重新添加才能聊天。',
                          style: ProfileUiTokens.sectionSubtitleText.copyWith(
                            color: CommonTokens.textTertiary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    if (!isSelf && currentFriend == null)
                      Padding(
                        padding: EdgeInsets.only(
                          left: ImDesignTokens.spaceLg,
                          right: ImDesignTokens.spaceLg,
                          bottom: ImDesignTokens.spaceSm,
                        ),
                        child: Text(
                          '成为好友后，可在此管理联系人关系。',
                          style: ProfileUiTokens.sectionSubtitleText.copyWith(
                            color: CommonTokens.textTertiary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    if (isSelf)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ImDesignTokens.spaceLg,
                        ),
                        child: Text(
                          '当前查看自己的资料，此处不提供删除类操作。',
                          style: ProfileUiTokens.sectionSubtitleText.copyWith(
                            color: CommonTokens.textTertiary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    if (!isSelf && currentFriend != null)
                      WxListGroup(
                        child: WxListItem(
                          icon: Icons.person_remove_alt_1_rounded,
                          title: '删除好友',
                          danger: true,
                          showDivider: false,
                          showChevron: false,
                          onTap: _isSubmitting
                              ? null
                              : () => _deleteFriend(currentFriend),
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
