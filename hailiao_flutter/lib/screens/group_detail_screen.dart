import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
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

    final nameController = TextEditingController(text: _group!.groupName ?? '');
    final descriptionController =
        TextEditingController(text: _group!.description ?? '');
    final noticeController = TextEditingController(text: _group!.notice ?? '');
    bool allowMemberInvite = _group!.allowMemberInvite ?? true;
    int joinType = _group!.joinType ?? ((_group!.needVerify ?? false) ? 1 : 0);
    String? error;
    bool isSubmitting = false;

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

              final dialogNavigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(this.context);

              setDialogState(() {
                isSubmitting = true;
                error = null;
              });

              final groupProvider = context.read<GroupProvider>();
              final success = await groupProvider.updateGroup(_groupId!, {
                'groupName': nameController.text.trim(),
                'description': descriptionController.text.trim(),
                'notice': noticeController.text.trim(),
                'allowMemberInvite': allowMemberInvite,
                'joinType': joinType,
              });

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
                  const SnackBar(content: Text('群资料已更新')),
                );
              } else {
                setDialogState(() {
                  error = groupProvider.error ?? '更新群资料失败';
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('编辑群资料'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '群名称'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '群简介',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noticeController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '群公告',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('允许成员申请'),
                      subtitle: const Text('关闭后，只有群主或管理员可添加成员'),
                      value: allowMemberInvite,
                      onChanged: (value) {
                        setDialogState(() {
                          allowMemberInvite = value;
                        });
                      },
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      initialValue: joinType,
                      decoration: const InputDecoration(
                        labelText: '入群方式',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('允许直接加入'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('需要管理员确认'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            joinType = value;
                          });
                        }
                      },
                    ),
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
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isSubmitting ? '保存中...' : '保存'),
                ),
              ],
            );
          },
        );
      },
    );
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
            ? '已开启全体静音'
            : '已关闭全体静音')
        : (groupProvider.error ?? '群静音设置失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleMemberMute(GroupMemberDTO member) async {
    if (_groupId == null || member.userId == null || _isActionRunning) {
      return;
    }

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
            ? '已对成员禁言'
            : '已解除成员禁言')
        : (groupProvider.error ?? '成员禁言设置失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleMemberAdmin(GroupMemberDTO member) async {
    if (_groupId == null || member.userId == null || _isActionRunning) {
      return;
    }

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
            ? '已设为管理员'
            : '已取消管理员')
        : (groupProvider.error ?? '管理员设置失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _transferOwnership(GroupMemberDTO member) async {
    if (_groupId == null || member.userId == null || _isActionRunning) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('转让群主'),
          content: Text(
            '确认将群主身份转让给 ${member.userInfo?.nickname ?? member.nickname ?? '该成员'} 吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认转让'),
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
        ? '群主已转让'
        : (groupProvider.error ?? '群主转让失败');
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
                  error = groupProvider.error ?? '入群申请提交失败';
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('申请加入群组'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '申请信息',
                      hintText: '可以填写你的来意',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
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
                    isSubmitting ? '提交中...' : '提交申请',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reviewJoinRequest(int requestId, bool approve) async {
    if (_groupId == null || _isActionRunning) {
      return;
    }

    setState(() {
      _isActionRunning = true;
    });

    final groupProvider = context.read<GroupProvider>();
    final success =
        await groupProvider.reviewJoinRequest(requestId, approve: approve);

    if (!mounted) {
      return;
    }

    setState(() {
      _isActionRunning = false;
    });

    final message = success
        ? (approve
            ? '已同意入群申请'
            : '已拒绝入群申请')
        : (groupProvider.error ?? '入群申请处理失败');
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
                    error = response.message;
                    isSubmitting = false;
                  });
                }
              } catch (_) {
                setDialogState(() {
                  error = '提交群组举报失败';
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('举报群组'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      decoration: const InputDecoration(
                        labelText: '举报原因',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: evidenceController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '补充说明',
                        hintText: '可以简要描述问题',
                        alignLabelWithHint: true,
                      ),
                    ),
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
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(
                    isSubmitting ? '提交中...' : '提交举报',
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
        _error = '缺少群组信息。';
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
                  error = '请输入用户号或手机号';
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
                  } else {
                    error = response.message;
                  }
                });
              } catch (_) {
                setDialogState(() {
                  error = '搜索失败，请稍后重试';
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
                  error = '请先搜索成员';
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
                  const SnackBar(content: Text('成员已添加')),
                );
              } else {
                setDialogState(() {
                  error = groupProvider.error ?? '添加成员失败';
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('添加成员'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: searchType,
                      decoration: const InputDecoration(
                        labelText: '搜索方式',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: keywordController,
                      decoration: InputDecoration(
                        labelText: '搜索关键词',
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
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          searchedUser!.nickname ?? '未设置昵称',
                        ),
                        subtitle: Text(
                          '用户号：${searchedUser!.userId ?? '-'}',
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
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(
                    isSubmitting ? '添加中...' : '确认添加',
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('移除成员'),
          content: Text(
            '确定移除 ${member.userInfo?.nickname ?? member.nickname ?? '该成员'} 吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认'),
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
        ? '成员已移除'
        : (groupProvider.error ?? '移除成员失败');
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
          title: const Text('退出群组'),
          content: const Text('退出后，你将从成员列表中移除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认退出'),
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
        const SnackBar(content: Text('已退出群组')),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(groupProvider.error ?? '退出群组失败')),
    );
  }

  Widget _buildGroupHeader(GroupDTO group) {
    final meta = <String>[
      if (group.memberCount != null) '${group.memberCount}人',
      if (group.maxMembers != null) '上限 ${group.maxMembers}',
      if (group.allowMemberInvite == false) '限制成员邀请',
      if ((group.joinType ?? 0) == 1 || group.needVerify == true) '入群需验证',
      if ((group.notice ?? '').isNotEmpty) '有公告',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Icon(Icons.groups, size: 32, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            group.groupName ?? '未命名群组',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meta.join(' | '),
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          ],
          if ((group.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              group.description!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          ],
          if ((group.notice ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '群公告：${group.notice!}',
                style: const TextStyle(color: Color(0xFF333333)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupActions(
    GroupDTO group, {
    required bool canInviteMembers,
    required bool isOwner,
    required bool isMember,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isMember
                    ? () {
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {
                            'targetId': group.id,
                            'type': 2,
                            'title': group.groupName ?? '群聊',
                          },
                        );
                      }
                    : _requestToJoinGroup,
                icon: Icon(isMember ? Icons.chat_bubble_outline : Icons.how_to_reg),
                label: Text(isMember ? '进入聊天' : '申请加入'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isMember
                    ? (canInviteMembers ? _openAddMemberDialog : _quitGroup)
                    : _loadGroupData,
                icon: Icon(
                  isMember
                      ? (canInviteMembers
                          ? Icons.person_add_alt_1
                          : Icons.exit_to_app)
                      : Icons.refresh,
                ),
                label: Text(
                  isMember
                      ? (canInviteMembers ? '添加成员' : '退出群组')
                      : '刷新',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isActionRunning ? null : _reportGroup,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('举报群组'),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerTools(GroupDTO group) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '群管理',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined),
            title: const Text('编辑群资料'),
            subtitle: const Text('修改群名称、群介绍和群公告'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isActionRunning ? null : _editGroupInfo,
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('全员静音'),
            subtitle: const Text('开启后，普通成员将受到发言限制'),
            value: group.isMute ?? false,
            onChanged: _isActionRunning ? null : _toggleGroupMute,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRequestSection(GroupProvider groupProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '入群申请',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          if (groupProvider.joinRequests.isEmpty)
            const Text(
              '暂无待处理申请',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            )
          else
            ...groupProvider.joinRequests.map(
              (request) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  request.userInfo?.nickname ?? '未知用户',
                ),
                subtitle: Text(
                  [
                    if ((request.userInfo?.userId ?? '').isNotEmpty)
                      '用户号 ${request.userInfo!.userId}',
                    if ((request.message ?? '').isNotEmpty) request.message!,
                  ].join(' | '),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _isActionRunning || request.id == null
                          ? null
                          : () => _reviewJoinRequest(request.id!, false),
                      child: const Text('拒绝'),
                    ),
                    ElevatedButton(
                      onPressed: _isActionRunning || request.id == null
                          ? null
                          : () => _reviewJoinRequest(request.id!, true),
                      child: const Text('同意'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    GroupMemberDTO member, {
    required bool canManage,
    required bool isOwner,
  }) {
    final roleLabel = switch (member.role) {
      1 => '群主',
      2 => '管理员',
      _ => '成员',
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Icon(Icons.person, color: Theme.of(context).primaryColor),
      ),
      title: Text(member.userInfo?.nickname ?? member.nickname ?? '未知成员'),
      subtitle: Text(
        [roleLabel, if (member.isMute == true) '已被禁言'].join(' | '),
      ),
      trailing: canManage && member.role != 2
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
      appBar: AppBar(title: const Text('群组详情')),
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
                  ? const Center(child: Text('暂无群组信息'))
                  : RefreshIndicator(
                      onRefresh: _loadGroupData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildGroupHeader(group),
                          const SizedBox(height: 16),
                          _buildGroupActions(
                            group,
                            canInviteMembers: canInviteMembers,
                            isOwner: isOwner,
                            isMember: isMember,
                          ),
                          if (isOwner) ...[
                            const SizedBox(height: 16),
                            _buildOwnerTools(group),
                          ],
                          if (canReviewJoinRequests && (group.joinType ?? 0) == 1) ...[
                            const SizedBox(height: 16),
                            _buildJoinRequestSection(groupProvider),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '成员列表',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (groupProvider.groupMembers.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      '暂无成员',
                                      style: TextStyle(color: Color(0xFF9E9E9E)),
                                    ),
                                  )
                                else
                                  ...groupProvider.groupMembers.map(
                                    (member) => _buildMemberTile(
                                      member,
                                      canManage: _canManageMember(
                                        currentRole,
                                        member,
                                        currentUserId,
                                      ),
                                      isOwner: isOwner,
                                    ),
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
