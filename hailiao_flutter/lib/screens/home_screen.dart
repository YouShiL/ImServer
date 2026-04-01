import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/qrcode_scanner_screen.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _conversationSearchController =
      TextEditingController();
  String _conversationQuery = '';
  String _conversationFilter = '全部';
  String _conversationSort = '智能排序';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadConversations();
      final friendProvider = context.read<FriendProvider>();
      friendProvider.loadFriends();
      friendProvider.loadFriendRequests();
    });
  }

  @override
  void dispose() {
    _conversationSearchController.dispose();
    super.dispose();
  }

  Future<void> _handleFriendRequest(int requestId, bool accept) async {
    final friendProvider = context.read<FriendProvider>();
    final success = accept
        ? await friendProvider.acceptFriendRequest(requestId)
        : await friendProvider.rejectFriendRequest(requestId);

    if (!mounted) {
      return;
    }

    final message = success
        ? (accept
            ? '已同意好友申请'
            : '已拒绝好友申请')
        : (friendProvider.error ?? '操作失败，请稍后重试');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updatePrivacySetting(
    String key,
    bool value, {
    required String successMessage,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserInfo({key: value});

    if (!mounted) {
      return;
    }

    final message = success
        ? successMessage
        : (authProvider.error ?? '设置更新失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _statusTextFromUser(UserDTO? user) {
    if (user == null) {
      return '状态未知';
    }
    if (user.showOnlineStatus == false) {
      return '在线状态已隐藏';
    }
    return (user.onlineStatus ?? 0) == 1 ? '在线' : '离线';
  }

  String _statusTextFromFriend(FriendDTO friend) {
    final info = friend.friendUserInfo;
    if (info?.showOnlineStatus == false) {
      return '在线状态已隐藏';
    }
    return (info?.onlineStatus ?? 0) == 1 ? '在线' : '离线';
  }

  Color _statusColor(bool isOnline) {
    return isOnline ? const Color(0xFF22C55E) : const Color(0xFF9E9E9E);
  }

  Widget _buildAvatar({double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/images/default_avatar.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: child,
    );
  }

  Future<void> _openAddFriendDialog() async {
    final keywordController = TextEditingController();
    final remarkController = TextEditingController();
    final messageController = TextEditingController(
      text: '你好，我想加你为好友。',
    );

    String searchType = 'userId';
    UserDTO? searchedUser;
    String? dialogError;
    bool isSearching = false;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> searchUser() async {
              final keyword = keywordController.text.trim();
              if (keyword.isEmpty) {
                setDialogState(() {
                  dialogError = '请输入用户号或手机号';
                });
                return;
              }

              setDialogState(() {
                isSearching = true;
                dialogError = null;
                searchedUser = null;
              });

              try {
                final response =
                    await ApiService.searchUser(keyword, type: searchType);
                setDialogState(() {
                  if (response.isSuccess) {
                    searchedUser = response.data;
                    if (searchedUser != null &&
                        remarkController.text.trim().isEmpty) {
                      remarkController.text =
                          searchedUser!.nickname ?? searchedUser!.userId ?? '';
                    }
                  } else {
                    dialogError = response.message;
                  }
                });
              } catch (_) {
                setDialogState(() {
                  dialogError = '搜索失败，请稍后重试';
                });
              } finally {
                setDialogState(() {
                  isSearching = false;
                });
              }
            }

            Future<void> submitRequest() async {
              if (searchedUser?.id == null) {
                setDialogState(() {
                  dialogError = '请先搜索用户';
                });
                return;
              }

              setDialogState(() {
                isSubmitting = true;
                dialogError = null;
              });

              final friendProvider = context.read<FriendProvider>();
              final success = await friendProvider.addFriend(
                searchedUser!.id!,
                remarkController.text.trim(),
                message: messageController.text.trim(),
              );

              if (!mounted) {
                return;
              }

              if (success) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('好友申请已发送'),
                  ),
                );
              } else {
                setDialogState(() {
                  dialogError =
                      friendProvider.error ?? '发送好友申请失败';
                });
              }

              if (mounted) {
                setDialogState(() {
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('添加好友'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        hintText: searchType == 'phone'
                            ? '请输入手机号'
                            : '请输入用户号',
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                      _buildSearchUserCard(searchedUser!),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarkController,
                        decoration: const InputDecoration(
                          labelText: '备注',
                        ),
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
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
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
                  onPressed: isSubmitting ? null : submitRequest,
                  child: Text(
                    isSubmitting
                        ? '发送中...'
                        : '发送申请',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchUserCard(UserDTO user) {
    final isOnline = (user.onlineStatus ?? 0) == 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.nickname ?? '未设置昵称',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text('用户号：${user.userId ?? '-'}'),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor(isOnline),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(_statusTextFromUser(user)),
            ],
          ),
          if ((user.signature ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.signature!,
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          ],
        ],
      ),
    );
  }

  bool _matchesConversationFilter(
    dynamic conversation,
    String draftText,
    bool hasUnread,
  ) {
    switch (_conversationFilter) {
      case '未读':
        return hasUnread;
      case '草稿':
        return draftText.isNotEmpty;
      case '置顶':
        return conversation.isTop == true;
      case '免打扰':
        return conversation.isMute == true;
      default:
        return true;
    }
  }

  List<dynamic> _filteredConversations(MessageProvider messageProvider) {
    final query = _conversationQuery.trim().toLowerCase();
    final items = messageProvider.conversations.where((conversation) {
      final hasUnread =
          conversation.unreadCount != null && conversation.unreadCount! > 0;
      final draft = messageProvider.getDraft(
        conversation.targetId,
        conversation.type,
      );
      final draftText = (draft?.trim().isNotEmpty == true
              ? draft!.trim()
              : (conversation.draft?.trim() ?? ''));
      if (!_matchesConversationFilter(conversation, draftText, hasUnread)) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack = [
        conversation.name ?? '',
        conversation.lastMessage ?? '',
        draftText,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    if (_conversationSort == '未读优先') {
      items.sort((a, b) {
        final unreadCompare =
            (b.unreadCount ?? 0).compareTo(a.unreadCount ?? 0);
        if (unreadCompare != 0) {
          return unreadCompare;
        }
        return (b.lastMessageTime ?? '').compareTo(a.lastMessageTime ?? '');
      });
    } else if (_conversationSort == '最近消息') {
      items.sort(
        (a, b) => (b.lastMessageTime ?? '').compareTo(a.lastMessageTime ?? ''),
      );
    } else if (_conversationSort == '名称排序') {
      items.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    }

    return items;
  }

  Widget _buildConversationStatChip(
    String label,
    String value, {
    Color valueColor = const Color(0xFF111827),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF4B5563),
          ),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab(MessageProvider messageProvider) {
    if (messageProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    if (messageProvider.conversations.isEmpty) {
      return const _EmptyState(
        icon: Icons.chat_bubble_outline,
        text: '暂无消息',
      );
    }

    final filteredConversations = _filteredConversations(messageProvider);
    final totalCount = messageProvider.conversations.length;
    final unreadCount = messageProvider.conversations
        .where((item) => (item.unreadCount ?? 0) > 0)
        .length;
    final draftCount = messageProvider.conversations.where((conversation) {
      final draft = messageProvider.getDraft(
        conversation.targetId,
        conversation.type,
      );
      final draftText = (draft?.trim().isNotEmpty == true
              ? draft!.trim()
              : (conversation.draft?.trim() ?? ''));
      return draftText.isNotEmpty;
    }).length;
    final topCount = messageProvider.conversations
        .where((item) => item.isTop == true)
        .length;
    final muteCount = messageProvider.conversations
        .where((item) => item.isMute == true)
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _conversationSearchController,
                decoration: InputDecoration(
                  hintText: '搜索会话、草稿或最近消息',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _conversationQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              _conversationSearchController.clear();
                              _conversationQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (value) {
                  setState(() {
                    _conversationQuery = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final filter in const [
                      '全部',
                      '未读',
                      '草稿',
                      '置顶',
                      '免打扰',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _conversationFilter == filter,
                          onSelected: (_) {
                            setState(() {
                              _conversationFilter = filter;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${filteredConversations.length} / $totalCount 个会话',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: '排序',
                          onSelected: (value) {
                            setState(() {
                              _conversationSort = value;
                            });
                          },
                          itemBuilder: (context) => [
                            CheckedPopupMenuItem(
                              value: '智能排序',
                              checked: _conversationSort == '智能排序',
                              child: const Text('智能排序'),
                            ),
                            CheckedPopupMenuItem(
                              value: '最近消息',
                              checked: _conversationSort == '最近消息',
                              child: const Text('最近消息'),
                            ),
                            CheckedPopupMenuItem(
                              value: '未读优先',
                              checked: _conversationSort == '未读优先',
                              child: const Text('未读优先'),
                            ),
                            CheckedPopupMenuItem(
                              value: '名称排序',
                              checked: _conversationSort == '名称排序',
                              child: const Text('名称排序'),
                            ),
                          ],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                _conversationSort,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _conversationSearchController.clear();
                              _conversationQuery = '';
                              _conversationFilter = '全部';
                              _conversationSort = '智能排序';
                            });
                          },
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildConversationStatChip(
                          '未读',
                          '$unreadCount',
                          valueColor: const Color(0xFF2563EB),
                        ),
                        _buildConversationStatChip(
                          '草稿',
                          '$draftCount',
                          valueColor: const Color(0xFFEA580C),
                        ),
                        _buildConversationStatChip(
                          '置顶',
                          '$topCount',
                          valueColor: const Color(0xFF7C3AED),
                        ),
                        _buildConversationStatChip(
                          '免打扰',
                          '$muteCount',
                          valueColor: const Color(0xFF0F766E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredConversations.isEmpty
              ? const _EmptyState(
                  icon: Icons.filter_list_off,
                  text: '没有符合当前筛选条件的会话',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    final hasUnread =
                        conversation.unreadCount != null && conversation.unreadCount! > 0;
                    final draft = messageProvider.getDraft(
                      conversation.targetId,
                      conversation.type,
                    );
                    final draftText = (draft?.trim().isNotEmpty == true
                            ? draft!.trim()
                            : (conversation.draft?.trim() ?? ''));
                    final statusLabels = <String>[
                      if (conversation.isTop == true) '置顶',
                      if (conversation.isMute == true) '免打扰',
                    ];
                    final previewText = draftText.isNotEmpty
                        ? '[草稿] $draftText'
                        : conversation.lastMessage ?? '';

                    return _buildCard(
                      child: ListTile(
                        leading: _buildAvatar(),
                        title: Text(
                          conversation.name ?? '',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontWeight:
                                hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (statusLabels.isNotEmpty)
                              '[${statusLabels.join(' / ')}]',
                            previewText,
                          ].where((item) => item.isNotEmpty).join(' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: draftText.isNotEmpty
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF9E9E9E),
                            fontSize: 14,
                          ),
                        ),
                        trailing: Text(
                          conversation.lastMessageTime ?? '',
                          style: TextStyle(
                            color: hasUnread
                                ? Theme.of(context).primaryColor
                                : const Color(0xFF9E9E9E),
                            fontSize: 12,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        minVerticalPadding: 12,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        titleAlignment: ListTileTitleAlignment.center,
                        selected: draftText.isNotEmpty,
                        selectedTileColor: const Color(0xFFFFF7ED),
                        onLongPress: () => _showConversationActions(conversation),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'targetId': conversation.targetId,
                              'type': conversation.type,
                              'title': conversation.name,
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool primary,
  }) {
    return Expanded(
      child: primary
          ? ElevatedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }

  Widget _buildRequestCard(
    FriendRequestDTO request, {
    required bool showActions,
    required String subtitle,
  }) {
    final user = request.fromUserInfo ?? request.toUserInfo;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nickname ?? request.remark ?? '新朋友',
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message?.isNotEmpty == true
                          ? request.message!
                          : subtitle,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRequestActionButton(
                  label: '拒绝',
                  onPressed: request.id == null
                      ? null
                      : () => _handleFriendRequest(request.id!, false),
                  primary: false,
                ),
                const SizedBox(width: 12),
                _buildRequestActionButton(
                  label: '同意',
                  onPressed: request.id == null
                      ? null
                      : () => _handleFriendRequest(request.id!, true),
                  primary: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleConversationTop(dynamic conversation) async {
    final messageProvider = context.read<MessageProvider>();
    final success = await messageProvider.updateConversationSetting(
      conversation.targetId!,
      type: conversation.type ?? 1,
      isTop: !(conversation.isTop ?? false),
    );

    if (!mounted) {
      return;
    }

    final message = success
        ? ((conversation.isTop ?? false)
            ? '已取消置顶'
            : '已置顶会话')
        : (messageProvider.error ?? '置顶设置失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleConversationMute(dynamic conversation) async {
    final messageProvider = context.read<MessageProvider>();
    final success = await messageProvider.updateConversationSetting(
      conversation.targetId!,
      type: conversation.type ?? 1,
      isMute: !(conversation.isMute ?? false),
    );

    if (!mounted) {
      return;
    }

    final message = success
        ? ((conversation.isMute ?? false)
            ? '已取消免打扰'
            : '已开启免打扰')
        : (messageProvider.error ?? '免打扰设置失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteConversation(dynamic conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除会话'),
          content: const Text(
            '删除后会从会话列表中移除，但不会删除历史消息记录。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final messageProvider = context.read<MessageProvider>();
    final success = await messageProvider.deleteConversation(
      conversation.targetId!,
      type: conversation.type ?? 1,
    );

    if (!mounted) {
      return;
    }

    final message = success
        ? '已删除会话'
        : (messageProvider.error ?? '删除会话失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showConversationActions(dynamic conversation) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  (conversation.isTop ?? false)
                      ? Icons.vertical_align_bottom
                      : Icons.vertical_align_top,
                ),
                title: Text(
                  (conversation.isTop ?? false)
                      ? '取消置顶'
                      : '置顶会话',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleConversationTop(conversation);
                },
              ),
              ListTile(
                leading: Icon(
                  (conversation.isMute ?? false)
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                ),
                title: Text(
                  (conversation.isMute ?? false)
                      ? '取消免打扰'
                      : '开启免打扰',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleConversationMute(conversation);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE53935),
                ),
                title: const Text(
                  '删除会话',
                  style: TextStyle(color: Color(0xFFE53935)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteConversation(conversation);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestSection({
    required String title,
    required List<FriendRequestDTO> requests,
    required bool showActions,
    required String emptySubtitle,
  }) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            ...requests.map(
              (request) => _buildRequestCard(
                request,
                showActions: showActions,
                subtitle: emptySubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTile(FriendDTO friend) {
    final info = friend.friendUserInfo;
    final isOnline = (info?.onlineStatus ?? 0) == 1;
    final signature = info?.signature ?? '';
    final subtitle = signature.isNotEmpty
        ? '${_statusTextFromFriend(friend)} | $signature'
        : _statusTextFromFriend(friend);

    return _buildCard(
      child: ListTile(
        leading: _buildAvatar(),
        title: Text(
          friend.remark ?? info?.nickname ?? '',
          style: const TextStyle(color: Color(0xFF333333)),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _statusColor(isOnline),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        onTap: info?.id == null
            ? null
            : () {
                Navigator.pushNamed(
                  context,
                  '/user-detail',
                  arguments: {
                    'userId': info!.id,
                    'user': info,
                  },
                );
              },
      ),
    );
  }

  Widget _buildFriendsTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    if (friendProvider.friends.isEmpty &&
        friendProvider.receivedRequests.isEmpty &&
        friendProvider.sentRequests.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline,
        text: '暂无好友',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (friendProvider.receivedRequests.isNotEmpty)
          _buildRequestSection(
            title: '收到的好友申请',
            requests: friendProvider.receivedRequests,
            showActions: true,
            emptySubtitle: '请求添加你为好友',
          ),
        if (friendProvider.sentRequests.isNotEmpty)
          _buildRequestSection(
            title: '发出的好友申请',
            requests: friendProvider.sentRequests,
            showActions: false,
            emptySubtitle: '等待对方处理',
          ),
        ...friendProvider.friends.map(_buildFriendTile),
      ],
    );
  }

  Widget _buildProfileTab(AuthProvider authProvider) {
    final showOnlineStatus = authProvider.user?.showOnlineStatus ?? true;
    final showLastOnline = authProvider.user?.showLastOnline ?? true;
    final allowSearchByPhone = authProvider.user?.allowSearchByPhone ?? true;
    final needFriendVerification =
        authProvider.user?.needFriendVerification ?? true;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildAvatar(size: 80),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.user?.nickname ??
                            '未设置昵称',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authProvider.user?.phone ?? '',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('显示在线状态'),
                subtitle: const Text(
                  '其他用户可以看到你是否在线。',
                ),
                value: showOnlineStatus,
                onChanged: (value) => _updatePrivacySetting(
                  'showOnlineStatus',
                  value,
                  successMessage:
                      '在线状态显示设置已更新',
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('显示最后在线时间'),
                subtitle: const Text(
                  '其他用户可以看到你的最后在线时间。',
                ),
                value: showLastOnline,
                onChanged: (value) => _updatePrivacySetting(
                  'showLastOnline',
                  value,
                  successMessage:
                      '最后在线时间显示设置已更新',
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('允许手机号搜索'),
                subtitle: const Text(
                  '其他用户可以通过手机号搜索到你。',
                ),
                value: allowSearchByPhone,
                onChanged: (value) => _updatePrivacySetting(
                  'allowSearchByPhone',
                  value,
                  successMessage:
                      '手机号搜索设置已更新',
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('添加好友需要验证'),
                subtitle: const Text(
                  '关闭后，对方可直接成为你的好友。',
                ),
                value: needFriendVerification,
                onChanged: (value) => _updatePrivacySetting(
                  'needFriendVerification',
                  value,
                  successMessage:
                      '好友验证设置已更新',
                ),
              ),
            ],
          ),
        ),
        _buildCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('账户与设备'),
            subtitle: const Text('管理设备锁、登录设备和异地登录提示'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/security'),
          ),
        ),
        _buildCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('我的举报'),
            subtitle: const Text('查看你提交的举报处理进度'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/report-list'),
          ),
        ),
        _buildCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('我的内容审核'),
            subtitle: const Text('查看你提交内容的审核状态'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/content-audit-list'),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) {
                return;
              }
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('退出登录'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final friendProvider = context.watch<FriendProvider>();

    final tabs = <Widget>[
      Scaffold(
        appBar: AppBar(
          title: const Text('消息'),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/groups'),
              icon: const Icon(Icons.groups_outlined),
              tooltip: '我的群组',
            ),
          ],
        ),
        body: _buildMessagesTab(messageProvider),
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('好友'),
          actions: [
            IconButton(
              onPressed: _openAddFriendDialog,
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: '添加好友',
            ),
          ],
        ),
        body: _buildFriendsTab(friendProvider),
      ),
      Scaffold(
        appBar: AppBar(title: const Text('我的')),
        body: _buildProfileTab(authProvider),
      ),
    ];

    final isWebOrWindows =
        kIsWeb || defaultTargetPlatform == TargetPlatform.windows;
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: '消息',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        activeIcon: Icon(Icons.people),
        label: '好友',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: '我的',
      ),
    ];

    if (!isWebOrWindows) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          activeIcon: Icon(Icons.qr_code_scanner),
          label: '扫码',
        ),
      );
    }

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (!isWebOrWindows && index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRCodeScannerScreen(
                  title: '扫码',
                  onScan: (code) => debugPrint('Scan result: $code'),
                ),
              ),
            );
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
        items: items,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}




