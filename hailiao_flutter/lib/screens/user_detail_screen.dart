import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
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
  Future<ResponseDTO<UserDTO>> getUserById(int userId) {
    return ApiService.getUserById(userId);
  }

  @override
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId) {
    return ApiService.getUserOnlineInfo(userId);
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

  FriendDTO? _findFriend(FriendProvider friendProvider, UserDTO user) {
    for (final friend in friendProvider.friends) {
      if (friend.friendId == user.id) {
        return friend;
      }
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    context.read<BlacklistProvider>().loadBlacklist();
    _readArguments();
    _loadUserDetail();
  }

  void _readArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _userId = args;
      return;
    }
    if (args is Map<String, dynamic>) {
      _userId = args['userId'] as int?;
      final user = args['user'];
      if (user is UserDTO) {
        _user = user;
      }
    }
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
      if (!mounted) {
        return;
      }
      if (response.isSuccess && response.data != null) {
        _user = response.data;
        await _loadPresence(_userId!);
      } else {
        _error = response.message;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _error = '加载用户资料失败，请稍后重试。';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPresence(int userId) async {
    try {
      final response = await widget.api.getUserOnlineInfo(userId);
      if (!mounted || !response.isSuccess || response.data == null) {
        return;
      }

      final data = response.data!;
      final isOnline = data['isOnline'] == true;
      final lastOnlineAt = data['lastOnlineAt']?.toString();

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
    } catch (_) {
      // Keep the detail page usable if presence loading fails.
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_user?.id == null || _isSubmitting) {
      return;
    }

    final remarkController = TextEditingController(
      text: _user?.nickname ?? _user?.userId ?? '',
    );
    final messageController = TextEditingController(
      text: '你好，我想加你为好友。',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加好友'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: remarkController,
                decoration: const InputDecoration(labelText: '备注'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '验证消息',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('发送'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final friendProvider = context.read<FriendProvider>();
    final success = await friendProvider.addFriend(
      _user!.id!,
      remarkController.text.trim(),
      message: messageController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    final message = success
        ? '好友申请已发送'
        : (friendProvider.error ?? '发送好友申请失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addToBlacklist() async {
    if (_user?.id == null || _isSubmitting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('加入黑名单'),
          content: const Text('加入后，你们将无法再互相发送好友申请。'),
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
      _isSubmitting = true;
    });

    final blacklistProvider = context.read<BlacklistProvider>();
    final success = await blacklistProvider.addToBlacklist(_user!.id!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    final message = success
        ? '已加入黑名单'
        : (blacklistProvider.error ?? '加入黑名单失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _removeFromBlacklist() async {
    if (_user?.id == null || _isSubmitting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('解除黑名单'),
          content: const Text('解除后，你们可以重新互相搜索或发送好友申请。'),
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
      _isSubmitting = true;
    });

    final blacklistProvider = context.read<BlacklistProvider>();
    final success = await blacklistProvider.removeFromBlacklist(_user!.id!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    final message = success
        ? '已解除黑名单'
        : (blacklistProvider.error ?? '解除黑名单失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _reportUser() async {
    if (_user?.id == null || _isSubmitting) {
      return;
    }

    final reasons = <String>[
      '\u9a9a\u6270\u6216\u8c29\u9a82',
      '\u8bc8\u9a97\u6216\u865a\u5047\u4fe1\u606f',
      '\u4e0d\u5f53\u5185\u5bb9',
      '\u5176\u4ed6',
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
                  _user!.id!,
                  1,
                  selectedReason,
                  evidence: evidenceController.text.trim(),
                );

                if (!mounted) {
                  return;
                }

                if (response.isSuccess) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('举报已提交')),
                  );
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

  Future<void> _updateFriendRemark(FriendDTO friend) async {
    if (_isSubmitting) {
      return;
    }

    final controller = TextEditingController(
      text: friend.remark ?? _user?.nickname ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('\u4fee\u6539\u5907\u6ce8'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '\u5907\u6ce8',
              hintText: '\u8bf7\u8f93\u5165\u597d\u53cb\u5907\u6ce8',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('\u4fdd\u5b58'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final friendProvider = context.read<FriendProvider>();
    final success = await friendProvider.updateFriendRemark(
      friend.friendId!,
      controller.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    final message = success
        ? '\u597d\u53cb\u5907\u6ce8\u5df2\u66f4\u65b0'
        : (friendProvider.error ?? '\u4fee\u6539\u5907\u6ce8\u5931\u8d25');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteFriend(FriendDTO friend) async {
    if (_isSubmitting || friend.friendId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('\u5220\u9664\u597d\u53cb'),
          content: const Text('\u5220\u9664\u540e\uff0c\u4f60\u4eec\u5c06\u9700\u8981\u91cd\u65b0\u53d1\u8d77\u597d\u53cb\u7533\u8bf7\u624d\u80fd\u6062\u590d\u5173\u7cfb\u3002'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认\u5220\u9664'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final friendProvider = context.read<FriendProvider>();
    final success = await friendProvider.deleteFriend(friend.friendId!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    final message = success
        ? '\u5df2\u5220\u9664\u597d\u53cb'
        : (friendProvider.error ?? '\u5220\u9664\u597d\u53cb\u5931\u8d25');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openChat() {
    if (_user?.id == null) {
      return;
    }
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'targetId': _user!.id,
        'type': 1,
        'title': _user!.nickname ?? _user!.userId ?? '\u804a\u5929',
      },
    );
  }

  Widget _buildHeader(UserDTO user) {
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
            backgroundImage: const AssetImage('assets/images/default_avatar.png'),
          ),
          const SizedBox(height: 16),
          Text(
            user.nickname ?? '\u672a\u8bbe\u7f6e\u6635\u79f0',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\u7528\u6237\u53f7\uff1a${user.userId ?? '-'}',
            style: const TextStyle(color: Color(0xFF666666)),
          ),
          if ((_statusText ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statusText!,
              style: const TextStyle(color: Color(0xFF1E88E5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserDTO user) {
    final rows = <MapEntry<String, String>>[
      MapEntry('\u6635\u79f0', user.nickname ?? '-'),
      MapEntry('\u7b7e\u540d', (user.signature ?? '').isNotEmpty ? user.signature! : '-'),
      MapEntry('\u5730\u533a', (user.region ?? '').isNotEmpty ? user.region! : '-'),
      MapEntry('\u624b\u673a\u53f7', (user.phone ?? '').isNotEmpty ? user.phone! : '\u672a\u516c\u5f00'),
      MapEntry('\u6700\u8fd1\u767b\u5f55', (user.lastLoginAt ?? '').isNotEmpty ? user.lastLoginAt! : '-'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        row.key,
                        style: const TextStyle(color: Color(0xFF9E9E9E)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(color: Color(0xFF333333)),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActions(UserDTO user) {
    final authProvider = context.watch<AuthProvider>();
    final blacklistProvider = context.watch<BlacklistProvider>();
    final friendProvider = context.watch<FriendProvider>();
    final isSelf = authProvider.user?.id == user.id;
    final friend = _findFriend(friendProvider, user);
    final isFriend = friend != null;
    final isBlocked = user.id != null && blacklistProvider.isBlocked(user.id!);

    if (isSelf) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting || isBlocked
                    ? null
                    : (isFriend ? _openChat : _sendFriendRequest),
                icon: Icon(isFriend ? Icons.chat_bubble_outline : Icons.person_add_alt_1),
                label: Text(
                  isBlocked
                      ? '\u5df2\u62c9\u9ed1'
                      : (isFriend ? '发送\u6d88\u606f' : '\u6dfb\u52a0\u597d\u53cb'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : (isBlocked ? _removeFromBlacklist : _addToBlacklist),
                icon: Icon(isBlocked ? Icons.undo : Icons.block_outlined),
                label: Text(isBlocked ? '\u89e3\u9664\u9ed1\u540d\u5355' : '\u52a0\u5165\u9ed1\u540d\u5355'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _reportUser,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('\u4e3e\u62a5\u7528\u6237'),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendManagement(FriendDTO friend) {
    final isBlocked =
        _user?.id != null && context.watch<BlacklistProvider>().isBlocked(_user!.id!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u597d\u53cb\u7ba1\u7406',
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
            title: const Text('\u4fee\u6539\u5907\u6ce8'),
            subtitle: Text(friend.remark ?? '\u6682\u672a\u8bbe\u7f6e\u5907\u6ce8'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isSubmitting || isBlocked
                ? null
                : () => _updateFriendRemark(friend),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
            title: const Text(
              '\u5220\u9664\u597d\u53cb',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
            subtitle: const Text('\u5220\u9664\u540e\u9700\u91cd\u65b0\u53d1\u8d77\u597d\u53cb\u7533\u8bf7'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isSubmitting ? null : () => _deleteFriend(friend),
          ),
          if (isBlocked) ...[
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                '\u5bf9\u65b9\u5df2\u5728\u9ed1\u540d\u5355\u4e2d\uff0c\u53d1\u6d88\u606f\u548c\u597d\u53cb\u64cd\u4f5c\u5df2\u53d7\u9650\u5236\u3002',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = context.watch<FriendProvider>();
    final currentFriend =
        _user == null ? null : _findFriend(friendProvider, _user!);

    return Scaffold(
      appBar: AppBar(title: const Text('\u7528\u6237\u8be6\u60c5')),
      body: _isLoading
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
              : _user == null
                  ? const Center(child: Text('暂无用户信息'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader(_user!),
                        const SizedBox(height: 16),
                        _buildActions(_user!),
                        const SizedBox(height: 16),
                        _buildInfoCard(_user!),
                        if (currentFriend != null) ...[
                          const SizedBox(height: 16),
                          _buildFriendManagement(currentFriend),
                        ],
                      ],
                    ),
    );
  }
}

