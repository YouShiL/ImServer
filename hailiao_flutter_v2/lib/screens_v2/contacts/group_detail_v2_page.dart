import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_chat_entry_log.dart';
import 'package:hailiao_flutter_v2/screens_v2/chat/chat_v2_page.dart' deferred as chat_v2;
import 'package:hailiao_flutter_v2/screens_v2/contacts/user_detail_v2_page.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

/// 群资料详情（[ApiService.getGroupById] / [ApiService.getGroupMembers]）。
class GroupDetailV2Page extends StatefulWidget {
  const GroupDetailV2Page({
    super.key,
    required this.groupId,
    this.initialGroup,
    this.openJoinRequestsSection = false,
    this.highlightJoinRequestsSection = false,
  });

  /// 与 WuKong / 会话一致的群 `group_chat.id`。
  final int groupId;
  final GroupDTO? initialGroup;

  /// 从入群申请通知进入时：展示入群审批入口并尝试滚动到该区域。
  final bool openJoinRequestsSection;

  /// 与 [openJoinRequestsSection] 同时使用时：审批入口短时高亮，便于「通知 → 操作」定位。
  final bool highlightJoinRequestsSection;

  @override
  State<GroupDetailV2Page> createState() => _GroupDetailV2PageState();
}

class _GroupDetailV2PageState extends State<GroupDetailV2Page> {
  GroupDTO? _group;
  List<GroupMemberDTO> _members = <GroupMemberDTO>[];
  String? _error;
  bool _loading = true;
  final GlobalKey _joinRequestsKey = GlobalKey();
  bool _didScrollToJoin = false;
  bool _joinHighlight = false;

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final response = await ApiService.getGroupById(widget.groupId);
      if (!response.isSuccess || response.data == null) {
        setState(() {
          if (_group == null) {
            _error = response.message.isNotEmpty ? response.message : '加载失败';
          }
          _loading = false;
        });
        return;
      }
      final membersResp = await ApiService.getGroupMembers(widget.groupId);
      setState(() {
        _group = response.data;
        if (membersResp.isSuccess && membersResp.data != null) {
          _members = membersResp.data!;
        }
        _error = null;
        _loading = false;
      });
      if (mounted &&
          widget.openJoinRequestsSection &&
          _canManageJoinRequests(_myRole(context.read<AuthProvider>()))) {
        _scheduleScrollToJoin();
      }
    } catch (e) {
      setState(() {
        if (_group == null) {
          _error = e.toString();
        }
        _loading = false;
      });
    }
  }

  String? _avatarUrl(GroupDTO? g) {
    final String? raw = g?.avatar?.trim();
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

  int? _myRole(AuthProvider auth) {
    final int? self = auth.messagingUserId;
    if (self == null) {
      return null;
    }
    for (final GroupMemberDTO m in _members) {
      if (m.userId == self) {
        return m.role;
      }
    }
    return null;
  }

  String _roleLabel(int? role) {
    if (role == 1) {
      return '群主';
    }
    if (role == 2) {
      return '管理员';
    }
    return '成员';
  }

  bool _canRename(int? role) {
    return role == 1 || role == 2;
  }

  bool _canManageJoinRequests(int? role) {
    return role == 1 || role == 2;
  }

  void _scheduleScrollToJoin() {
    if (_didScrollToJoin) {
      return;
    }
    _didScrollToJoin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final BuildContext? ctx = _joinRequestsKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.12,
          duration: Duration.zero,
        );
      }
      if (mounted && widget.highlightJoinRequestsSection) {
        await _pulseJoinHighlight();
      }
    });
  }

  Future<void> _pulseJoinHighlight() async {
    if (!widget.highlightJoinRequestsSection) {
      return;
    }
    const int times = 3;
    for (int i = 0; i < times; i++) {
      if (!mounted) {
        return;
      }
      setState(() => _joinHighlight = true);
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) {
        return;
      }
      setState(() => _joinHighlight = false);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> _openJoinRequestsSheet(BuildContext context) async {
    final GroupProvider gp = context.read<GroupProvider>();
    await gp.loadJoinRequests(widget.groupId);
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Consumer<GroupProvider>(
              builder: (BuildContext context, GroupProvider g, _) {
                final List<GroupJoinRequestDTO> pending = g.joinRequests
                    .where((GroupJoinRequestDTO r) => (r.status ?? 0) == 0)
                    .toList();
                if (pending.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('暂无待审批入群申请')),
                  );
                }
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '入群审批',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: pending.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(height: 1),
                          itemBuilder: (BuildContext context, int i) {
                            final GroupJoinRequestDTO r = pending[i];
                            final String name =
                                r.userInfo?.nickname?.trim().isNotEmpty == true
                                    ? r.userInfo!.nickname!.trim()
                                    : '用户 ${r.userId ?? '?'}';
                            return ListTile(
                              title: Text(name),
                              subtitle: (r.message ?? '').trim().isNotEmpty
                                  ? Text(r.message!.trim())
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TextButton(
                                    onPressed: r.id == null
                                        ? null
                                        : () async {
                                            final bool ok = await g.reviewJoinRequest(
                                              r.id!,
                                              approve: false,
                                            );
                                            if (!context.mounted) {
                                              return;
                                            }
                                            if (ok) {
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('已拒绝')),
                                              );
                                            }
                                          },
                                    child: const Text('拒绝'),
                                  ),
                                  FilledButton(
                                    onPressed: r.id == null
                                        ? null
                                        : () async {
                                            final bool ok = await g.reviewJoinRequest(
                                              r.id!,
                                              approve: true,
                                            );
                                            if (!context.mounted) {
                                              return;
                                            }
                                            if (ok) {
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('已通过')),
                                              );
                                            }
                                          },
                                    child: const Text('同意'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _renameGroup(BuildContext context, GroupDTO g) async {
    final TextEditingController c = TextEditingController(
      text: (g.groupName ?? '').trim(),
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('修改群名称'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              hintText: '群名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    c.dispose();
    if (result == null || result.isEmpty) {
      return;
    }
    final response = await ApiService.updateGroup(widget.groupId, <String, dynamic>{
      'groupName': result,
    });
    if (!context.mounted) {
      return;
    }
    if (response.isSuccess && response.data != null) {
      setState(() {
        _group = response.data;
      });
      await context.read<GroupProvider>().loadGroups();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message.isNotEmpty ? response.message : '保存失败')),
      );
    }
  }

  Future<void> _quitGroup(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('退出群聊'),
          content: const Text('确定退出该群？'),
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
    final response = await ApiService.deleteGroup(widget.groupId);
    if (!context.mounted) {
      return;
    }
    if (response.isSuccess) {
      await context.read<GroupProvider>().loadGroups();
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已退出群聊')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message.isNotEmpty ? response.message : '操作失败')),
      );
    }
  }

  Future<void> _openChat(BuildContext context, String title) async {
    imChatEntryLog(
      'group_detail',
      targetId: widget.groupId,
      type: 2,
      title: title,
    );
    await chat_v2.loadLibrary();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => chat_v2.ChatV2Page(
          targetId: widget.groupId,
          type: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final GroupDTO? g = _group;
    final int? myRole = _myRole(auth);

    if (_loading && g == null) {
      return const SecondaryPageScaffoldV2(
        title: '群聊详情',
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && g == null) {
      return SecondaryPageScaffoldV2(
        title: '群聊详情',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('重试')),
              ],
            ),
          ),
        ),
      );
    }
    if (g == null) {
      return const SecondaryPageScaffoldV2(
        title: '群聊详情',
        child: SizedBox.shrink(),
      );
    }

    final String title = (g.groupName ?? '').trim().isNotEmpty ? g.groupName!.trim() : '群聊';
    final String groupIdStr = (g.groupCode ?? '').trim().isNotEmpty ? g.groupCode!.trim() : '${g.id ?? widget.groupId}';
    final int memberCount = _members.isNotEmpty
        ? _members.length
        : (g.memberCount ?? 0);

    return SecondaryPageScaffoldV2(
      title: '群聊详情',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: <Widget>[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _avatarUrl(g) != null
                  ? Image.network(
                      _avatarUrl(g)!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                          _avatarPlaceholder(),
                    )
                  : _avatarPlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ChatV2Tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '群 ID $groupIdStr',
              style: ChatV2Tokens.headerSubtitle,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$memberCount 名成员 · ${_roleLabel(myRole)}',
              style: ChatV2Tokens.headerSubtitle,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTile('群公告', (g.notice ?? '').trim().isNotEmpty ? g.notice!.trim() : '未设置'),
          const SizedBox(height: 12),
          _sectionTile('群简介', (g.description ?? '').trim().isNotEmpty ? g.description!.trim() : '未设置'),
          const SizedBox(height: 24),
          if (widget.openJoinRequestsSection && _canManageJoinRequests(myRole)) ...<Widget>[
            AnimatedContainer(
              key: _joinRequestsKey,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: _joinHighlight
                    ? const Color(0xFFFFF3E0)
                    : ChatV2Tokens.surface,
                borderRadius: BorderRadius.circular(8),
                border: _joinHighlight
                    ? Border.all(color: const Color(0xFFFFB74D))
                    : null,
              ),
              child: ListTile(
                tileColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                title: const Text('入群申请'),
                subtitle: const Text('审批待处理成员'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openJoinRequestsSheet(context),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ListTile(
            tileColor: ChatV2Tokens.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Text('查看全部成员'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GroupMembersV2Page(
                    groupId: widget.groupId,
                    groupName: title,
                  ),
                ),
              );
            },
          ),
          if (_canRename(myRole)) ...<Widget>[
            const SizedBox(height: 8),
            ListTile(
              tileColor: ChatV2Tokens.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text('修改群名称'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _renameGroup(context, g),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ChatV2Tokens.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _openChat(context, title),
              child: const Text('进入聊天'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _quitGroup(context),
              child: const Text('退出群聊', style: TextStyle(color: Color(0xFFE34D59))),
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
      child: const Icon(Icons.groups, size: 48, color: ChatV2Tokens.textSecondary),
    );
  }

  Widget _sectionTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: ChatV2Tokens.headerSubtitle),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ChatV2Tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ChatV2Tokens.divider),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: ChatV2Tokens.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// 群成员列表（最小列表；点击进用户详情）。
class GroupMembersV2Page extends StatefulWidget {
  const GroupMembersV2Page({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final int groupId;
  final String groupName;

  @override
  State<GroupMembersV2Page> createState() => _GroupMembersV2PageState();
}

class _GroupMembersV2PageState extends State<GroupMembersV2Page> {
  List<GroupMemberDTO> _members = <GroupMemberDTO>[];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final response = await ApiService.getGroupMembers(widget.groupId);
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _error = response.message.isNotEmpty ? response.message : '加载失败';
          _loading = false;
        });
        return;
      }
      setState(() {
        _members = response.data!;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _memberTitle(GroupMemberDTO m) {
    final String fromUser = m.userInfo?.nickname?.trim().isNotEmpty == true
        ? m.userInfo!.nickname!.trim()
        : (m.nickname ?? '').trim();
    if (fromUser.isNotEmpty) {
      return fromUser;
    }
    if (m.userId != null) {
      return '用户 ${m.userId}';
    }
    return '成员';
  }

  String _memberSubtitle(GroupMemberDTO m) {
    if (m.userId != null) {
      return 'UID ${m.userId}';
    }
    return '';
  }

  String _roleShort(int? role) {
    if (role == 1) {
      return '群主';
    }
    if (role == 2) {
      return '管理员';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryPageScaffoldV2(
      title: '${widget.groupName} 成员',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('重试')),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _members.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final GroupMemberDTO m = _members[index];
                    final int? uid = m.userId ?? m.userInfo?.id;
                    final String role = _roleShort(m.role);
                    final String name = _memberTitle(m);
                    final String initial =
                        name.isNotEmpty ? name.substring(0, 1) : '?';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: ChatV2Tokens.surfaceSoft,
                        child: Text(initial),
                      ),
                      title: Text(_memberTitle(m)),
                      subtitle: Text(
                        role.isNotEmpty ? '${_memberSubtitle(m)} · $role' : _memberSubtitle(m),
                        style: ChatV2Tokens.headerSubtitle,
                      ),
                      onTap: uid == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => UserDetailV2Page(userId: uid),
                                ),
                              );
                            },
                    );
                  },
                ),
    );
  }
}
