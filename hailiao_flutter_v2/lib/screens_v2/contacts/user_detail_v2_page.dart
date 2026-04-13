import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_chat_entry_log.dart';
import 'package:hailiao_flutter_v2/screens_v2/chat/chat_v2_page.dart' deferred as chat_v2;
import 'package:hailiao_flutter_v2/screens_v2/contacts/add_friend_v2_page.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

/// 他人资料页（微信风格：展示 + 发消息 / 加好友 / 更多占位）。
class UserDetailV2Page extends StatefulWidget {
  const UserDetailV2Page({
    super.key,
    required this.userId,
    this.initialFriend,
  });

  /// 业务用户主键（与聊天 targetId、FriendDTO.friendUserInfo.id 对齐）。
  final int userId;
  final FriendDTO? initialFriend;

  @override
  State<UserDetailV2Page> createState() => _UserDetailV2PageState();
}

class _UserDetailV2PageState extends State<UserDetailV2Page> {
  UserDTO? _user;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _user = widget.initialFriend?.friendUserInfo;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final response = await ApiService.getUserById(widget.userId);
      if (!response.isSuccess || response.data == null) {
        setState(() {
          if (_user == null) {
            _error = response.message.isNotEmpty ? response.message : '加载失败';
          }
          _loading = false;
        });
        return;
      }
      setState(() {
        _user = response.data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        if (_user == null) {
          _error = e.toString();
        }
        _loading = false;
      });
    }
  }

  bool _isSelf(AuthProvider auth) {
    final int? self = auth.messagingUserId ?? auth.user?.id;
    return self != null && self == widget.userId;
  }

  bool _isFriend(FriendProvider fp) {
    for (final FriendDTO f in fp.friends) {
      if (f.friendUserId == widget.userId) {
        return true;
      }
      if (f.friendUserInfo?.id == widget.userId) {
        return true;
      }
    }
    return false;
  }

  String _genderLabel(UserDTO? u) {
    final int? g = u?.gender;
    if (g == null) {
      return '未设置';
    }
    if (g == 1) {
      return '男';
    }
    if (g == 2) {
      return '女';
    }
    return '保密';
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

  Future<void> _openChat(BuildContext context, String titleHint) async {
    imChatEntryLog(
      'user_detail',
      targetId: widget.userId,
      type: 1,
      title: titleHint,
    );
    await chat_v2.loadLibrary();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => chat_v2.ChatV2Page(
          targetId: widget.userId,
          type: 1,
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ChatV2Tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('加入黑名单'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('功能开发中')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('举报'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('功能开发中')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final FriendProvider friendProvider = context.watch<FriendProvider>();
    final UserDTO? u = _user;
    final bool self = _isSelf(auth);
    final bool friend = _isFriend(friendProvider);
    final String displayName = u?.nickname?.trim().isNotEmpty == true
        ? u!.nickname!.trim()
        : '用户';
    final String userIdStr = u?.userCode?.trim().isNotEmpty == true
        ? u!.userCode!.trim()
        : '${widget.userId}';

    return SecondaryPageScaffoldV2(
      title: '个人资料',
      actions: <Widget>[
        if (!self)
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showMore(context),
          ),
      ],
      child: _loading && u == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && u == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: <Widget>[
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _avatarUrl(u) != null
                            ? Image.network(
                                _avatarUrl(u)!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (BuildContext c, Object e, StackTrace? s) =>
                                        _avatarPlaceholder(),
                              )
                            : _avatarPlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: ChatV2Tokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'ID $userIdStr',
                        style: ChatV2Tokens.headerSubtitle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _infoTile('性别', _genderLabel(u)),
                    _infoTile(
                      '个性签名',
                      u?.signature?.trim().isNotEmpty == true
                          ? u!.signature!.trim()
                          : '未设置',
                    ),
                    const SizedBox(height: 32),
                    if (self)
                      Text(
                        '这是你自己',
                        textAlign: TextAlign.center,
                        style: ChatV2Tokens.headerSubtitle,
                      )
                    else ...<Widget>[
                      if (friend) ...<Widget>[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: ChatV2Tokens.accent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _openChat(context, displayName),
                            child: const Text('发消息'),
                          ),
                        ),
                      ] else ...<Widget>[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: ChatV2Tokens.accent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AddFriendV2Page(),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('请在添加好友页搜索用户 ID：$userIdStr'),
                                ),
                              );
                            },
                            child: const Text('加好友'),
                          ),
                        ),
                      ],
                    ],
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

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: ChatV2Tokens.headerSubtitle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: ChatV2Tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
