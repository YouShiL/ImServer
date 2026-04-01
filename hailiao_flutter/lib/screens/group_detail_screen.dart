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
                Navigator.of(dialogContext).pop();
                _loadGroupData();
                ScaffoldMessenger.of(context).showSnackBar(
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
                      value: joinType,
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
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
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
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
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
                      value: selectedReason,
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
      final groupProvider = context.read<GroupProvider>();
      final response = await widget.api.getGroupById(_groupId!);
      await groupProvider.loadGroupMembers(_groupId!);
      final currentUserId = context.read<AuthProvider>().user?.id;
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
                Navigator.of(dialogContext).pop();
                _loadGroupData();
                ScaffoldMessenger.of(context).showSnackBar(
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
                      value: searchType,
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
                              Theme.of(context).primaryColor.withOpacity(0.1),
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
          title: const Text('\u79fb\u9664\u6210\u5458'),
          content: Text(
            '\u786e\u5b9a\u79fb\u9664 ${member.userInfo?.nickname ?? member.nickname ?? '\u8be5\u6210\u5458'} \u5417\uff1f',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('\u786e\u8ba4'),
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
        ? '\u6210\u5458\u5df2\u79fb\u9664'
        : (groupProvider.error ?? '\u79fb\u9664\u6210\u5458\u5931\u8d25');
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
          title: const Text('\u9000\u51fa\u7fa4\u7ec4'),
          content: const Text('\u9000\u51fa\u540e\uff0c\u4f60\u5c06\u4ece\u6210\u5458\u5217\u8868\u4e2d\u79fb\u9664\u3002'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('\u786e\u8ba4\u9000\u51fa'),
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
        const SnackBar(content: Text('\u5df2\u9000\u51fa\u7fa4\u7ec4')),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(groupProvider.error ?? '\u9000\u51fa\u7fa4\u7ec4\u5931\u8d25')),
    );
  }

  Widget _buildGroupHeader(GroupDTO group) {
    final meta = <String>[
      if (group.memberCount != null) '${group.memberCount}\u4eba',
      if (group.maxMembers != null) '\u4e0a\u9650 ${group.maxMembers}',
      if (group.allowMemberInvite == false) '\u9650\u5236\u6210\u5458\u9080\u8bf7',
      if ((group.joinType ?? 0) == 1 || group.needVerify == true) '\u5165\u7fa4\u9700\u9a8c\u8bc1',
      if ((group.notice ?? '').isNotEmpty) '\u6709\u516c\u544a',
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
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(Icons.groups, size: 32, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            group.groupName ?? '\u672a\u547d\u540d\u7fa4\u7ec4',
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
                '\u7fa4\u516c\u544a\uff1a${group.notice!}',
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
                            'title': group.groupName ?? '\u7fa4\u804a',
                          },
                        );
                      }
                    : _requestToJoinGroup,
                icon: Icon(isMember ? Icons.chat_bubble_outline : Icons.how_to_reg),
                label: Text(isMember ? '\u8fdb\u5165\u804a\u5929' : '\u7533\u8bf7\u52a0\u5165'),
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
                      ? (canInviteMembers ? '\u6dfb\u52a0\u6210\u5458' : '\u9000\u51fa\u7fa4\u7ec4')
                      : '\u5237\u65b0',
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
            label: const Text('\u4e3e\u62a5\u7fa4\u7ec4'),
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
            '\u7fa4\u7ba1\u7406',
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
            title: const Text('\u7f16\u8f91\u7fa4\u8d44\u6599'),
            subtitle: const Text('\u4fee\u6539\u7fa4\u540d\u79f0\u3001\u7fa4\u4ecb\u7ecd\u548c\u7fa4\u516c\u544a'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isActionRunning ? null : _editGroupInfo,
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('\u5168\u5458\u9759\u97f3'),
            subtitle: const Text('\u5f00\u542f\u540e\uff0c\u666e\u901a\u6210\u5458\u5c06\u53d7\u5230\u53d1\u8a00\u9650\u5236'),
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
            '\u5165\u7fa4\u7533\u8bf7',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          if (groupProvider.joinRequests.isEmpty)
            const Text(
              '\u6682\u65e0\u5f85\u5904\u7406\u7533\u8bf7',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            )
          else
            ...groupProvider.joinRequests.map(
              (request) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  request.userInfo?.nickname ?? '\u672a\u77e5\u7528\u6237',
                ),
                subtitle: Text(
                  [
                    if ((request.userInfo?.userId ?? '').isNotEmpty)
                      '\u7528\u6237\u53f7 ${request.userInfo!.userId}',
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
                      child: const Text('\u62d2\u7edd'),
                    ),
                    ElevatedButton(
                      onPressed: _isActionRunning || request.id == null
                          ? null
                          : () => _reviewJoinRequest(request.id!, true),
                      child: const Text('\u540c\u610f'),
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
      1 => '\u7fa4\u4e3b',
      2 => '\u7ba1\u7406\u5458',
      _ => '\u6210\u5458',
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(Icons.person, color: Theme.of(context).primaryColor),
      ),
      title: Text(member.userInfo?.nickname ?? member.nickname ?? '\u672a\u77e5\u6210\u5458'),
      subtitle: Text(
        [roleLabel, if (member.isMute == true) '\u5df2\u88ab\u7981\u8a00'].join(' | '),
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
                          ? '取消\u7ba1\u7406\u5458'
                          : '\u8bbe\u4e3a\u7ba1\u7406\u5458',
                    ),
                  ),
                PopupMenuItem(
                  value: 'mute',
                  child: Text(
                    (member.isMute ?? false)
                        ? '\u89e3\u9664\u7981\u8a00'
                        : '\u8bbe\u7f6e\u7981\u8a00',
                  ),
                ),
                if (isOwner && member.role != 1)
                  const PopupMenuItem(
                    value: 'transfer',
                    child: Text('\u8f6c\u8ba9\u7fa4\u4e3b'),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('\u79fb\u9664\u6210\u5458'),
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
      appBar: AppBar(title: const Text('\u7fa4\u7ec4\u8be6\u60c5')),
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
                  ? const Center(child: Text('\u6682\u65e0\u7fa4\u7ec4\u4fe1\u606f'))
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
                                  '\u6210\u5458\u5217\u8868',
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
                                      '\u6682\u65e0\u6210\u5458',
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
