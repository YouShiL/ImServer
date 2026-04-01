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
                  error = '\u8bf7\u8f93\u5165\u7fa4\u540d\u79f0';
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
                  const SnackBar(content: Text('\u7fa4\u7ec4\u5df2\u521b\u5efa')),
                );
              } else {
                setDialogState(() {
                  error = groupProvider.error ?? '\u521b\u5efa\u7fa4\u7ec4\u5931\u8d25';
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('\u521b\u5efa\u7fa4\u7ec4'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '\u7fa4\u540d\u79f0',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '\u7fa4\u4ecb\u7ecd',
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
                  child: const Text('\u53d6\u6d88'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(
                    isSubmitting ? '\u521b\u5efa\u4e2d...' : '\u521b\u5efa',
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
                  error = '\u8bf7\u8f93\u5165\u7fa4\u53f7';
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
                  error = '\u641c\u7d22\u7fa4\u7ec4\u5931\u8d25';
                });
              } finally {
                setDialogState(() {
                  isSearching = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('\u67e5\u627e\u7fa4\u7ec4'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: groupIdController,
                      decoration: InputDecoration(
                        labelText: '\u7fa4\u53f7',
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
                        title: Text(group!.groupName ?? '\u672a\u547d\u540d\u7fa4\u7ec4'),
                        subtitle: Text(
                          [
                            if ((group!.groupId ?? '').isNotEmpty)
                              '\u7fa4\u53f7 ${group!.groupId}',
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
                          child: const Text('\u67e5\u770b'),
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
                  child: const Text('\u5173\u95ed'),
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
                  '\u67e5\u627e\u7fa4\u7ec4',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '\u8f93\u5165\u7fa4\u53f7\uff0c\u5feb\u901f\u67e5\u770b\u7fa4\u8d44\u6599\u5e76\u53d1\u8d77\u5165\u7fa4\u7533\u8bf7',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _openSearchGroupDialog,
            icon: const Icon(Icons.search),
            label: const Text('\u67e5\u7fa4'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(GroupDTO group) {
    final meta = <String>[
      if ((group.groupId ?? '').isNotEmpty) '\u7fa4\u53f7 ${group.groupId}',
      if (group.memberCount != null) '${group.memberCount}\u4eba',
      if (group.maxMembers != null) '\u4e0a\u9650 ${group.maxMembers}',
      if (group.isMute == true) '\u5df2\u9759\u97f3',
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
          group.groupName ?? '\u672a\u547d\u540d\u7fa4\u7ec4',
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
          title: const Text('\u64a4\u56de\u7533\u8bf7'),
          content: const Text('\u786e\u5b9a\u64a4\u56de\u8fd9\u6761\u5165\u7fa4\u7533\u8bf7\u5417\uff1f'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('\u53d6\u6d88'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('\u786e\u8ba4\u64a4\u56de'),
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
              ? '\u5165\u7fa4\u7533\u8bf7\u5df2\u64a4\u56de'
              : (groupProvider.error ?? '\u64a4\u56de\u5165\u7fa4\u7533\u8bf7\u5931\u8d25'),
        ),
      ),
    );
  }

  Widget _buildJoinRequestCard(GroupJoinRequestDTO request) {
    final statusText = switch (request.status) {
      1 => '\u5df2\u901a\u8fc7',
      2 => '\u5df2\u62d2\u7edd',
      3 => '\u5df2\u64a4\u56de',
      _ => '\u5f85\u5ba1\u6838',
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
                  request.groupInfo?.groupName ?? '\u672a\u77e5\u7fa4\u7ec4',
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
                '\u7fa4\u53f7 ${request.groupInfo!.groupId}',
              if ((request.message ?? '').isNotEmpty) '\u7533\u8bf7\u4fe1\u606f\uff1a${request.message!}',
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
                    child: const Text('\u64a4\u56de\u7533\u8bf7'),
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
                  child: const Text('\u67e5\u770b\u7fa4\u8be6\u60c5'),
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
        title: const Text('\u7fa4\u7ec4'),
        actions: [
          IconButton(
            onPressed: _openSearchGroupDialog,
            icon: const Icon(Icons.search),
            tooltip: '\u67e5\u627e\u7fa4\u7ec4',
          ),
          IconButton(
            onPressed: _openCreateGroupDialog,
            icon: const Icon(Icons.add),
            tooltip: '\u521b\u5efa\u7fa4\u7ec4',
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
                    '\u6211\u7684\u5165\u7fa4\u7533\u8bf7',
                    subtitle: '\u53ef\u4ee5\u5728\u8fd9\u91cc\u67e5\u770b\u5ba1\u6838\u8fdb\u5ea6',
                  ),
                  if (groupProvider.myJoinRequests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        '\u6682\u65e0\u5165\u7fa4\u7533\u8bf7',
                        style: TextStyle(color: Color(0xFF9E9E9E)),
                      ),
                    )
                  else
                    ...groupProvider.myJoinRequests.map(_buildJoinRequestCard),
                  _buildSectionTitle(
                    '\u6211\u7684\u7fa4\u7ec4',
                    subtitle: '\u5df2\u52a0\u5165\u548c\u5df2\u521b\u5efa\u7684\u7fa4\u90fd\u5728\u8fd9\u91cc',
                  ),
                  if (groupProvider.groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        '\u6682\u65e0\u7fa4\u7ec4',
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
