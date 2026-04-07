import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/screens/edit_group_profile_screen.dart';
import 'package:hailiao_flutter/screens/group_chat_screen.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/theme/empty_state_ux_strings.dart';
import 'package:hailiao_flutter/theme/feedback_ux_strings.dart';
import 'package:hailiao_flutter/theme/group_ui_tokens.dart';
import 'package:hailiao_flutter/theme/search_ux_strings.dart';
import 'package:hailiao_flutter/widgets/common/badge_tag.dart';
import 'package:hailiao_flutter/widgets/common/wx_list_group.dart';
import 'package:hailiao_flutter/widgets/common/wx_section_title.dart';
import 'package:hailiao_flutter/widgets/profile/profile_circle_avatar.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';
import 'package:hailiao_flutter/widgets/chat/open_chat_history_search.dart';
import 'package:hailiao_flutter/widgets/shell/im_template_shell.dart';
import 'package:provider/provider.dart';

abstract class GroupDetailApi {
  Future<ResponseDTO<GroupDTO>> getGroupById(int groupId);
  Future<ResponseDTO<UserDTO>> searchUser(String keyword, {String type});
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  });
}

class ApiGroupDetailApi implements GroupDetailApi {
  const ApiGroupDetailApi();

  @override
  Future<ResponseDTO<GroupDTO>> getGroupById(int groupId) {
    return ApiService.getGroupById(groupId);
  }

  @override
  Future<ResponseDTO<UserDTO>> searchUser(
    String keyword, {
    String type = 'userId',
  }) {
    return ApiService.searchUser(keyword, type: type);
  }

