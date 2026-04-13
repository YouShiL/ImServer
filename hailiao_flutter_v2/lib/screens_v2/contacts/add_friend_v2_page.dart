import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/user_detail_v2_page.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_section_header_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_list_item_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

class AddFriendV2Page extends StatefulWidget {
  const AddFriendV2Page({super.key});

  @override
  State<AddFriendV2Page> createState() => _AddFriendV2PageState();
}

class _AddFriendV2PageState extends State<AddFriendV2Page> {
  late final TextEditingController _keywordController;
  late final TextEditingController _remarkController;
  late final TextEditingController _messageController;

  String _searchType = 'userId';
  UserDTO? _searchedUser;
  String? _error;
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _didLoadFriendState = false;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController();
    _remarkController = TextEditingController();
    _messageController = TextEditingController(text: '你好，我想加你为好友。');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadFriendState) {
      return;
    }
    _didLoadFriendState = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final FriendProvider friendProvider = context.read<FriendProvider>();
      if (friendProvider.friends.isEmpty) {
        await friendProvider.loadFriends();
      }
      await friendProvider.loadFriendRequests();
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _remarkController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final String keyword = _keywordController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _error = '请输入用户 ID 或手机号';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _searchedUser = null;
    });

    try {
      final response = await ApiService.searchUser(keyword, type: _searchType);
      if (!mounted) {
        return;
      }

      setState(() {
        if (response.isSuccess) {
          final AuthProvider auth = context.read<AuthProvider>();
          final int? selfId = auth.messagingUserId ?? auth.user?.id;
          final UserDTO? raw = response.data;
          if (raw != null &&
              selfId != null &&
              raw.id != null &&
              raw.id == selfId) {
            _searchedUser = null;
            _error = '不能添加自己为好友';
          } else {
            _searchedUser = raw;
            if (_searchedUser == null) {
              _error = '未找到匹配用户';
            } else if (_remarkController.text.trim().isEmpty) {
              _remarkController.text = _displayNameOf(_searchedUser!);
            }
          }
        } else {
          _error = response.message.trim().isNotEmpty
              ? response.message.trim()
              : '搜索失败，请稍后重试';
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '搜索失败，请检查网络后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _submitFriendRequest() async {
    final UserDTO? user = _searchedUser;
    if (user == null || user.id == null) {
      setState(() {
        _error = '请先搜索目标用户';
      });
      return;
    }

    final String remark = _remarkController.text.trim();
    if (remark.isEmpty) {
      setState(() {
        _error = '请输入备注';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final FriendProvider friendProvider = context.read<FriendProvider>();
    final bool success = await friendProvider.addFriend(
      user.id!,
      remark,
      message: _messageController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('好友申请已发送')),
        );
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _error = friendProvider.error?.trim().isNotEmpty == true
          ? friendProvider.error!.trim()
          : '发送好友申请失败';
    });
  }

  bool _isAlreadyFriend(FriendProvider friendProvider, UserDTO user) {
    final int? userId = user.id;
    final String? userNo = user.userCode?.trim();
    return friendProvider.friends.any((FriendDTO friend) {
      if (userId != null && friend.friendUserId == userId) {
        return true;
      }
      final String? friendUserNo = friend.friendUserInfo?.userCode?.trim();
      return userNo != null && userNo.isNotEmpty && friendUserNo == userNo;
    });
  }

  bool _hasPendingRequest(FriendProvider friendProvider, UserDTO user) {
    final int? userId = user.id;
    return friendProvider.sentRequests.any((FriendRequestDTO request) {
      if (userId == null) {
        return false;
      }
      return request.toUserId == userId && (request.status ?? 0) == 0;
    });
  }

  String _displayNameOf(UserDTO user) {
    final String nickname = user.nickname?.trim() ?? '';
    if (nickname.isNotEmpty) {
      return nickname;
    }
    final String account = user.userCode?.trim() ?? '';
    if (account.isNotEmpty) {
      return account;
    }
    return '未命名用户';
  }

  FriendDTO? _friendInitialFor(FriendProvider fp, UserDTO user) {
    final int? uid = user.id;
    if (uid == null) {
      return null;
    }
    for (final FriendDTO f in fp.friends) {
      if (f.friendUserId == uid) {
        return f;
      }
    }
    return null;
  }

  String _subtitleOf(UserDTO user) {
    final String userId = user.userCode?.trim() ?? '';
    final String phone = user.phone?.trim() ?? '';
    if (userId.isNotEmpty && phone.isNotEmpty) {
      return 'ID $userId · $phone';
    }
    if (userId.isNotEmpty) {
      return 'ID $userId';
    }
    if (phone.isNotEmpty) {
      return phone;
    }
    return '用户资料待补充';
  }

  @override
  Widget build(BuildContext context) {
    final FriendProvider friendProvider = context.watch<FriendProvider>();
    final AuthProvider auth = context.watch<AuthProvider>();
    final int? selfId = auth.messagingUserId ?? auth.user?.id;
    final UserDTO? searchedUser = _searchedUser;
    final bool isSelf = searchedUser != null &&
        selfId != null &&
        searchedUser.id != null &&
        searchedUser.id == selfId;
    final bool alreadyFriend = searchedUser == null
        ? false
        : _isAlreadyFriend(friendProvider, searchedUser);
    final bool hasPendingRequest = searchedUser == null
        ? false
        : _hasPendingRequest(friendProvider, searchedUser);

    return SecondaryPageScaffoldV2(
      title: '添加好友',
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'userId',
                  label: Text('用户 ID'),
                  icon: Icon(Icons.badge_outlined),
                ),
                ButtonSegment<String>(
                  value: 'phone',
                  label: Text('手机号'),
                  icon: Icon(Icons.phone_android_outlined),
                ),
              ],
              selected: <String>{_searchType},
              onSelectionChanged: _isSearching
                  ? null
                  : (Set<String> selection) {
                      setState(() {
                        _searchType = selection.first;
                      });
                    },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchUser(),
                    decoration: InputDecoration(
                      hintText: _searchType == 'phone' ? '输入手机号' : '输入用户 ID',
                      prefixIcon: const Icon(Icons.person_search_outlined),
                      filled: true,
                      fillColor: ChatV2Tokens.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSearching ? null : _searchUser,
                  child: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('搜索'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PrimarySectionHeaderV2(title: '搜索结果'),
          if (searchedUser == null && !_isSearching)
            _buildInfoCard('输入用户 ID 或手机号后即可发起搜索，并通过旧工程好友申请链路发送请求。')
          else if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (searchedUser != null) ...<Widget>[
            PrimaryListItemV2(
              title: _displayNameOf(searchedUser),
              subtitle: _subtitleOf(searchedUser),
              leading: _UserLeading(title: _displayNameOf(searchedUser)),
              trailing: _buildResultAction(
                isSelf: isSelf,
                alreadyFriend: alreadyFriend,
                hasPendingRequest: hasPendingRequest,
              ),
              onTap: searchedUser.id == null || isSelf
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => UserDetailV2Page(
                            userId: searchedUser.id!,
                            initialFriend: _friendInitialFor(
                              friendProvider,
                              searchedUser,
                            ),
                          ),
                        ),
                      );
                    },
            ),
            Container(
              color: ChatV2Tokens.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildFieldLabel('备注'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _remarkController,
                    enabled:
                        !isSelf && !alreadyFriend && !hasPendingRequest && !_isSubmitting,
                    decoration: _fieldDecoration('给对方设置备注'),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('验证消息'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _messageController,
                    enabled:
                        !isSelf && !alreadyFriend && !hasPendingRequest && !_isSubmitting,
                    maxLines: 2,
                    decoration: _fieldDecoration('填写发送给对方的申请说明'),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
          if (searchedUser != null &&
              !isSelf &&
              !alreadyFriend &&
              !hasPendingRequest) ...<Widget>[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitFriendRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('发送好友申请'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultAction({
    required bool isSelf,
    required bool alreadyFriend,
    required bool hasPendingRequest,
  }) {
    if (isSelf) {
      return const Text(
        '本人',
        style: TextStyle(
          fontSize: 12,
          color: ChatV2Tokens.textSecondary,
        ),
      );
    }
    if (alreadyFriend) {
      return const Text(
        '已添加',
        style: TextStyle(
          fontSize: 12,
          color: ChatV2Tokens.textSecondary,
        ),
      );
    }
    if (hasPendingRequest) {
      return const Text(
        '已申请',
        style: TextStyle(
          fontSize: 12,
          color: ChatV2Tokens.textSecondary,
        ),
      );
    }
    return const Icon(
      Icons.person_add_alt_1_outlined,
      color: ChatV2Tokens.accent,
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ChatV2Tokens.textSecondary,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: ChatV2Tokens.surfaceSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      color: ChatV2Tokens.surface,
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: ChatV2Tokens.textSecondary,
        ),
      ),
    );
  }
}

class _UserLeading extends StatelessWidget {
  const _UserLeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFD6DCE3),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        title.isEmpty ? '?' : title.substring(0, 1),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ChatV2Tokens.textPrimary,
        ),
      ),
    );
  }
}
