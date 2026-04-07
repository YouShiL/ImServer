import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/screens/create_group_screen.dart';
import 'package:hailiao_flutter/screens/search_group_screen.dart';
import 'package:hailiao_flutter/theme/empty_state_ux_strings.dart';
import 'package:hailiao_flutter/theme/feedback_ux_strings.dart';
import 'package:hailiao_flutter/theme/group_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/widgets/profile/profile_circle_avatar.dart';
import 'package:hailiao_flutter/widgets/shell/im_template_shell.dart';
import 'package:provider/provider.dart';

String _groupDisplayName(GroupDTO group) {
  final String n = (group.groupName ?? '').trim();
  return n.isEmpty ? '未命名群组' : n;
}


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

  void _openSearchGroupPage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SearchGroupScreen()),
    );
  }

  void _openCreateGroupPage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const CreateGroupScreen()),
    );
  }

  Widget _buildTopActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ImTemplateShell.pagePaddingH,
        0,
        ImTemplateShell.pagePaddingH,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '搜索群号加入，或创建新群聊',
            style: ImTemplateShell.pageSubtitleText(context).copyWith(
              color: GroupUiTokens.chipText,
            ),
          ),
          const SizedBox(height: ImTemplateShell.elementGapMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openSearchGroupPage,
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text('搜索群号'),
                  style: UiTokens.outlinedSecondary(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: ImTemplateShell.elementGapMd),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openCreateGroupPage,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('创建群聊'),
                  style: UiTokens.filledPrimary(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(GroupDTO group, {bool showDivider = true}) {
    final String titleText = _groupDisplayName(group);
    final parts = <String>[
      if ((group.groupId ?? '').trim().isNotEmpty) '群号 ${group.groupId}',
      if (group.memberCount != null) '${group.memberCount} 人',
      if ((group.description ?? '').trim().isNotEmpty) group.description!.trim(),
    ];
    if (group.isMute == true) {
      parts.add('全体禁言');
    }
    final String subLine =
        parts.isEmpty ? '群聊' : parts.take(3).join(' · ');

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: ProfileCircleAvatar(
            title: titleText,
            avatarRaw: group.avatar,
            size: 50,
            fontSize: 18,
          ),
          title: Text(
            titleText,
            style: TextStyle(
              color: UiTokens.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: UiTokens.textSecondary,
              fontSize: 13,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: UiTokens.textSecondary.withValues(alpha: 0.55),
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/group-detail',
              arguments: <String, dynamic>{
                'groupId': group.id,
                'group': group,
              },
            );
          },
        ),
        if (showDivider)
          Divider(height: 1, indent: 62, color: UiTokens.lineSubtle),
      ],
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
          shape: ImTemplateShell.dialogShape,
          insetPadding: ImTemplateShell.dialogInsetPadding,
          title: const ImDialogTitle('撤回申请'),
          titlePadding: ImTemplateShell.dialogTitlePadding,
          contentPadding: ImTemplateShell.dialogContentPadding,
          content: Text(
            '确定撤回这条入群申请吗？',
            style: TextStyle(
              color: UiTokens.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          actionsPadding: ImTemplateShell.dialogActionsPadding,
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '取消',
                style: TextStyle(color: UiTokens.textSecondary),
              ),
            ),
            FilledButton(
              style: UiTokens.filledPrimary(),
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

  Widget _buildJoinRequestCard(
    GroupJoinRequestDTO request, {
    bool showBottomDivider = true,
  }) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.groupInfo == null
                          ? '未命名群组'
                          : _groupDisplayName(request.groupInfo!),
                      style: TextStyle(
                        color: UiTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if ((request.groupInfo?.groupId ?? '').isNotEmpty ||
                  (request.message ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    if ((request.groupInfo?.groupId ?? '').isNotEmpty)
                      '群号 ${request.groupInfo!.groupId}',
                    if ((request.message ?? '').isNotEmpty)
                      '申请信息：${request.message!}',
                  ].join(' · '),
                  style: TextStyle(
                    color: UiTokens.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: [
                    if (request.status == 0)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: UiTokens.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _withdrawJoinRequest(request),
                        child: const Text(
                          '撤回申请',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: UiTokens.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
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
                      child: const Text(
                        '群信息',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showBottomDivider)
          Divider(height: 1, color: UiTokens.lineSubtle),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title, {
    String? subtitle,
    bool secondary = false,
  }) {
    final topPad = secondary ? ImTemplateShell.sectionGap : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ImTemplateShell.pagePaddingH,
        topPad,
        ImTemplateShell.pagePaddingH,
        secondary ? 8 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: CommonTokens.textPrimary,
              fontSize: secondary ? 15 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: CommonTokens.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
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
      backgroundColor: UiTokens.backgroundGray,
      appBar: AppBar(
        title: const Text('群组'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: UiTokens.backgroundGray,
        foregroundColor: UiTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: isInitialLoading
          ? Center(
              child: CircularProgressIndicator(
                color: UiTokens.primaryBlue,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 8),
                  _buildTopActions(),
                  _buildSectionTitle(
                    '我的群组',
                    subtitle: '群名、人数与状态与「群信息」一致',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ImTemplateShell.pagePaddingH,
                    ),
                    child: groupProvider.groups.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            child: Column(
                              children: <Widget>[
                                Icon(
                                  Icons.groups_outlined,
                                  size: 40,
                                  color: UiTokens.textSecondary
                                      .withValues(alpha: 0.75),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  EmptyStateUxStrings.groupListEmptyTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: UiTokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  EmptyStateUxStrings.groupListEmptyDetail,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: UiTokens.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DecoratedBox(
                            decoration: UiTokens.groupedListDecoration(),
                            child: Column(
                              children: [
                                for (int i = 0;
                                    i < groupProvider.groups.length;
                                    i++)
                                  _buildGroupTile(
                                    groupProvider.groups[i],
                                    showDivider:
                                        i < groupProvider.groups.length - 1,
                                  ),
                              ],
                            ),
                          ),
                  ),
                  _buildSectionTitle(
                    '我的入群申请',
                    subtitle: '审核进度',
                    secondary: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ImTemplateShell.pagePaddingH,
                    ),
                    child: groupProvider.myJoinRequests.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  EmptyStateUxStrings
                                      .groupMyJoinRequestsEmptyTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: UiTokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  EmptyStateUxStrings
                                      .groupMyJoinRequestsEmptyDetail,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: UiTokens.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0;
                                  i < groupProvider.myJoinRequests.length;
                                  i++)
                                _buildJoinRequestCard(
                                  groupProvider.myJoinRequests[i],
                                  showBottomDivider:
                                      i < groupProvider.myJoinRequests.length - 1,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
