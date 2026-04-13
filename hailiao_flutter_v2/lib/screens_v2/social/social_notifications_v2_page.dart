import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/user_notification_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter_v2/domain_v2/social/social_notification_copy.dart';
import 'package:hailiao_flutter_v2/domain_v2/social/social_notification_payload.dart';
import 'package:hailiao_flutter_v2/providers/social_notification_provider.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/friend_requests_received_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/group_detail_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/user_detail_v2_page.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

/// 社交关系事件（social 域），非聊天、非万能通知中心。
class SocialNotificationsV2Page extends StatefulWidget {
  const SocialNotificationsV2Page({super.key});

  @override
  State<SocialNotificationsV2Page> createState() =>
      _SocialNotificationsV2PageState();
}

class _SocialNotificationsV2PageState extends State<SocialNotificationsV2Page> {
  bool _didLoad = false;

  /// 同一条通知处理中（markRead + 跳转）时忽略重复点击，避免连点或动画误触重复 push。
  int? _processingNotificationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await context.read<SocialNotificationProvider>().loadFirstPage();
    });
  }

  Future<void> _onTap(
    BuildContext context,
    SocialNotificationProvider social,
    UserNotificationDTO n,
  ) async {
    final int? nid = n.id;
    if (nid == null) {
      return;
    }
    if (_processingNotificationId == nid) {
      return;
    }
    _processingNotificationId = nid;
    try {
      await social.markRead(nid);
      if (!context.mounted) {
        return;
      }
      final Map<String, dynamic>? p =
          SocialNotificationPayload.tryParse(n.payload);
      final String? t = n.type;

      if (t == 'friend_request_received') {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FriendRequestsReceivedV2Page(),
          ),
        );
        if (!context.mounted) {
          return;
        }
        await context.read<SocialNotificationProvider>().refreshAfterBusinessAction();
        if (!context.mounted) {
          return;
        }
        await context.read<FriendProvider>().loadFriendRequests();
        return;
      }

      if (t == 'friend_request_accepted' || t == 'friend_request_rejected') {
        final int? uid = SocialNotificationPayload.userIdForPeer(p);
        if (uid != null) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => UserDetailV2Page(userId: uid),
            ),
          );
          if (!context.mounted) {
            return;
          }
          await context.read<FriendProvider>().loadFriends();
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('缺少对方用户信息，无法打开详情')),
          );
        }
        return;
      }

      if (t == 'group_join_request_received') {
        final int? gid = SocialNotificationPayload.groupChatId(p);
        if (gid != null) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GroupDetailV2Page(
                groupId: gid,
                openJoinRequestsSection: true,
                highlightJoinRequestsSection: true,
              ),
            ),
          );
          if (!context.mounted) {
            return;
          }
          await context.read<SocialNotificationProvider>().refreshAfterBusinessAction();
          if (!context.mounted) {
            return;
          }
          final GroupProvider gp = context.read<GroupProvider>();
          await gp.loadGroups();
          await gp.loadJoinRequests(gid);
        }
        return;
      }

      if (t == 'group_join_request_approved' ||
          t == 'group_join_request_rejected' ||
          t == 'group_invite_received') {
        // group_invite_received：未来若需「确认加入」，应拆为待处理类（pending）+ 独立确认流；type 已预留。
        final int? gid = SocialNotificationPayload.groupChatId(p);
        if (gid != null) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GroupDetailV2Page(groupId: gid),
            ),
          );
          if (!context.mounted) {
            return;
          }
          await context.read<GroupProvider>().loadGroups();
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('缺少群信息，无法打开详情')),
          );
        }
        return;
      }
    } finally {
      if (_processingNotificationId == nid) {
        _processingNotificationId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SocialNotificationProvider social =
        context.watch<SocialNotificationProvider>();

    return SecondaryPageScaffoldV2(
      title: '新的朋友',
      actions: <Widget>[
        TextButton(
          onPressed: social.isLoading
              ? null
              : () async {
                  await social.markAllRead();
                },
          child: const Text('全部已读'),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => social.loadFirstPage(),
        child: social.isLoading && social.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : social.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const <Widget>[
                      SizedBox(height: 48),
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: ChatV2Tokens.textSecondary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '暂无社交关系通知',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ChatV2Tokens.textSecondary),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: social.items.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final UserNotificationDTO n = social.items[index];
                      final String? st = n.status;
                      final bool isUnread = st == 'unread';
                      final bool isDimmed =
                          st == 'handled' || st == 'expired';
                      final bool isBold = isUnread;
                      final Color titleColor = isDimmed
                          ? ChatV2Tokens.textSecondary
                          : ChatV2Tokens.textPrimary;
                      final String title = SocialNotificationCopy.titleFor(n);
                      final String body = SocialNotificationCopy.bodyFor(n);
                      final String? statusLine =
                          SocialNotificationCopy.statusLine(st);
                      final bool showPendingChip =
                          (st == 'unread' || st == 'read') &&
                              SocialNotificationCopy.pendingEntryTypes
                                  .contains(n.type);
                      return ListTile(
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isBold
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            if (showPendingChip) ...<Widget>[
                              const SizedBox(width: 8),
                              Chip(
                                label: const Text('待处理'),
                                labelStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE65100),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                backgroundColor: const Color(0xFFFFF3E0),
                                side: const BorderSide(
                                  color: Color(0xFFFFCC80),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ChatV2Tokens.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (statusLine != null) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                statusLine,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ChatV2Tokens.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: isUnread
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: n.id == null
                            ? null
                            : () => _onTap(context, social, n),
                      );
                    },
                  ),
      ),
    );
  }
}
