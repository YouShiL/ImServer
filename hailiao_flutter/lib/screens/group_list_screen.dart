import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:provider/provider.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final groupProvider = context.read<GroupProvider>();
    await groupProvider.loadGroups();
    await groupProvider.loadMyJoinRequests();
  }

  Future<void> _openCreateGroupDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSubmitting = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (nameController.text.trim().isEmpty) {
                setDialogState(() {
                  error = '请输入群名称';
                });
                return;
              }

              setDialogState(() {
                isSubmitting = true;
                error = null;
              });

              final groupProvider = context.read<GroupProvider>();
              final success = await groupProvider.createGroup(
                nameController.text.trim(),
                descriptionController.text.trim(),
              );

              if (!mounted) {
                return;
              }

              if (success) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('群组已创建')),
                );
              } else {
                setDialogState(() {
                  error = groupProvider.error ?? '创建群组失败';
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('创建群组'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '群名称',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '群介绍',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(
                    isSubmitting ? '创建中...' : '创建',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openSearchGroupDialog() async {
    final groupIdController = TextEditingController();
    bool isSearching = false;
    String? error;
    GroupDTO? group;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> search() async {
              final keyword = groupIdController.text.trim();
              if (keyword.isEmpty) {
                setDialogState(() {
                  error = '请输入群号';
                });
                return;
              }

              setDialogState(() {
                isSearching = true;
                error = null;
                group = null;
              });

              try {
                final response = await ApiService.getGroupByBusinessId(keyword);
                setDialogState(() {
                  if (response.isSuccess) {
                    group = response.data;
                  } else {
                    error = response.message;
                  }
                });
              } catch (_) {
                setDialogState(() {
                  error = '搜索群组失败';
                });
              } finally {
                setDialogState(() {
                  isSearching = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('查找群组'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: groupIdController,
                      decoration: InputDecoration(
                        labelText: '群号',
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                onPressed: search,
                                icon: const Icon(Icons.search),
                              ),
                      ),
                      onSubmitted: (_) => search(),
                    ),
                    if (group != null) ...[
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.groups,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(group!.groupName ?? '未命名群组'),
                        subtitle: Text(
                          [
                            if ((group!.groupId ?? '').isNotEmpty)
                              '群号 ${group!.groupId}',
                            if ((group!.description ?? '').isNotEmpty)
                              group!.description!,
                          ].join(' | '),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.pushNamed(
                              context,
                              '/group-detail',
                              arguments: {'groupId': group!.id, 'group': group},
                            );
                          },
                          child: const Text('查看'),
                        ),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('关闭'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '查找群组',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '输入群号，快速查看群资料并发起入群申请',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _openSearchGroupDialog,
            icon: const Icon(Icons.search),
            label: const Text('查群'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(GroupDTO group) {
    final meta = <String>[
      if ((group.groupId ?? '').isNotEmpty) '群号 ${group.groupId}',
      if (group.memberCount != null) '${group.memberCount}人',
      if (group.maxMembers != null) '上限 ${group.maxMembers}',
      if (group.isMute == true) '已静音',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.groups, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          group.groupName ?? '未命名群组',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            if (meta.isNotEmpty) meta.join(' | '),
            if ((group.description ?? '').isNotEmpty) group.description!,
          ].join('\n'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/group-detail',
            arguments: {'groupId': group.id, 'group': group},
          );
        },
      ),
    );
  }

  Future<void> _withdrawJoinRequest(GroupJoinRequestDTO request) async {
    if (request.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('撤回申请'),
          content: const Text('确定撤回这条入群申请吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认撤回'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final groupProvider = context.read<GroupProvider>();
    final success = await groupProvider.withdrawJoinRequest(request.id!);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '入群申请已撤回'
              : (groupProvider.error ?? '撤回入群申请失败'),
        ),
      ),
    );
  }

  Widget _buildJoinRequestCard(GroupJoinRequestDTO request) {
    final statusText = switch (request.status) {
      1 => '已通过',
      2 => '已拒绝',
      3 => '已撤回',
      _ => '待审核',
    };
    final statusColor = switch (request.status) {
      1 => const Color(0xFF2E7D32),
      2 => const Color(0xFFC62828),
      3 => const Color(0xFF616161),
      _ => const Color(0xFFEF6C00),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.groupInfo?.groupName ?? '未知群组',
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              if ((request.groupInfo?.groupId ?? '').isNotEmpty)
                '群号 ${request.groupInfo!.groupId}',
              if ((request.message ?? '').isNotEmpty) '申请信息：${request.message!}',
            ].join(' | '),
            style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                if (request.status == 0)
                  TextButton(
                    onPressed: () => _withdrawJoinRequest(request),
                    child: const Text('撤回申请'),
                  ),
                TextButton(
                  onPressed: request.groupInfo?.id == null
                      ? null
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/group-detail',
                            arguments: {
                              'groupId': request.groupInfo!.id,
                              'group': request.groupInfo,
                            },
                          );
                        },
                  child: const Text('查看群详情'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final isInitialLoading =
        groupProvider.isLoading &&
        groupProvider.groups.isEmpty &&
        groupProvider.myJoinRequests.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('群组'),
        actions: [
          IconButton(
            onPressed: _openSearchGroupDialog,
            icon: const Icon(Icons.search),
            tooltip: '查找群组',
          ),
          IconButton(
            onPressed: _openCreateGroupDialog,
            icon: const Icon(Icons.add),
            tooltip: '创建群组',
          ),
        ],
      ),
      body: isInitialLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildSearchCard(),
                  _buildSectionTitle(
                    '我的入群申请',
                    subtitle: '可以在这里查看审核进度',
                  ),
                  if (groupProvider.myJoinRequests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        '暂无入群申请',
                        style: TextStyle(color: Color(0xFF9E9E9E)),
                      ),
                    )
                  else
                    ...groupProvider.myJoinRequests.map(_buildJoinRequestCard),
                  _buildSectionTitle(
                    '我的群组',
                    subtitle: '已加入和已创建的群都在这里',
                  ),
                  if (groupProvider.groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        '暂无群组',
                        style: TextStyle(color: Color(0xFF9E9E9E)),
                      ),
                    )
                  else
                    ...groupProvider.groups.map(_buildGroupTile),
                ],
              ),
            ),
    );
  }
}