  @override
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) {
    return ApiService.createReport(
      targetId,
      targetType,
      reason,
      evidence: evidence,
    );
  }
}

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, GroupDetailApi? api})
    : api = api ?? const ApiGroupDetailApi();

  final GroupDetailApi api;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _initialized = false;
  bool _isRefreshing = true;
  bool _isActionRunning = false;
  int? _groupId;
  GroupDTO? _group;
  String? _error;

  GroupMemberDTO? _findCurrentMember(GroupProvider groupProvider, int? userId) {
    if (userId == null) {
      return null;
    }
    for (final member in groupProvider.groupMembers) {
      if (member.userId == userId) {
        return member;
      }
    }
    return null;
  }

  bool _canManageMember(int? currentRole, GroupMemberDTO target, int? currentUserId) {
    if (currentRole == null || currentUserId == null || target.userId == null) {
      return false;
    }
    if (target.userId == currentUserId) {
      return false;
    }
    return currentRole < (target.role ?? 99);
  }

  Future<void> _editGroupInfo() async {
    if (_groupId == null || _group == null || _isActionRunning) {
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditGroupProfileScreen(
          groupId: _groupId!,
          group: _group!,
        ),
      ),
    );
    if (!mounted || saved != true) {
      return;
    }
    await _loadGroupData();
  }

  Future<void> _toggleGroupMute(bool nextMute) async {
    if (_groupId == null || _isActionRunning) {
      return;
    }

    setState(() {
      _isActionRunning = true;
    });

    final groupProvider = context.read<GroupProvider>();
    final success = await groupProvider.setGroupMute(_groupId!, nextMute);

    if (!mounted) {
      return;
    }

    setState(() {
      _isActionRunning = false;
      if (success && _group != null) {
        _group = GroupDTO(
          id: _group!.id,
          groupId: _group!.groupId,
          groupName: _group!.groupName,
          description: _group!.description,
          notice: _group!.notice,
          avatar: _group!.avatar,
          ownerId: _group!.ownerId,
          groupType: _group!.groupType,
          memberCount: _group!.memberCount,
          maxMembers: _group!.maxMembers,
          needVerify: _group!.needVerify,
          allowMemberInvite: _group!.allowMemberInvite,
          joinType: _group!.joinType,
          isMute: nextMute,
          status: _group!.status,
          createdAt: _group!.createdAt,
          updatedAt: _group!.updatedAt,
        );
      }
    });

    final message = success
        ? (nextMute
            ? '已开启全体禁言'
            : '已关闭全体禁言')
        : FeedbackUxStrings.messageOrFallback(
            groupProvider.error,
            FeedbackUxStrings.fallbackOperationFailed,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleMemberMute(GroupMemberDTO member) async {
    if (_groupId == null || member.userId == null || _isActionRunning) {
      return;
    }

    final String who = ProfileDisplayTexts.groupMemberTitle(member);
    final nextMute = !(member.isMute ?? false);
    setState(() {
      _isActionRunning = true;
    });

    final groupProvider = context.read<GroupProvider>();
    final success =
        await groupProvider.setMemberMute(_groupId!, member.userId!, nextMute);

    if (!mounted) {
      return;
    }

    setState(() {
      _isActionRunning = false;
    });

    final message = success
        ? (nextMute
            ? '已对「$who」禁言'
            : '已解除「$who」的禁言')
        : FeedbackUxStrings.messageOrFallback(
            groupProvider.error,
            FeedbackUxStrings.fallbackOperationFailed,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleMemberAdmin(GroupMemberDTO member) async {
    if (_groupId == null || member.userId == null || _isActionRunning) {
      return;
    }

    final String who = ProfileDisplayTexts.groupMemberTitle(member);
    final nextAdmin = member.role != 2;
    setState(() {
      _isActionRunning = true;
    });

    final groupProvider = context.read<GroupProvider>();
    final success =
        await groupProvider.setMemberAdmin(_groupId!, member.userId!, nextAdmin);

    if (!mounted) {
      return;
    }

    setState(() {
      _isActionRunning = false;
    });

    final message = success
        ? (nextAdmin
            ? '已将「$who」设为管理员'
            : '已取消「$who」的管理员身份')
        : FeedbackUxStrings.messageOrFallback(
            groupProvider.error,
            FeedbackUxStrings.fallbackOperationFailed,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _transferOwnership(GroupMemberDTO member) async {
    if (_groupId == null || member.userId == null || _isActionRunning) {
      return;
    }

    final String who = ProfileDisplayTexts.groupMemberTitle(member);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: ImTemplateShell.dialogShape,
          insetPadding: ImTemplateShell.dialogInsetPadding,
          title: const ImDialogTitle(FeedbackUxStrings.dialogTitleTransferOwner),
          titlePadding: ImTemplateShell.dialogTitlePadding,
          contentPadding: ImTemplateShell.dialogContentPadding,
          content: Text(
            '确认将群主身份转让给「$who」吗？',
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
                FeedbackUxStrings.actionCancel,
                style: TextStyle(color: UiTokens.textSecondary),
              ),
            ),
            FilledButton(
              style: UiTokens.filledDanger(),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(FeedbackUxStrings.dialogActionTransferOwner),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isActionRunning = true;
    });

    final groupProvider = context.read<GroupProvider>();
    final success = await groupProvider.transferOwnership(_groupId!, member.userId!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isActionRunning = false;
    });

    final message = success
        ? '已将群主转让给「$who」'
        : FeedbackUxStrings.messageOrFallback(
            groupProvider.error,
            FeedbackUxStrings.fallbackOperationFailed,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    if (success) {
      _loadGroupData();
    }
  }

  Future<void> _requestToJoinGroup() async {
    if (_groupId == null || _isActionRunning) {
      return;
    }

    final messageController = TextEditingController();
    bool isSubmitting = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final dialogNavigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(this.context);

              setDialogState(() {
                isSubmitting = true;
                error = null;
              });

              final groupProvider = context.read<GroupProvider>();
              final success = await groupProvider.requestToJoinGroup(
                _groupId!,
                message: messageController.text.trim(),
              );

              if (!mounted) {
                return;
              }

              if (success) {
                if (!dialogContext.mounted) {
                  return;
                }
                dialogNavigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('入群申请已提交')),
                );
              } else {
                setDialogState(() {
                  error = FeedbackUxStrings.messageOrFallback(
                    groupProvider.error,
                    FeedbackUxStrings.fallbackOperationFailed,
                  );
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              shape: ImTemplateShell.dialogShape,
              insetPadding: ImTemplateShell.dialogInsetPadding,
              title: const ImDialogTitle('申请加入群组'),
              titlePadding: ImTemplateShell.dialogTitlePadding,
              contentPadding: ImTemplateShell.dialogContentPadding,
              actionsPadding: ImTemplateShell.dialogActionsPadding,
              actionsAlignment: MainAxisAlignment.end,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: ImTemplateShell.dialogFieldDecoration(
                      label: '申请信息',
                      hint: '可以填写你的来意',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: ImTemplateShell.elementGapMd),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: CommonTokens.danger,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(FeedbackUxStrings.actionCancel),
                ),
                FilledButton(
                  style: UiTokens.filledPrimary(),
                  onPressed: isSubmitting ? null : submit,
                  child: Text(
                    isSubmitting
                        ? FeedbackUxStrings.buttonSubmittingInProgress
                        : '提交申请',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reviewJoinRequest(
    GroupJoinRequestDTO request,
    bool approve,
  ) async {
    if (_groupId == null || _isActionRunning || request.id == null) {
      return;
    }

    final String who = ProfileDisplayTexts.joinRequestApplicantTitle(request);

    setState(() {
      _isActionRunning = true;
    });

    final groupProvider = context.read<GroupProvider>();
    final success = await groupProvider.reviewJoinRequest(
      request.id!,
      approve: approve,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isActionRunning = false;
    });

    final message = success
        ? (approve
            ? '已同意「$who」的入群申请'
            : '已拒绝「$who」的入群申请')
        : FeedbackUxStrings.messageOrFallback(
            groupProvider.error,
            FeedbackUxStrings.fallbackOperationFailed,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    if (success) {
      _loadGroupData();
    }
  }

  Future<void> _reportGroup() async {
    if (_groupId == null || _isActionRunning) {
      return;
    }

    final reasons = <String>[
      '违规内容',
      '刷屏或广告',
      '诈骗或虚假信息',
      '其他',
    ];
    String selectedReason = reasons.first;
    final evidenceController = TextEditingController();
    String? error;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final dialogNavigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(this.context);

              setDialogState(() {
                isSubmitting = true;
                error = null;
              });

              try {
                final response = await widget.api.createReport(
                  _groupId!,
                  2,
                  selectedReason,
                  evidence: evidenceController.text.trim(),
                );

                if (!mounted) {
                  return;
                }

                if (response.isSuccess) {
                  if (!dialogContext.mounted) {
                    return;
                  }
                  dialogNavigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('群组举报已提交')),
                  );
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
              title: const ImDialogTitle('举报群组'),
              titlePadding: ImTemplateShell.dialogTitlePadding,
              contentPadding: ImTemplateShell.dialogContentPadding,
              actionsPadding: ImTemplateShell.dialogActionsPadding,
              actionsAlignment: MainAxisAlignment.end,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      decoration: ImTemplateShell.dialogFieldDecoration(
                        label: '举报原因',
                      ),
                      items: reasons
                          .map(
                            (reason) => DropdownMenuItem(
                              value: reason,
                              child: Text(reason),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedReason = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: ImTemplateShell.elementGapMd),
                    TextField(
                      controller: evidenceController,
                      maxLines: 4,
                      decoration: ImTemplateShell.dialogFieldDecoration(
                        label: '补充说明',
                        hint: '可以简要描述问题',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: ImTemplateShell.elementGapMd),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: CommonTokens.danger,
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
                  child: const Text(FeedbackUxStrings.actionCancel),
                ),
                FilledButton(
                  style: UiTokens.filledPrimary(),
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
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _groupId = args?['groupId'] as int?;
    final group = args?['group'];
    if (group is GroupDTO) {
      _group = group;
    }
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    if (_groupId == null) {
      setState(() {
        _isRefreshing = false;
        _error = EmptyStateUxStrings.groupTargetMissingMessage;
      });
      return;
    }

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      final currentUserId = context.read<AuthProvider>().user?.id;
      final groupProvider = context.read<GroupProvider>();
      final response = await widget.api.getGroupById(_groupId!);
      await groupProvider.loadGroupMembers(_groupId!);
      final currentMember = _findCurrentMember(groupProvider, currentUserId);
      if ((currentMember?.role ?? 99) <= 2) {
        await groupProvider.loadJoinRequests(_groupId!);
      } else {
        groupProvider.clearJoinRequests();
      }

      if (!mounted) {
        return;
      }

      if (response.isSuccess && response.data != null) {
        setState(() {
          _group = response.data;
        });
      } else {
        setState(() {
          _error = response.message;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '加载群详情失败，请稍后重试。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openAddMemberDialog() async {
    if (_groupId == null || _isActionRunning) {
      return;
    }

    final keywordController = TextEditingController();
    String searchType = 'userId';
    String? error;
    bool isSearching = false;
    bool isSubmitting = false;
    UserDTO? searchedUser;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> searchUser() async {
              final keyword = keywordController.text.trim();
              if (keyword.isEmpty) {
                setDialogState(() {
                  error = SearchUxStrings.errorUserKeywordRequired;
                });
                return;
              }

              setDialogState(() {
                isSearching = true;
                error = null;
                searchedUser = null;
              });

              try {
                    final response = await widget.api.searchUser(
                      keyword,
                      type: searchType,
                    );
                setDialogState(() {
                  if (response.isSuccess) {
                    searchedUser = response.data;
                    if (searchedUser == null) {
                      error = SearchUxStrings.emptyNoResults;
                    }
                  } else {
                    error = SearchUxStrings.messageWhenSearchRequestFailed(
                      response.message,
                    );
                  }
                });
              } catch (_) {
                setDialogState(() {
                  error = SearchUxStrings.errorSearchFailed;
                });
              } finally {
                setDialogState(() {
                  isSearching = false;
                });
              }
            }

            Future<void> submit() async {
              if (searchedUser?.id == null) {
                setDialogState(() {
                  error = SearchUxStrings.errorMemberSearchFirst;
                });
                return;
              }

              final dialogNavigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(this.context);

              setDialogState(() {
                isSubmitting = true;
                error = null;
              });

              final groupProvider = context.read<GroupProvider>();
              final success =
                  await groupProvider.addGroupMember(_groupId!, searchedUser!.id!);

              if (!mounted) {
                return;
              }

              if (success) {
                if (!dialogContext.mounted) {
                  return;
                }
                dialogNavigator.pop();
                _loadGroupData();
                messenger.showSnackBar(
                  const SnackBar(content: Text(FeedbackUxStrings.snackMemberAdded)),
                );
              } else {
                setDialogState(() {
                  error = FeedbackUxStrings.messageOrFallback(
                    groupProvider.error,
                    FeedbackUxStrings.fallbackOperationFailed,
                  );
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              shape: ImTemplateShell.dialogShape,
              insetPadding: ImTemplateShell.dialogInsetPadding,
              title: const ImDialogTitle('添加成员'),
              titlePadding: ImTemplateShell.dialogTitlePadding,
              contentPadding: ImTemplateShell.dialogContentPadding,
              actionsPadding: ImTemplateShell.dialogActionsPadding,
              actionsAlignment: MainAxisAlignment.end,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: searchType,
                      decoration: ImTemplateShell.dialogFieldDecoration(
                        label: '搜索方式',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'userId',
                          child: Text('用户号'),
                        ),
                        DropdownMenuItem(
                          value: 'phone',
                          child: Text('手机号'),
                        ),
                      ],
                      onChanged: isSearching
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  searchType = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: ImTemplateShell.elementGapMd),
                    TextField(
                      controller: keywordController,
                      decoration: ImTemplateShell.dialogFieldDecoration(
                        label: '搜索关键词',
                        hint: SearchUxStrings.keywordHintForUserSearch(
                          searchType,
                        ),
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
                                onPressed: searchUser,
                                icon: const Icon(Icons.search),
                              ),
                      ),
                      onSubmitted: (_) => searchUser(),
                    ),
                    if (searchedUser != null) ...[
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: searchedUser!.id == null
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  this.context,
                                  '/user-detail',
                                  arguments: <String, dynamic>{
                                    'userId': searchedUser!.id,
                                    'user': searchedUser,
                                  },
                                );
                              },
                        leading: ProfileCircleAvatar(
                          title: ProfileDisplayTexts.displayName(searchedUser!),
                          avatarRaw: searchedUser!.avatar,
                        ),
                        title: Text(
                          ProfileDisplayTexts.displayName(searchedUser!),
                        ),
                        subtitle: Text(
                          '用户号：${ProfileDisplayTexts.accountIdLine(searchedUser!.userId)}',
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
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(FeedbackUxStrings.actionCancel),
                ),
                FilledButton(
                  style: UiTokens.filledPrimary(),
                  onPressed: isSubmitting ? null : submit,
                  child: Text(
                    isSubmitting
                        ? FeedbackUxStrings.buttonAddingInProgress
                        : FeedbackUxStrings.buttonConfirmAddMember,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeMember(GroupMemberDTO member) async {
    if (_groupId == null || member.userId == null || _isActionRunning) {
      return;
    }

    final String who = ProfileDisplayTexts.groupMemberTitle(member);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: ImTemplateShell.dialogShape,
          insetPadding: ImTemplateShell.dialogInsetPadding,
          title: const ImDialogTitle(FeedbackUxStrings.dialogTitleRemoveMember),
          titlePadding: ImTemplateShell.dialogTitlePadding,
          contentPadding: ImTemplateShell.dialogContentPadding,
          content: Text(
            '将「$who」从本群移出？对方可再次通过入群流程加入（若群内规则允许）。',
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
                FeedbackUxStrings.actionCancel,
                style: TextStyle(color: UiTokens.textSecondary),
              ),
            ),
            FilledButton(
              style: UiTokens.filledDanger(),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(FeedbackUxStrings.dialogActionRemoveFromGroup),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isActionRunning = true;
    });

    final groupProvider = context.read<GroupProvider>();
    final success =
        await groupProvider.removeGroupMember(_groupId!, member.userId!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isActionRunning = false;
    });

    final message = success
        ? '已将「$who」移出群组'
        : FeedbackUxStrings.messageOrFallback(
            groupProvider.error,
            FeedbackUxStrings.fallbackOperationFailed,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    if (success) {
      _loadGroupData();
    }
  }

  Future<void> _quitGroup() async {
    if (_groupId == null || _isActionRunning) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: ImTemplateShell.dialogShape,
          insetPadding: ImTemplateShell.dialogInsetPadding,
          title: const ImDialogTitle(FeedbackUxStrings.dialogTitleQuitGroup),
          titlePadding: ImTemplateShell.dialogTitlePadding,
          contentPadding: ImTemplateShell.dialogContentPadding,
          content: Text(
            '退出后你将不再是本群成员；群聊记录是否保留以服务端规则为准。此操作不会解散群聊。',
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
                FeedbackUxStrings.actionCancel,
                style: TextStyle(color: UiTokens.textSecondary),
              ),
            ),
            FilledButton(
              style: UiTokens.filledDanger(),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(FeedbackUxStrings.dialogActionQuitGroup),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isActionRunning = true;
    });

    final groupProvider = context.read<GroupProvider>();
    final success = await groupProvider.quitGroup(_groupId!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isActionRunning = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(FeedbackUxStrings.snackQuitGroupDone)),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          FeedbackUxStrings.messageOrFallback(
            groupProvider.error,
            FeedbackUxStrings.fallbackQuitGroupFailed,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, GroupDTO group) {
    final String desc = (group.description ?? '').trim();
    final String? notice =
        (group.notice ?? '').trim().isEmpty ? null : group.notice!.trim();
    final meta = <String>[
      if (group.maxMembers != null) '人数上限 ${group.maxMembers}',
      if (group.allowMemberInvite == false) '已关闭成员邀请',
      if ((group.joinType ?? 0) == 1 || group.needVerify == true)
        '入群需管理员确认',
      if (group.isMute == true) '全体禁言中',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WxListGroup(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ProfileCircleAvatar(
                title: group.groupName ?? '群',
                avatarRaw: group.avatar,
                size: 56,
                fontSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      group.groupName ?? '未命名群组',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.memberCount != null
                          ? '共 ${group.memberCount} 人'
                          : '群聊',
                      style: TextStyle(
                        fontSize: 13,
                        color: CommonTokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (meta.isNotEmpty || desc.isNotEmpty || (notice ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildGroupContextBelowHero(
              meta: meta,
              description: desc,
              notice: notice,
            ),
          ),
      ],
    );
  }

  Widget _buildGroupContextBelowHero({
    required List<String> meta,
    required String description,
    String? notice,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (meta.isNotEmpty)
          Wrap(
            spacing: UiTokens.space8,
            runSpacing: UiTokens.space8,
            children: meta
                .map(
                  (String item) => BadgeTag(
                    label: item,
                    backgroundColor: GroupUiTokens.chipBackground,
                    textColor: GroupUiTokens.chipText,
                  ),
                )
                .toList(),
          ),
        if (description.isNotEmpty) ...<Widget>[
          if (meta.isNotEmpty) SizedBox(height: ImDesignTokens.spaceSm),
          Text(
            description,
            style: TextStyle(
              color: UiTokens.textSecondary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if ((notice ?? '').isNotEmpty) ...<Widget>[
          if (meta.isNotEmpty || description.isNotEmpty)
            SizedBox(height: ImDesignTokens.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.campaign_outlined,
                size: 18,
                color: UiTokens.textSecondary,
              ),
              const SizedBox(width: UiTokens.space8),
              Expanded(
                child: Text(
                  notice!,
                  style: TextStyle(
                    color: UiTokens.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 弱视觉功能区：编辑 / 添加成员（横向，非独立重卡片）。
  Widget _buildFunctionWeakRow({
    required bool isOwner,
    required bool canInviteMembers,
    required bool isMember,
  }) {
    final bool showEdit = isOwner;
    final bool showAdd = isMember && canInviteMembers;
    if (!showEdit && !showAdd) {
      return const SizedBox.shrink();
    }
    return WxListGroup(
      child: Row(
        children: <Widget>[
          if (showEdit)
            Expanded(
              child: TextButton.icon(
                onPressed: _isActionRunning ? null : _editGroupInfo,
                icon: Icon(Icons.edit_outlined, size: ImDesignTokens.iconSm),
                label: const Text('编辑资料'),
              ),
            ),
          if (showEdit && showAdd)
            SizedBox(
              height: 36,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: CommonTokens.lineSubtle,
              ),
            ),
          if (showAdd)
            Expanded(
              child: TextButton.icon(
                onPressed: _isActionRunning ? null : _openAddMemberDialog,
                icon: Icon(
                  Icons.person_add_alt_1_outlined,
                  size: ImDesignTokens.iconSm,
                ),
                label: const Text('添加成员'),
              ),
            ),
        ],
      ),
    );
  }

  Color _roleChipBackground(int? role) {
    return switch (role) {
      1 => GroupUiTokens.chipAccentBackground,
      2 => const Color(0xFFE8EEF9),
      _ => GroupUiTokens.chipBackground,
    };
  }

  Color _roleChipForeground(int? role) {
    return switch (role) {
      1 => GroupUiTokens.chipAccentText,
      2 => GroupUiTokens.settingIconColor,
      _ => GroupUiTokens.chipText,
    };
  }

  Widget _buildDangerArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '危险操作',
            style: CommonTokens.caption.copyWith(
              color: CommonTokens.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        WxListGroup(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '退出后将失去本群成员身份。',
                style: GroupUiTokens.sectionSubtitleText.copyWith(
                  color: UiTokens.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isActionRunning ? null : _quitGroup,
                  style: UiTokens.filledDanger(),
                  child: const Text('退出群组'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryChatSection(
    GroupDTO group, {
    required bool isMember,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          onPressed: isMember
              ? () {
                  final int? gid = group.id;
                  if (gid == null) {
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: GroupChatScreen.navigationArguments(
                      targetId: gid,
                      title: group.groupName ?? '未命名群组',
                    ),
                  );
                }
              : _requestToJoinGroup,
          icon: Icon(
            isMember ? Icons.chat_bubble_outline : Icons.how_to_reg,
            size: ImDesignTokens.iconMd,
          ),
          label: Text(isMember ? '进入聊天' : '申请加入'),
          style: UiTokens.filledPrimary(),
        ),
        if (isMember && group.id != null) ...<Widget>[
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () {
                openChatHistorySearch(
                  context,
                  targetId: group.id!,
                  type: 2,
                );
              },
              child: Text(
                SearchUxStrings.hintChatHistory,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: UiTokens.textSecondary,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: UiTokens.space12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: UiTokens.space8,
          runSpacing: 0,
          children: <Widget>[
            TextButton(
              onPressed: _isActionRunning ? null : _reportGroup,
              child: Text(
                '举报群组',
                style: TextStyle(
                  color: UiTokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!isMember)
              TextButton(
                onPressed: _loadGroupData,
                child: Text(
                  '刷新群信息',
                  style: TextStyle(
                    color: UiTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerTools(BuildContext context, GroupDTO group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        WxSectionTitle(
          '群管理',
          padding: const EdgeInsets.only(left: 4, bottom: 8),
        ),
        WxListGroup(
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: const Text('全体禁言'),
            subtitle: Text(
              '普通成员禁言（群主/管理员除外）',
              style: TextStyle(
                fontSize: 12,
                color: UiTokens.textSecondary,
              ),
            ),
            value: group.isMute ?? false,
            onChanged: _isActionRunning ? null : _toggleGroupMute,
          ),
        ),
      ],
    );
  }

  Widget _buildJoinRequestSection(BuildContext context, GroupProvider groupProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        WxSectionTitle(
          '入群申请',
          padding: const EdgeInsets.only(left: 4, bottom: 8),
        ),
        WxListGroup(
          child: groupProvider.joinRequests.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        EmptyStateUxStrings.groupPendingJoinRequestsEmptyTitle,
                        style: GroupUiTokens.memberNameText.copyWith(
                          color: GroupUiTokens.chipText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        EmptyStateUxStrings.groupPendingJoinRequestsEmptyDetail,
                        style: GroupUiTokens.sectionSubtitleText.copyWith(
                          color: GroupUiTokens.chipText,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: groupProvider.joinRequests
                      .map(
                        (GroupJoinRequestDTO request) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              onTap: request.userId == null
                  ? null
                  : () {
                      final UserDTO? snapshot =
                          ProfileDisplayTexts.userDetailSnapshotFromApplicant(
                        userId: request.userId,
                        userInfo: request.userInfo,
                      );
                      final Map<String, dynamic> args = <String, dynamic>{
                        'userId': request.userId,
                      };
                      if (snapshot != null) {
                        args['user'] = snapshot;
                      }
                      Navigator.pushNamed(
                        context,
                        '/user-detail',
                        arguments: args,
                      );
                    },
              leading: ProfileCircleAvatar(
                title:
                    ProfileDisplayTexts.joinRequestApplicantTitle(request),
                avatarRaw: request.userInfo?.avatar,
              ),
              title: Text(
                ProfileDisplayTexts.joinRequestApplicantTitle(request),
              ),
              subtitle: Text(
                ProfileDisplayTexts.joinRequestApplicantSubtitle(
                  userInfo: request.userInfo,
                  userIdFallback: request.userId,
                  message: request.message,
                ),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _isActionRunning || request.id == null
                        ? null
                        : () => _reviewJoinRequest(request, false),
                    child: const Text('拒绝'),
                  ),
                  FilledButton(
                    style: UiTokens.filledPrimary(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _isActionRunning || request.id == null
                        ? null
                        : () => _reviewJoinRequest(request, true),
                    child: const Text('同意'),
                  ),
                ],
              ),
            )
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(
    BuildContext context, {
    required GroupProvider groupProvider,
    required int? currentRole,
    required int? currentUserId,
    required bool isOwner,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        WxSectionTitle(
          '成员列表',
          padding: const EdgeInsets.only(left: 4, bottom: 8),
        ),
        WxListGroup(
          child: groupProvider.groupMembers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        EmptyStateUxStrings.groupMembersEmptyTitle,
                        style: GroupUiTokens.memberNameText.copyWith(
                          color: GroupUiTokens.chipText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        EmptyStateUxStrings.groupMembersEmptyDetail,
                        style: GroupUiTokens.sectionSubtitleText.copyWith(
                          color: GroupUiTokens.chipText,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int i = 0;
                        i < groupProvider.groupMembers.length;
                        i++) ...<Widget>[
                      _buildMemberTile(
                        groupProvider.groupMembers[i],
                        canManage: _canManageMember(
                          currentRole,
                          groupProvider.groupMembers[i],
                          currentUserId,
                        ),
                        isOwner: isOwner,
                      ),
                      if (i < groupProvider.groupMembers.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: CommonTokens.lineSubtle,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  static const double _groupMemberAvatarSize = 40;

  Widget _groupMemberListAvatar(BuildContext context, GroupMemberDTO member) {
    return ProfileCircleAvatar(
      title: ProfileDisplayTexts.groupMemberTitle(member),
      avatarRaw: member.userInfo?.avatar,
      size: _groupMemberAvatarSize,
    );
  }

  Widget _buildMemberTile(
    GroupMemberDTO member, {
    required bool canManage,
    required bool isOwner,
  }) {
    return ListTile(
      onTap: member.userId == null
          ? null
          : () {
              final UserDTO? snapshot =
                  ProfileDisplayTexts.userDetailSnapshotFromGroupMember(member);
              final Map<String, dynamic> args = <String, dynamic>{
                'userId': member.userId,
              };
              if (snapshot != null) {
                args['user'] = snapshot;
              }
              Navigator.pushNamed(
                context,
                '/user-detail',
                arguments: args,
              );
            },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      visualDensity: VisualDensity.compact,
      leading: _groupMemberListAvatar(context, member),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              ProfileDisplayTexts.groupMemberTitle(member),
              style: GroupUiTokens.memberNameText,
            ),
          ),
          const SizedBox(width: 8),
          BadgeTag(
            label: ProfileDisplayTexts.groupMemberRoleLabel(member.role),
            backgroundColor: _roleChipBackground(member.role),
            textColor: _roleChipForeground(member.role),
          ),
        ],
      ),
      subtitle: Text(
        ProfileDisplayTexts.groupMemberListSubtitle(member),
        style: GroupUiTokens.memberRoleText,
      ),
      trailing: canManage
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mute') {
                  _toggleMemberMute(member);
                } else if (value == 'admin') {
                  _toggleMemberAdmin(member);
                } else if (value == 'transfer') {
                  _transferOwnership(member);
                } else if (value == 'remove') {
                  _removeMember(member);
                }
              },
              itemBuilder: (context) => [
                if (isOwner && member.role != 1)
                  PopupMenuItem(
                    value: 'admin',
                    child: Text(
                      member.role == 2
                          ? '取消管理员'
                          : '设为管理员',
                    ),
                  ),
                PopupMenuItem(
                  value: 'mute',
                  child: Text(
                    (member.isMute ?? false)
                        ? '解除禁言'
                        : '设置禁言',
                  ),
                ),
                if (isOwner && member.role != 1)
                  const PopupMenuItem(
                    value: 'transfer',
                    child: Text('转让群主'),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('移除成员'),
                ),
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final authProvider = context.watch<AuthProvider>();
    final group = _group;
    final currentUserId = authProvider.user?.id;
    final currentMember = _findCurrentMember(groupProvider, currentUserId);
    final currentRole = currentMember?.role;
    final isMember = currentMember != null;
    final isOwner = currentRole == 1 || group?.ownerId == currentUserId;
    final canInviteMembers =
        currentRole != null && (currentRole <= 2 || group?.allowMemberInvite == true);
    final canReviewJoinRequests = currentRole != null && currentRole <= 2;

    return Scaffold(
      backgroundColor: UiTokens.backgroundGray,
      appBar: AppBar(
        title: const Text('群信息'),
        backgroundColor: UiTokens.backgroundGray,
        foregroundColor: UiTokens.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isRefreshing
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                  ),
                )
              : group == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              EmptyStateUxStrings.groupInfoNotLoadedTitle,
                              textAlign: TextAlign.center,
                              style: GroupUiTokens.memberNameText.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              EmptyStateUxStrings.groupInfoNotLoadedDetail,
                              textAlign: TextAlign.center,
                              style: GroupUiTokens.sectionSubtitleText.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadGroupData,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ImTemplateShell.pagePaddingH,
                          vertical: ImTemplateShell.pagePaddingV,
                        ),
                        children: [
                          _buildGroupHeader(context, group),
                          const SizedBox(height: ImTemplateShell.sectionGap),
                          _buildFunctionWeakRow(
                            isOwner: isOwner,
                            canInviteMembers: canInviteMembers,
                            isMember: isMember,
                          ),
                          const SizedBox(height: ImTemplateShell.sectionGap),
                          _buildPrimaryChatSection(
                            group,
                            isMember: isMember,
                          ),
                          if (isOwner) ...[
                            const SizedBox(height: UiTokens.space16),
                            _buildOwnerTools(context, group),
                          ],
                          if (canReviewJoinRequests && (group.joinType ?? 0) == 1) ...[
                            const SizedBox(height: UiTokens.space16),
                            _buildJoinRequestSection(context, groupProvider),
                          ],
                          const SizedBox(height: UiTokens.space16),
                          _buildMembersSection(
                            context,
                            groupProvider: groupProvider,
                            currentRole: currentRole,
                            currentUserId: currentUserId,
                            isOwner: isOwner,
                          ),
                          if (isMember) ...<Widget>[
                            const SizedBox(height: UiTokens.space20),
                            _buildDangerArea(),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
