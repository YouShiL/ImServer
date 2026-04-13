import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/conversation_summary.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/identity_resolver.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_message_mapper.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/add_friend_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/contacts_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/create_group_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/conversation/conversation_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/profile/profile_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/profile/settings_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/search/search_v2_page.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/main_shell_header_v2.dart';
import 'package:hailiao_flutter_v2/providers/social_notification_provider.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/primary_header_actions_v2.dart';
import 'package:provider/provider.dart';

class MainV2ShellPage extends StatefulWidget {
  const MainV2ShellPage({super.key});

  @override
  State<MainV2ShellPage> createState() => _MainV2ShellPageState();
}

class _MainV2ShellPageState extends State<MainV2ShellPage> {
  int _currentIndex = 0;
  ConversationRepository? _conversationRepository;
  StreamSubscription<ConversationSummary>? _conversationUnreadSub;
  int _messageTabUnreadTotal = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _conversationRepository ??= _createConversationRepository();
    _conversationUnreadSub ??=
        _conversationRepository!.watchConversationSummaries().listen((_) {
      _recalcMessageTabUnread();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _recalcMessageTabUnread();
      unawaited(context.read<SocialNotificationProvider>().loadPendingCount());
    });
  }

  void _recalcMessageTabUnread() {
    final ConversationRepository? repo = _conversationRepository;
    if (repo == null) {
      return;
    }
    int sum = 0;
    for (final ConversationSummary s in repo.getCachedConversations()) {
      sum += s.unreadCount;
    }
    if (sum != _messageTabUnreadTotal && mounted) {
      setState(() {
        _messageTabUnreadTotal = sum;
      });
    }
  }

  @override
  void dispose() {
    _conversationUnreadSub?.cancel();
    super.dispose();
  }

  ConversationRepository _createConversationRepository() {
    final IdentityResolver id = IdentityResolver(
      getFriends: () => context.read<FriendProvider>().friends,
      getGroups: () => context.read<GroupProvider>().groups,
    );
    return ApiConversationRepository(
      mapper: ImMessageMapper(identityResolver: id),
    );
  }

  List<_MainTabItem> _buildTabs(
    BuildContext context, {
    required int messageUnread,
    required int socialPending,
  }) {
    return <_MainTabItem>[
      _MainTabItem(
        title: 'Chats',
        widget: const ConversationV2Page(),
        destination: NavigationDestination(
          icon: _tabIconWithBadge(
            badge: messageUnread,
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          selectedIcon: _tabIconWithBadge(
            badge: messageUnread,
            icon: const Icon(Icons.chat_bubble),
          ),
          label: 'Chats',
        ),
        actions: <PrimaryHeaderActionItemV2>[
          PrimaryHeaderActionItemV2(
            icon: Icons.search,
            tooltip: 'Search',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SearchV2Page(),
                ),
              );
            },
          ),
          PrimaryHeaderActionItemV2(
            icon: Icons.more_horiz,
            tooltip: 'More',
            onTap: () => _showConversationMoreEntry(context),
          ),
        ],
      ),
      _MainTabItem(
        title: 'Contacts',
        widget: const ContactsV2Page(),
        destination: NavigationDestination(
          icon: _tabIconWithBadge(
            badge: socialPending,
            icon: const Icon(Icons.perm_contact_calendar_outlined),
          ),
          selectedIcon: _tabIconWithBadge(
            badge: socialPending,
            icon: const Icon(Icons.perm_contact_calendar),
          ),
          label: 'Contacts',
        ),
        actions: <PrimaryHeaderActionItemV2>[
          PrimaryHeaderActionItemV2(
            icon: Icons.person_add_alt_1_outlined,
            tooltip: 'Add friend',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddFriendV2Page(),
                ),
              );
            },
          ),
          PrimaryHeaderActionItemV2(
            icon: Icons.group_add_outlined,
            tooltip: 'Create group',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateGroupV2Page(),
                ),
              );
            },
          ),
        ],
      ),
      _MainTabItem(
        title: 'Profile',
        widget: const ProfileV2Page(),
        destination: const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        actions: <PrimaryHeaderActionItemV2>[
          PrimaryHeaderActionItemV2(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsV2Page(),
                ),
              );
            },
          ),
        ],
      ),
    ];
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showConversationMoreEntry(BuildContext context) async {
    final ConversationRepository repo = _conversationRepository!;
    List<ConversationSummary> conversations =
        repo.getCachedConversations();

    if (conversations.isEmpty) {
      try {
        conversations = await repo.loadConversations();
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showToast(this.context, error.toString());
        return;
      }
    }

    if (!mounted) {
      return;
    }

    if (conversations.isEmpty) {
      _showToast(this.context, 'No conversations available.');
      return;
    }

    await showModalBottomSheet<void>(
      context: this.context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext itemContext, int index) {
              final ConversationSummary conversation = conversations[index];
              final List<String> tags = <String>[
                if (conversation.isTop) 'Pinned',
                if (conversation.isMuted) 'Muted',
              ];
              final String subtitle = [
                ...tags,
                if (conversation.lastMessage.trim().isNotEmpty)
                  conversation.lastMessage.trim(),
              ].join(' · ');

              return ListTile(
                title: Text(conversation.title),
                subtitle: subtitle.isEmpty
                    ? null
                    : Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showConversationActions(itemContext, conversation);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showConversationActions(
    BuildContext context,
    ConversationSummary conversation,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _conversationSheetTile(
                icon: conversation.isTop
                    ? Icons.vertical_align_bottom
                    : Icons.vertical_align_top,
                title: conversation.isTop ? 'Unpin conversation' : 'Pin conversation',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _toggleConversationTop(context, conversation);
                },
              ),
              const Divider(height: 1),
              _conversationSheetTile(
                icon: conversation.isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                title: conversation.isMuted ? 'Turn on notifications' : 'Mute conversation',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _toggleConversationMute(context, conversation);
                },
              ),
              const Divider(height: 1),
              _conversationSheetTile(
                icon: Icons.delete_outline,
                title: 'Delete conversation',
                iconColor: Colors.redAccent,
                textColor: Colors.redAccent,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _deleteConversation(context, conversation);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _conversationSheetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }

  Future<void> _toggleConversationTop(
    BuildContext context,
    ConversationSummary conversation,
  ) async {
    bool success = false;
    String? errorMessage;
    try {
      await _conversationRepository!.updateConversationSetting(
        conversation.targetId,
        type: conversation.type,
        isTop: !conversation.isTop,
      );
      success = true;
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!context.mounted) {
      return;
    }

    _showToast(
      context,
      success
          ? (conversation.isTop ? 'Conversation unpinned.' : 'Conversation pinned.')
          : (errorMessage ?? 'Failed to update pin status.'),
    );
  }

  Future<void> _toggleConversationMute(
    BuildContext context,
    ConversationSummary conversation,
  ) async {
    bool success = false;
    String? errorMessage;
    try {
      await _conversationRepository!.updateConversationSetting(
        conversation.targetId,
        type: conversation.type,
        isMuted: !conversation.isMuted,
      );
      success = true;
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!context.mounted) {
      return;
    }

    _showToast(
      context,
      success
          ? (conversation.isMuted
              ? 'Notifications enabled.'
              : 'Conversation muted.')
          : (errorMessage ?? 'Failed to update mute status.'),
    );
  }

  Future<void> _deleteConversation(
    BuildContext context,
    ConversationSummary conversation,
  ) async {
    bool success = false;
    String? errorMessage;
    try {
      await _conversationRepository!.deleteConversation(
        conversation.targetId,
        type: conversation.type,
      );
      success = true;
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!context.mounted) {
      return;
    }

    _showToast(
      context,
      success
          ? 'Conversation deleted.'
          : (errorMessage ?? 'Failed to delete conversation.'),
    );
  }

  static Widget _tabIconWithBadge({required int badge, required Widget icon}) {
    if (badge <= 0) {
      return icon;
    }
    final String label = badge > 99 ? '99+' : '$badge';
    return Badge(
      label: Text(label),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int socialPending =
        context.watch<SocialNotificationProvider>().pendingCount;
    final List<_MainTabItem> tabs = _buildTabs(
      context,
      messageUnread: _messageTabUnreadTotal,
      socialPending: socialPending,
    );
    final _MainTabItem currentTab = tabs[_currentIndex];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            MainShellHeaderV2(
              title: currentTab.title,
              actions: <Widget>[
                PrimaryHeaderActionsV2(actions: currentTab.actions),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: tabs.map((tab) => tab.widget).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations:
            tabs.map((tab) => tab.destination).toList(growable: false),
      ),
    );
  }
}

class _MainTabItem {
  const _MainTabItem({
    required this.title,
    required this.widget,
    required this.destination,
    required this.actions,
  });

  final String title;
  final Widget widget;
  final NavigationDestination destination;
  final List<PrimaryHeaderActionItemV2> actions;
}
