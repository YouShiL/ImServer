import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_list_item_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/common/primary_section_header_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

class CreateGroupV2Page extends StatefulWidget {
  const CreateGroupV2Page({super.key});

  @override
  State<CreateGroupV2Page> createState() => _CreateGroupV2PageState();
}

class _CreateGroupV2PageState extends State<CreateGroupV2Page> {
  late final TextEditingController _nameController;
  final Set<int> _selectedFriendIds = <int>{};
  bool _didLoadFriends = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadFriends) {
      return;
    }
    _didLoadFriends = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final FriendProvider friendProvider = context.read<FriendProvider>();
      if (friendProvider.friends.isEmpty) {
        await friendProvider.loadFriends();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleFriend(FriendDTO friend) {
    final int? friendId = friend.friendUserId ?? friend.friendUserInfo?.id;
    if (friendId == null) {
      return;
    }
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  Future<void> _submit() async {
    final String groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      setState(() {
        _error = '请输入群名称';
      });
      return;
    }
    if (_selectedFriendIds.isEmpty) {
      setState(() {
        _error = '请至少选择 1 位成员';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final GroupProvider groupProvider = context.read<GroupProvider>();
    final bool ok = await groupProvider.createGroup(
      groupName,
      '',
      memberIds: _selectedFriendIds.toList(growable: false),
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('群聊已创建')),
        );
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _submitting = false;
      _error = groupProvider.error ?? '创建群组失败';
    });
  }

  @override
  Widget build(BuildContext context) {
    final FriendProvider friendProvider = context.watch<FriendProvider>();
    final List<FriendDTO> friends = friendProvider.friends;

    return SecondaryPageScaffoldV2(
      title: '建群',
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameController,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: '输入群名称',
                prefixIcon: const Icon(Icons.groups_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_error != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          PrimarySectionHeaderV2(
            title: '成员 (${_selectedFriendIds.length})',
          ),
          if (friendProvider.isLoading && friends.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (friends.isEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: const Text(
                '当前没有可用于本地选择的好友数据。',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            )
          else
            ...friends.map((FriendDTO friend) {
              final int? friendId = friend.friendUserId ?? friend.friendUserInfo?.id;
              final bool selected =
                  friendId != null && _selectedFriendIds.contains(friendId);
              final String title = friend.remark?.trim().isNotEmpty == true
                  ? friend.remark!.trim()
                  : friend.friendUserInfo?.nickname?.trim().isNotEmpty == true
                      ? friend.friendUserInfo!.nickname!.trim()
                      : '未命名联系人';
              final String subtitle =
                  friend.friendUserInfo?.phone?.trim().isNotEmpty == true
                  ? '手机号 ${friend.friendUserInfo!.phone!.trim()}'
                  : '联系人资料占位';

              return PrimaryListItemV2(
                title: title,
                subtitle: subtitle,
                onTap: _submitting ? null : () => _toggleFriend(friend),
                leading: Container(
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
                    ),
                  ),
                ),
                trailing: Checkbox(
                  value: selected,
                  onChanged: _submitting ? null : (_) => _toggleFriend(friend),
                ),
              );
            }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? '创建中...' : '创建群组'),
            ),
          ),
        ],
      ),
    );
  }
}
