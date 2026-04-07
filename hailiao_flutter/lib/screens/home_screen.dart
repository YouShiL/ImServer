import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/add_friend_screen.dart';
import 'package:hailiao_flutter/screens/create_group_screen.dart';
import 'package:hailiao_flutter/screens/group_chat_screen.dart';
import 'package:hailiao_flutter/screens/group_list_screen.dart';
import 'package:hailiao_flutter/screens/me_screen.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/conversation_ui_tokens.dart';
import 'package:hailiao_flutter/theme/empty_state_ux_strings.dart';
import 'package:hailiao_flutter/theme/search_ux_strings.dart';
import 'package:hailiao_flutter/utils/conversation_time_format.dart';
import 'package:hailiao_flutter/utils/network_avatar_url.dart';
import 'package:hailiao_flutter/widgets/chat/conversation_empty_state.dart';
import 'package:hailiao_flutter/widgets/chat/conversation_list_item.dart';
import 'package:hailiao_flutter/widgets/common/im_feedback.dart';
import 'package:hailiao_flutter/widgets/common/wx_search_bar.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';
import 'package:hailiao_flutter/widgets/profile/profile_list_avatar.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
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

  static const double _homeEdgePad = 12;

  /// 会话 tab 全空列表（与筛选无关）。
  static const String _conversationEmptyTitle = '暂无会话';
  static const String _conversationEmptyDetail = '去添加好友或发起聊天';

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

  void _openAddFriendPage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AddFriendScreen(),
      ),
    );
  }

  void _openCreateGroupPage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CreateGroupScreen(),
      ),
    );
  }

  /// 「+」锚点：菜单左缘与顶缘（相对 Overlay），须位于按钮下沿以下以免遮挡。
  static const double _plusMenuRightMargin = 12;
  static const double _plusMenuGapBelow = 8;
  static const double _plusMenuWidth = 156;
  static const double _plusMenuRowHeight = 44;
  static const double _plusMenuRadius = 12;
  static const double _plusMenuCaretRight = 16;
  static const double _plusMenuCaretTop = -6;

  /// 会话页「+」锚点菜单：深色浮层（IM 操作层语义）。
  static const Color _plusMenuSurface = Color(0xFF2C2C2E);
  static Color get _plusMenuIconColor =>
      Colors.white.withValues(alpha: 0.9);
  static Color get _plusMenuTextColor =>
      Colors.white.withValues(alpha: 0.95);
  static Color get _plusMenuDividerColor =>
      Colors.white.withValues(alpha: 0.08);
  static Color get _plusMenuBorderColor =>
      Colors.white.withValues(alpha: 0.12);

  /// 与原先 [showMenu] 一致的锚点几何：顶缘 = 按钮底 + gap，左缘 = 屏宽 - 右边距 - 菜单宽。
  ({double left, double top}) _plusMenuAnchorLeftTop(
    BuildContext anchorContext,
  ) {
    final RenderBox button =
        anchorContext.findRenderObject()! as RenderBox;
    final OverlayState overlayState =
        Overlay.of(anchorContext, rootOverlay: true);
    final RenderBox overlay =
        overlayState.context.findRenderObject()! as RenderBox;
    final Size overlaySize = overlay.size;
    final Offset bottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final double topY = bottomRight.dy + _plusMenuGapBelow;
    final double left = (overlaySize.width -
            _plusMenuRightMargin -
            _plusMenuWidth)
        .clamp(8.0, overlaySize.width - _plusMenuRightMargin - 48);
    return (left: left, top: topY);
  }

  Widget _plusMenuDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 12,
      endIndent: 12,
      color: _plusMenuDividerColor,
    );
  }

  Widget _plusMenuActionRow({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.10),
      highlightColor: Colors.white.withValues(alpha: 0.06),
      child: SizedBox(
        height: _plusMenuRowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: _plusMenuIconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CommonTokens.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _plusMenuTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHomePlusMenu(BuildContext anchorContext) async {
    // 等当前帧与手势结束后再挂上遮罩，避免 pointer up 立刻触发展开即关。
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !anchorContext.mounted) {
      return;
    }

    final ({double left, double top}) anchor =
        _plusMenuAnchorLeftTop(anchorContext);
    final Completer<String?> completer = Completer<String?>();
    final OverlayState overlay =
        Overlay.of(anchorContext, rootOverlay: true);

    late OverlayEntry entry;
    var menuDismissed = false;
    void dismiss([String? result]) {
      if (menuDismissed) {
        return;
      }
      menuDismissed = true;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      entry.remove();
      entry.dispose();
    }

    entry = OverlayEntry(
      builder: (BuildContext _) {
        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => dismiss(null),
                  child: const ColoredBox(color: Color(0x14000000)),
                ),
              ),
              Positioned(
                left: anchor.left,
                top: anchor.top,
                width: _plusMenuWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Material(
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      surfaceTintColor: Colors.transparent,
                      color: _plusMenuSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_plusMenuRadius),
                        side: BorderSide(
                          color: _plusMenuBorderColor,
                          width: 0.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _plusMenuActionRow(
                            onTap: () => dismiss('create_group'),
                            icon: Icons.group_add_outlined,
                            label: '发起群聊',
                          ),
                          _plusMenuDivider(),
                          _plusMenuActionRow(
                            onTap: () => dismiss('add_friend'),
                            icon: Icons.person_add_alt_1_outlined,
                            label: '添加朋友',
                          ),
                          _plusMenuDivider(),
                          _plusMenuActionRow(
                            onTap: () => dismiss('scan'),
                            icon: Icons.qr_code_scanner_rounded,
                            label: '扫一扫',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: _plusMenuCaretTop,
                      right: _plusMenuCaretRight,
                      child: const _PlusMenuCaret(color: _plusMenuSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(entry);
    final String? choice = await completer.future;
    if (!mounted || choice == null) {
      return;
    }
    switch (choice) {
      case 'create_group':
        _openCreateGroupPage();
        break;
      case 'add_friend':
        _openAddFriendPage();
        break;
      case 'scan':
        Navigator.pushNamed(context, '/qr-scan');
        break;
    }
  }

  FriendDTO? _singleChatFriend(
    ConversationDTO conversation,
    FriendProvider friendProvider,
  ) {
    if (conversation.type != 1) {
      return null;
    }
    for (final FriendDTO f in friendProvider.friends) {
      if (f.friendId == conversation.targetId) {
        return f;
      }
    }
    return null;
  }

  /// 与聊天顶栏、资料页使用同一套单聊展示名规则（含好友备注）。
  /// 删除好友后 [FriendProvider] 无对应关系时回落 [ConversationDTO.name]/用户号链路，不再使用备注。
  String _conversationListTitle(
    ConversationDTO conversation,
    FriendProvider friendProvider,
  ) {
    if (conversation.type != 1) {
      return conversation.name ?? ProfileDisplayTexts.unset;
    }
    final FriendDTO? match = _singleChatFriend(conversation, friendProvider);
    return ProfileDisplayTexts.singleChatDisplayTitle(
      peer: match?.friendUserInfo,
      friendRemark: match?.remark,
      nameFallback: conversation.name,
    );
  }

  /// 单聊优先好友资料头像，否则会话快照 [ConversationDTO.avatar]；仅接受 `http`/`https`。
  String? _conversationAvatarImageUrl(
    ConversationDTO conversation,
    FriendProvider friendProvider,
  ) {
    final String raw;
    if (conversation.type == 1) {
      final FriendDTO? match = _singleChatFriend(conversation, friendProvider);
      final String avTrim =
          (match?.friendUserInfo?.avatar ?? '').trim();
      final String? fromUser = avTrim.isEmpty ? null : avTrim;
      raw = (fromUser ?? (conversation.avatar ?? '')).trim();
    } else {
      raw = (conversation.avatar ?? '').trim();
    }
    return httpOrHttpsAvatarUrlOrNull(raw);
  }

  /// [MessageProvider] 草稿优先，否则会话快照 [ConversationDTO.draft]。
  String _effectiveConversationDraftText(
    MessageProvider messageProvider,
    ConversationDTO c,
  ) {
    final String? fromProvider = messageProvider.getDraft(c.targetId, c.type);
    if (fromProvider != null && fromProvider.trim().isNotEmpty) {
      return fromProvider.trim();
    }
    return (c.draft ?? '').trim();
  }

  bool _conversationHasUnread(ConversationDTO c) =>
      (c.unreadCount ?? 0) > 0;

  List<ConversationDTO> _filteredConversations(
    MessageProvider messageProvider,
    FriendProvider friendProvider,
  ) {
    final query = _conversationQuery.trim().toLowerCase();
    final List<ConversationDTO> items =
        messageProvider.conversations.where((ConversationDTO conversation) {
      final String effectiveDraft =
          _effectiveConversationDraftText(messageProvider, conversation);
      if (query.isEmpty) {
        return true;
      }
      final displayTitle =
          _conversationListTitle(conversation, friendProvider);
      final FriendDTO? singleFriend = conversation.type == 1
          ? _singleChatFriend(conversation, friendProvider)
          : null;
      final String remarkHay = (singleFriend?.remark ?? '').trim();
      final haystack = [
        displayTitle,
        if (remarkHay.isNotEmpty) remarkHay,
        conversation.name ?? '',
        conversation.lastMessage ?? '',
        effectiveDraft,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    return items;
  }

  Widget _buildMessagesTab(
    MessageProvider messageProvider,
    FriendProvider friendProvider,
  ) {
    if (messageProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    if (messageProvider.conversations.isEmpty) {
      return const ConversationEmptyState(
        icon: Icons.chat_bubble_outline,
        title: _conversationEmptyTitle,
        detail: _conversationEmptyDetail,
      );
    }

    final filteredConversations =
        _filteredConversations(messageProvider, friendProvider);

    return ColoredBox(
      color: ConversationUiTokens.pageBackground,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _homeEdgePad,
              6,
              _homeEdgePad,
              8,
            ),
            child: WxSearchBar(
              controller: _conversationSearchController,
              hintText: '搜索',
              showClear: _conversationQuery.isNotEmpty,
              onChanged: (String value) {
                setState(() {
                  _conversationQuery = value;
                });
              },
              onClear: () {
                setState(() {
                  _conversationSearchController.clear();
                  _conversationQuery = '';
                });
              },
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: ConversationUiTokens.surface,
              child: filteredConversations.isEmpty
                  ? const ConversationEmptyState(
                      icon: Icons.search_off_rounded,
                      title: SearchUxStrings.emptyNoResults,
                      detail:
                          EmptyStateUxStrings.conversationSearchNoMatchDetail,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: filteredConversations.length,
                      itemBuilder: (BuildContext context, int index) {
                        final conversation = filteredConversations[index];
                        final bool hasUnread =
                            _conversationHasUnread(conversation);
                        final String draftText =
                            _effectiveConversationDraftText(
                          messageProvider,
                          conversation,
                        );
                        final previewText = draftText.isNotEmpty
                            ? '[草稿] $draftText'
                            : (conversation.lastMessage ?? '');
                        final title = _conversationListTitle(
                          conversation,
                          friendProvider,
                        );
                        final String avatarText =
                            ProfileDisplayTexts.listAvatarInitial(title);

                        return ConversationListItem(
                          title: title,
                          previewText: previewText,
                          timeText: ConversationTimeFormat.formatListTime(
                            conversation.lastMessageTime,
                          ),
                          hasUnread: hasUnread,
                          isDraft: draftText.isNotEmpty,
                          isTop: conversation.isTop == true,
                          isMute: conversation.isMute == true,
                          unreadCount: conversation.unreadCount ?? 0,
                          avatarText: avatarText,
                          avatarImageUrl: _conversationAvatarImageUrl(
                            conversation,
                            friendProvider,
                          ),
                          onLongPress: () =>
                              _showConversationActions(conversation),
                          onTap: () {
                            final int? tid = conversation.targetId;
                            if (tid == null) {
                              return;
                            }
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: conversation.type == 2
                                  ? GroupChatScreen.navigationArguments(
                                      targetId: tid,
                                      title: title,
                                    )
                                  : <String, dynamic>{
                                      'targetId': tid,
                                      'type': conversation.type,
                                      'title': title,
                                    },
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool primary,
  }) {
    return Expanded(
      child: primary
          ? FilledButton(
              style: UiTokens.filledPrimary(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onPressed,
              child: Text(label),
            )
          : OutlinedButton(
              style: UiTokens.outlinedSecondary(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onPressed,
              child: Text(label),
            ),
    );
  }

  Widget _buildRequestCard(
    FriendRequestDTO request, {
    required bool showActions,
    required String subtitle,
  }) {
    final user = request.fromUserInfo ?? request.toUserInfo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: CommonTokens.softSurface,
                child: Icon(
                  Icons.person_outline,
                  color: CommonTokens.textTertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user != null
                          ? ProfileDisplayTexts.displayName(user)
                          : ProfileDisplayTexts.fieldValue(
                              request.remark,
                              emptyLabel: '新朋友',
                            ),
                      style: const TextStyle(
                        color: CommonTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.message?.isNotEmpty == true
                          ? request.message!
                          : subtitle,
                      style: TextStyle(
                        color: CommonTokens.textSecondary.withValues(
                          alpha: 0.92,
                        ),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showActions) ...<Widget>[
            const SizedBox(height: 10),
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
        ? ((conversation.isTop ?? false) ? '已取消置顶' : '已置顶会话')
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
        ? ((conversation.isMute ?? false) ? '已取消免打扰' : '已开启免打扰')
        : (messageProvider.error ?? '免打扰设置失败');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _conversationSheetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return SizedBox(
      height: ImDesignTokens.heightItem,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ImDesignTokens.spaceLg,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: ImDesignTokens.iconMd,
                color: iconColor ?? ImDesignTokens.textSecondary,
              ),
              SizedBox(width: ImDesignTokens.spaceMd),
              Expanded(
                child: Text(
                  title,
                  style: CommonTokens.body.copyWith(
                    color: textColor ?? ImDesignTokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              _conversationSheetTile(
                icon: (conversation.isTop ?? false)
                    ? Icons.vertical_align_bottom
                    : Icons.vertical_align_top,
                title: (conversation.isTop ?? false)
                    ? '取消置顶'
                    : '置顶会话',
                onTap: () {
                  Navigator.pop(context);
                  _toggleConversationTop(conversation);
                },
              ),
              Divider(height: 1, thickness: 1, color: CommonTokens.lineSubtle),
              _conversationSheetTile(
                icon: (conversation.isMute ?? false)
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                title: (conversation.isMute ?? false)
                    ? '取消免打扰'
                    : '开启免打扰',
                onTap: () {
                  Navigator.pop(context);
                  _toggleConversationMute(conversation);
                },
              ),
              Divider(height: 1, thickness: 1, color: CommonTokens.lineSubtle),
              _conversationSheetTile(
                icon: Icons.delete_outline,
                title: '删除会话',
                iconColor: CommonTokens.danger,
                textColor: CommonTokens.danger,
                onTap: () async {
                  Navigator.pop(context);
                  final int? tid = conversation.targetId;
                  if (tid == null || !mounted) {
                    return;
                  }
                  final success = await context
                      .read<MessageProvider>()
                      .deleteConversation(
                        tid,
                        type: conversation.type ?? 1,
                      );
                  if (!mounted) {
                    return;
                  }
                  if (success) {
                    ImFeedback.showSuccess(context, '已删除会话');
                  } else {
                    ImFeedback.showError(
                      context,
                      context.read<MessageProvider>().error ?? '删除失败',
                    );
                  }
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title,
              style: CommonTokens.caption.copyWith(
                color: CommonTokens.textTertiary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          ...requests.map(
            (FriendRequestDTO request) => Column(
              children: <Widget>[
                _buildRequestCard(
                  request,
                  showActions: showActions,
                  subtitle: emptySubtitle,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: CommonTokens.lineSubtle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(FriendDTO friend) {
    final info = friend.friendUserInfo;
    final String rowTitle = ProfileDisplayTexts.singleChatDisplayTitle(
      peer: info,
      friendRemark: friend.remark,
      nameFallback: null,
    );
    final isOnline = (info?.onlineStatus ?? 0) == 1;
    final signature = info?.signature ?? '';
    final subtitle = signature.isNotEmpty
        ? '${_statusTextFromFriend(friend)} · $signature'
        : _statusTextFromFriend(friend);
    final String? avatarUrl = httpOrHttpsAvatarUrlOrNull(info?.avatar);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ProfileListAvatar(
            title: rowTitle,
            imageUrl: avatarUrl,
            size: 52,
          ),
          title: Text(
            rowTitle,
            style: TextStyle(
              color: UiTokens.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
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
                  style: TextStyle(
                    color: UiTokens.textSecondary,
                    fontSize: 13,
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
        Divider(
          height: 1,
          thickness: 1,
          indent: 72,
          color: CommonTokens.lineSubtle,
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final friendProvider = context.watch<FriendProvider>();

    final tabs = <Widget>[
      Scaffold(
        backgroundColor: ConversationUiTokens.pageBackground,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            '会话',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          toolbarHeight: 42,
          leadingWidth: 48,
          leading: const SizedBox(width: 48, height: 48),
          titleSpacing: 0,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: ConversationUiTokens.pageBackground,
          foregroundColor: UiTokens.textPrimary,
          surfaceTintColor: Colors.transparent,
          actions: <Widget>[
            SizedBox(
              width: 48,
              height: 48,
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.white.withValues(alpha: 0.10),
                  highlightColor: Colors.white.withValues(alpha: 0.06),
                ),
                child: Builder(
                  builder: (BuildContext buttonCtx) {
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(Icons.add, size: 26),
                      tooltip: '快捷操作',
                      onPressed: () => _showHomePlusMenu(buttonCtx),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: _buildMessagesTab(messageProvider, friendProvider),
      ),
      Scaffold(
        backgroundColor: UiTokens.backgroundGray,
        appBar: AppBar(
          title: const Text('好友'),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: UiTokens.backgroundGray,
          foregroundColor: UiTokens.textPrimary,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: _openAddFriendPage,
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: '添加好友',
            ),
          ],
        ),
        body: ColoredBox(
          color: UiTokens.backgroundGray,
          child: _buildFriendsTab(friendProvider),
        ),
      ),
      const GroupListScreen(),
      Scaffold(
        backgroundColor: ConversationUiTokens.pageBackground,
        appBar: AppBar(
          title: const Text(
            '我的',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          toolbarHeight: 44,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: ConversationUiTokens.pageBackground,
          foregroundColor: UiTokens.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        body: const MeScreen(),
      ),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: '会话',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        activeIcon: Icon(Icons.people),
        label: '好友',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups_outlined),
        activeIcon: Icon(Icons.groups),
        label: '群组',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: '我的',
      ),
    ];

    return Scaffold(
      backgroundColor: ConversationUiTokens.pageBackground,
      body: tabs[_currentIndex],
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: ConversationUiTokens.surface,
          border: Border(
            top: BorderSide(color: CommonTokens.lineSubtle),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: CommonTokens.brandBlue,
          unselectedItemColor:
              CommonTokens.textSecondary.withValues(alpha: 0.55),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CommonTokens.textSecondary.withValues(alpha: 0.55),
          ),
          elevation: 0,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: items,
        ),
      ),
    );
  }
}

/// 指向「+」的小三角，与 [_HomeScreenState._plusMenuSurface] 同色以无缝贴合。
class _PlusMenuCaret extends StatelessWidget {
  const _PlusMenuCaret({required this.color});

  final Color color;

  static const Size _size = Size(12, 7);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: _size,
      painter: _PlusMenuCaretPainter(color: color),
    );
  }
}

class _PlusMenuCaretPainter extends CustomPainter {
  const _PlusMenuCaretPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PlusMenuCaretPainter oldDelegate) =>
      oldDelegate.color != color;
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
