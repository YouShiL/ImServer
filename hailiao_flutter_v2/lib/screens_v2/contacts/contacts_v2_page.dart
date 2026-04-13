import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter_v2/providers/social_notification_provider.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_api_flows_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_chat_entry_log.dart';
import 'package:hailiao_flutter_v2/screens_v2/social/social_notifications_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/groups_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/user_detail_v2_page.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/contacts/contact_list_item_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/contacts/contact_section_header_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/contacts/contacts_empty_state_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/primary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

class ContactsV2Page extends StatefulWidget {
  const ContactsV2Page({super.key});

  @override
  State<ContactsV2Page> createState() => _ContactsV2PageState();
}

class _ContactsV2PageState extends State<ContactsV2Page> {
  int _selectedIndex = 0;
  bool _didLoadFriends = false;

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
      final FriendProvider fp = context.read<FriendProvider>();
      await fp.loadFriends();
      if (!mounted) {
        return;
      }
      await fp.loadFriendRequests();
      if (!mounted) {
        return;
      }
      await context.read<SocialNotificationProvider>().loadFirstPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryPageScaffoldV2(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  label: Text('好友'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('群组'),
                  icon: Icon(Icons.groups_outlined),
                ),
              ],
              selected: <int>{_selectedIndex},
              onSelectionChanged: (Set<int> selection) {
                setState(() {
                  _selectedIndex = selection.first;
                });
              },
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const <Widget>[
                FriendsTabV2(),
                GroupsV2Page(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FriendsTabV2 extends StatelessWidget {
  const FriendsTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    final FriendProvider friendProvider = context.watch<FriendProvider>();
    final SocialNotificationProvider social =
        context.watch<SocialNotificationProvider>();
    final List<FriendDTO> friends = friendProvider.friends;

    if (friendProvider.isLoading && friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final int pendingReceived = friendProvider.receivedRequests
        .where((FriendRequestDTO r) => (r.status ?? 0) == 0)
        .length;

    final int socialPending = social.pendingCount;

    if (friends.isEmpty && pendingReceived == 0 && socialPending == 0) {
      return const ContactsEmptyStateV2(
        title: '暂无联系人',
        subtitle: '当前还没有可展示的好友数据。',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: friends.length + 2,
      separatorBuilder: (_, int index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Material(
            color: ChatV2Tokens.surface,
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SocialNotificationsV2Page(),
                  ),
                );
                if (context.mounted) {
                  await context.read<SocialNotificationProvider>().loadFirstPage();
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ChatV2Tokens.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_outlined,
                        color: ChatV2Tokens.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            '新的朋友',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            socialPending > 0
                                ? '$socialPending 项待处理'
                                : '好友与群组相关',
                            style: const TextStyle(
                              fontSize: 13,
                              color: ChatV2Tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (socialPending > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$socialPending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.chevron_right,
                        color: ChatV2Tokens.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        if (index == 1) {
          return const ContactSectionHeaderV2(title: '我的好友');
        }

        final FriendDTO friend = friends[index - 2];
        final String title = friend.remark?.trim().isNotEmpty == true
            ? friend.remark!.trim()
            : friend.friendUserInfo?.nickname?.trim().isNotEmpty == true
                ? friend.friendUserInfo!.nickname!.trim()
                : '未命名联系人';
        final String subtitle =
            friend.friendUserInfo?.phone?.trim().isNotEmpty == true
                ? '手机号 ${friend.friendUserInfo!.phone!.trim()}'
                : friend.groupName?.trim().isNotEmpty == true
                    ? friend.groupName!.trim()
                    : '好友资料占位';
        // IM 对端 uid：优先嵌套用户信息中的 id，避免 friendId 与资料不一致时发错会话。
        final int? targetId =
            friend.friendUserInfo?.id ?? friend.friendUserId;

        return ContactListItemV2(
          title: title,
          subtitle: subtitle,
          onTap: targetId == null
              ? () {}
              : () {
                  imFriendFlowLog('contacts_tap_chat', <String, Object?>{
                    'sourceApi': '/friend/list -> FriendDTO',
                    'sourceModel': 'FriendDTO',
                    'relationId': friend.id?.toString() ?? 'null',
                    'ownerUserId': friend.ownerUserId?.toString() ?? 'null',
                    'friendUserId': friend.friendUserId?.toString() ?? 'null',
                    'friendUserInfoId': friend.friendUserInfo?.id?.toString() ?? 'null',
                    'chatTargetId': targetId.toString(),
                    'chatType': '1',
                  });
                  imChatEntryLog(
                    'contacts_friend',
                    targetId: targetId,
                    type: 1,
                    title: title,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => UserDetailV2Page(
                        userId: targetId,
                        initialFriend: friend,
                      ),
                    ),
                  );
                },
        );
      },
    );
  }
}
