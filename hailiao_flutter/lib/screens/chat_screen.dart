import 'dart:async';
import 'dart:io';
import 'dart:math' show max;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hailiao_flutter/config/im_feature_flags.dart';
import 'package:hailiao_flutter/im/im_event_bridge.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/call_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/call_screen.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/services/call_signal_bridge.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_app_bar.dart';
import 'package:hailiao_flutter/widgets/chat/chat_app_bar_title.dart';
import 'package:hailiao_flutter/widgets/chat/chat_body.dart';
import 'package:hailiao_flutter/widgets/chat/chat_attach_panel.dart';
import 'package:hailiao_flutter/widgets/chat/chat_composer_column.dart';
import 'package:hailiao_flutter/widgets/chat/chat_emoji_panel.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_actions_sheet.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_timeline.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';
import 'package:hailiao_flutter/widgets/chat/chat_selection_summary_bar.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_body_types.dart';
import 'package:hailiao_flutter/widgets/chat/chat_thread_message_item.dart';
import 'package:hailiao_flutter/widgets/chat/message_dto_chat_display.dart';
import 'package:hailiao_flutter/widgets/common/app_empty_state.dart';
import 'package:hailiao_flutter/widgets/common/chat_page_scaffold.dart';
import 'package:hailiao_flutter/widgets/common/wx_bottom_sheet_shell.dart';
import 'package:hailiao_flutter/widgets/common/wx_search_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wukongimfluttersdk/wkim.dart';

/// [ListView.builder] 稳定 key：clientMsgNo → id → 字段指纹（禁止用 index）。
String chatMessageListItemValueKey(MessageDTO message) {
  final String? no = message.clientMsgNo?.trim();
  if (no != null && no.isNotEmpty) {
    return 'msg-cmn-$no';
  }
  final int? id = message.id;
  if (id != null) {
    return 'msg-id-$id';
  }
  final String fb =
      '${message.fromUserId}_${message.toUserId}_${message.groupId}_${message.createdAt}_${message.content}';
  return 'msg-fb-${fb.hashCode}';
}

abstract class ChatScreenApi {
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId);
  Future<ResponseDTO<List<MessageDTO>>> searchMessages(
    String keyword, {
    int page,
    int size,
  });
  Future<ResponseDTO<List<MessageDTO>>> searchGroupMessages(
    int groupId,
    String keyword, {
    int page,
    int size,
  });
}

class ApiChatScreenApi implements ChatScreenApi {
  const ApiChatScreenApi();

  @override
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId) {
    return ApiService.getUserOnlineInfo(userId);
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> searchMessages(
    String keyword, {
    int page = 1,
    int size = 50,
  }) {
    return ApiService.searchMessages(keyword, page: page, size: size);
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> searchGroupMessages(
    int groupId,
    String keyword, {
    int page = 1,
    int size = 50,
  }) {
    return ApiService.searchGroupMessages(
      groupId,
      keyword,
      page: page,
      size: size,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, ChatScreenApi? api})
    : api = api ?? const ApiChatScreenApi();

  final ChatScreenApi api;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  Timer? _privateReadSyncTimer;

  bool _initialized = false;
  bool _isTyping = false;
  bool _isEmojiPanelOpen = false;
  bool _isAttachPanelOpen = false;
  bool _isVoiceMode = false;
  final FocusNode _composerFocus = FocusNode();
  bool _loadingHistory = false;
  bool _hasMoreHistory = true;
  bool _selectionHintShown = false;
  int? _targetId;
  int? _type;
  int _currentPage = 1;
  String _title = '聊天';
  String? _avatarUrl;
  String? _statusText;
  /// 历史分页插入后，在该索引前增加轻分隔（与上一条有时间/日期断点时不重复绘制）。
  int? _historyBoundaryIndex;
  int? _highlightedMessageId;
  final Set<int> _selectedMessageIds = <int>{};
  MessageDTO? _replyingTo;
  MessageDTO? _editingMessage;

  static const int _pageSize = 20;

  /// 判断「贴近底部」：距最大滚动量不超过此值则 composer / 面板高度变化后自动贴底。
  static const double _nearBottomScrollThreshold = 80;

  /// [composerHeight + bottomPanelHeight + safeAreaBottom] 签名，用于统一底部模型只做一套贴底。
  String _lastBottomLayoutSignature = '';

  /// 底部布局变化后单次 [jumpTo(max)]，避免多路 postFrame 争抢。
  bool _bottomAnchorJumpScheduled = false;

  /// 上一帧用于 IME ↔ 表情 / + 号过渡检测（先于 [_syncBottomAnchorIfLayoutChanged] 内更新）。
  double _bottomAnchorTrackPrevInsets = 0;
  bool _bottomAnchorTrackPrevEmoji = false;
  bool _bottomAnchorTrackPrevAttach = false;

  /// IME 与自定义面板切换中推迟贴底，待 [_tryCompensateAfterImePanelTransition] 稳态再 jump。
  bool _pendingStablePanelAnchorAfterImeTransition = false;

  /// 检测 thread 条数是否增加（IM/REST）；仅在「非拉更早历史」且条数变多时触发滚底。
  int? _prevThreadLenForAutoScroll;

  /// 避免对同一条对方消息重复 [markAsRead]（幂等仍少打接口）。
  int? _lastPeerMessageMarkReadId;
  String? _lastPeerMessageMarkReadClientMsgNo;

  /// 分页拉取更早消息导致 thread 变长时，不要自动滚到底（避免打断用户回看）。
  bool _suppressAutoScrollOnNextThreadGrow = false;

  /// 私聊已读：[threadMessages.length] 增长检测基线（与滚底解耦）。
  int? _prevThreadLenForRead;

  /// 首轮 [reset: true] 历史落地并切回实时流后为 true，即时已读增长判断依赖此门闸。
  bool _chatInitSequenceComplete = false;

  /// 会话列表拉取仅在 post-frame 触发一次，避免 [loadConversations] 内 notify 落在 build 生命周期。
  bool _scheduledLoadConversations = false;

  /// 首屏滚底完成前禁止「贴顶自动拉更早一页」，避免 page2 prepend 打断首屏。
  bool _suppressPrependHistoryUntilInitialScrollSettled = true;

  /// 首屏消息区：在切回 Provider 实时列表前，用本地快照渲染，避免用户看到 thread 的“生长过程”。
  List<MessageDTO> _firstPaintSnapshotMessages = const [];

  /// 首屏 handoff 未完成（遮罩 / 禁止 prepend 等）。与数据源解耦：[build] 中 messages 另见 [_freezeFirstPaintDataSource]。
  bool _useFirstPaintSnapshot = true;

  /// page1 已写入快照列表，可供首帧稳定绘制。
  bool _firstPaintSnapshotReady = false;

  /// revealed 后短暂保持 [_firstPaintSnapshotMessages] 作为列表数据源，再切 [liveThreadMessages]，避免换数据瞬时高度差导致「吸一下」。
  bool _freezeFirstPaintDataSource = false;

  /// 首屏 [jumpTo(maxScrollExtent)] 已完成，才允许用户看到消息区（避免先见默认 offset 再跳底的「弹出感」）。
  bool _firstPaintSnapshotRevealed = false;

  /// 避免 [setState] 切实时流被嵌套调用多次。
  bool _switchingOffFirstPaintSnapshot = false;

  MessageProvider? _messageProviderBinding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _composerFocus.addListener(_onComposerFocusChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncPrivateOutgoingReadIfOpen();
    }
  }

  void _onComposerFocusChanged() {
    if (!mounted) {
      return;
    }
    if (!_composerFocus.hasFocus) {
      return;
    }
    if (!_isEmojiPanelOpen &&
        !_isAttachPanelOpen &&
        !_isVoiceMode) {
      return;
    }
    setState(() {
      _isEmojiPanelOpen = false;
      _isAttachPanelOpen = false;
      _isVoiceMode = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageProviderBinding ??= context.read<MessageProvider>();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _scrollController.addListener(_handleScroll);
    _initializeChat();
  }

  @override
  void dispose() {
    _scheduledLoadConversations = false;
    _suppressPrependHistoryUntilInitialScrollSettled = true;
    _messageProviderBinding?.clearActiveConversation();
    _lastPeerMessageMarkReadId = null;
    _lastPeerMessageMarkReadClientMsgNo = null;
    WidgetsBinding.instance.removeObserver(this);
    _privateReadSyncTimer?.cancel();
    _composerFocus.removeListener(_onComposerFocusChanged);
    _composerFocus.dispose();
    _scrollController.removeListener(_handleScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    _chatInitSequenceComplete = false;
    _suppressPrependHistoryUntilInitialScrollSettled = true;
    _firstPaintSnapshotMessages = const [];
    _firstPaintSnapshotReady = false;
    _firstPaintSnapshotRevealed = false;
    _freezeFirstPaintDataSource = false;
    _useFirstPaintSnapshot = true;
    _switchingOffFirstPaintSnapshot = false;
    _lastBottomLayoutSignature = '';
    _bottomAnchorTrackPrevInsets = 0;
    _bottomAnchorTrackPrevEmoji = false;
    _bottomAnchorTrackPrevAttach = false;
    _pendingStablePanelAnchorAfterImeTransition = false;
    if (kDebugMode) {
      debugPrint('[im.chat.audit] _initializeChat enter');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<BlacklistProvider>().loadBlacklist();
    });
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _targetId = args?['targetId'] as int? ?? 1;
    _type = args?['type'] as int? ?? 1;
    _title = args?['title'] as String? ?? '聊天';
    _avatarUrl =
        args?['avatarUrl'] as String? ??
        args?['avatar'] as String?;
    _currentPage = 1;
    _hasMoreHistory = true;
    _loadingHistory = false;
    _historyBoundaryIndex = null;

    final AuthProvider authReader = context.read<AuthProvider>();
    final int? viewerId = _effectiveViewerForThread(authReader);
    if (kDebugMode && _type == 1) {
      debugPrint(
        '[im.chat] open private peer=$_targetId viewer=$viewerId '
        '(authMessaging=${authReader.messagingUserId} wkUid=${WKIM.shared.options.uid})',
      );
    }
    final provider = context.read<MessageProvider>();
    provider.setActiveConversation(_targetId!, _type!);
    if (_scheduledLoadConversations) {
      return;
    }
    _scheduledLoadConversations = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeChatLoadConversationsPhase());
    });
  }

  /// 首帧 build 结束后再 [loadConversations]（内部 notify），随后与原顺序一致拉历史 / 已读等。
  Future<void> _initializeChatLoadConversationsPhase() async {
    if (!mounted) {
      _scheduledLoadConversations = false;
      return;
    }
    final MessageProvider provider = context.read<MessageProvider>();
    final int? viewerInit =
        _effectiveViewerForThread(context.read<AuthProvider>());
    provider.retainEphemeralMessagesForChat(
      _targetId!,
      _type!,
      currentUserId: viewerInit,
    );
    await provider.loadConversations();
    if (!mounted) {
      _scheduledLoadConversations = false;
      return;
    }
    _hydrateConversationMeta(provider.conversations);
    _restoreDraft(provider.conversations);

    await _loadHistoryPage(page: 1, reset: true);
    if (!mounted) {
      return;
    }
    final int? viewerAfterHistory =
        _effectiveViewerForThread(context.read<AuthProvider>());
    final List<MessageDTO> prepared =
        List<MessageDTO>.from(_threadMessages(provider, viewerAfterHistory));
    setState(() {
      _firstPaintSnapshotMessages = prepared;
      _firstPaintSnapshotReady = true;
      _useFirstPaintSnapshot = true;
      _freezeFirstPaintDataSource = false;
    });
    _scheduleFirstPaintSnapshotHandoff();
  }

  void _postFrame(void Function() fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      fn();
    });
  }

  /// 首屏快照已就绪：双帧 layout → 遮罩下 [jumpTo] 底 → 揭遮罩 → 冻数据源 1 帧 → 对齐 live → 底距守恒滚轮 → 再副作用。
  void _scheduleFirstPaintSnapshotHandoff() {
    if (!mounted || !_firstPaintSnapshotReady) {
      return;
    }
    if (_firstPaintSnapshotMessages.isEmpty) {
      _postFrame(() {
        _postFrame(() {
          if (!mounted) {
            return;
          }
          setState(() {
            _firstPaintSnapshotRevealed = true;
            _useFirstPaintSnapshot = false;
            _freezeFirstPaintDataSource = false;
            _chatInitSequenceComplete = true;
            _suppressPrependHistoryUntilInitialScrollSettled = false;
          });
          _prevThreadLenForAutoScroll = 0;
          _prevThreadLenForRead = 0;
          unawaited(_completeOpenChatSideEffects());
        });
      });
      return;
    }
    _postFrame(() {
      _postFrame(() {
        if (_scrollController.hasClients) {
          final double max = _scrollController.position.maxScrollExtent;
          if (max > 0) {
            _scrollController.jumpTo(max);
          }
        }
        _postFrame(() {
          setState(() {
            _firstPaintSnapshotRevealed = true;
          });
          _postFrame(_lingerSnapshotThenHandoffToLive);
        });
      });
    });
  }

  void _lingerSnapshotThenHandoffToLive() {
    if (!mounted) {
      return;
    }
    setState(() {
      _useFirstPaintSnapshot = false;
      _freezeFirstPaintDataSource = true;
    });
    _postFrame(() => _trySwitchFirstPaintDataToLive(alignAttempt: 0));
  }

  /// snapshot 与 live 在尾部是否可用同一「强键」对齐（id 或 clientMsgNo 至少一侧非空且相等）。
  bool _snapshotTailStrongKeyMatch(MessageDTO a, MessageDTO b) {
    final int? idA = a.id;
    final int? idB = b.id;
    if (idA != null && idB != null && idA == idB) {
      return true;
    }
    final String? cA = a.clientMsgNo?.trim();
    final String? cB = b.clientMsgNo?.trim();
    if (cA != null &&
        cA.isNotEmpty &&
        cB != null &&
        cB.isNotEmpty &&
        cA == cB) {
      return true;
    }
    return false;
  }

  /// 仅在 live 与首屏快照足够一致时才切流，避免 snapshot→live 那一帧视觉抖动。
  bool _canSwitchFromSnapshotToLive(
    List<MessageDTO> snapshot,
    List<MessageDTO> live,
  ) {
    if (snapshot.isEmpty && live.isEmpty) {
      return true;
    }
    if (snapshot.length != live.length) {
      return false;
    }
    if (snapshot.isEmpty || live.isEmpty) {
      return false;
    }
    final MessageDTO sLast = snapshot.last;
    final MessageDTO lLast = live.last;
    if (!_snapshotTailStrongKeyMatch(sLast, lLast)) {
      return false;
    }
    final int n = snapshot.length < 5 ? snapshot.length : 5;
    for (int k = 0; k < n; k++) {
      final int i = snapshot.length - 1 - k;
      final MessageDTO s = snapshot[i];
      final MessageDTO l = live[i];
      if (!_snapshotTailStrongKeyMatch(s, l)) {
        return false;
      }
      if (s.isRead != l.isRead) {
        return false;
      }
      if (s.status != l.status) {
        return false;
      }
      if (s.msgType != l.msgType) {
        return false;
      }
    }
    return true;
  }

  /// 冻数据源阶段：对齐 live 与快照后再切数据，并用距底守恒修正 scroll（[alignAttempt] 最多顺延 3 帧）。
  void _trySwitchFirstPaintDataToLive({int alignAttempt = 0}) {
    if (!mounted ||
        !_firstPaintSnapshotReady ||
        !_firstPaintSnapshotRevealed ||
        !_freezeFirstPaintDataSource) {
      return;
    }
    final int? v = _effectiveViewerForThread(context.read<AuthProvider>());
    final List<MessageDTO> live = List<MessageDTO>.from(
      _threadMessages(context.read<MessageProvider>(), v),
    );
    final List<MessageDTO> snapshot = _firstPaintSnapshotMessages;

    final bool aligned = _canSwitchFromSnapshotToLive(snapshot, live);
    if (!aligned && alignAttempt < 3) {
      _postFrame(() => _trySwitchFirstPaintDataToLive(alignAttempt: alignAttempt + 1));
      return;
    }

    if (_switchingOffFirstPaintSnapshot) {
      return;
    }
    _switchingOffFirstPaintSnapshot = true;
    final int snapLen = _firstPaintSnapshotMessages.length;
    _prevThreadLenForAutoScroll = snapLen;
    _prevThreadLenForRead = snapLen;
    _suppressPrependHistoryUntilInitialScrollSettled = false;

    double? preserveDistanceFromBottom;
    if (_scrollController.hasClients) {
      final ScrollPosition pos = _scrollController.position;
      preserveDistanceFromBottom = pos.maxScrollExtent - pos.pixels;
    }

    setState(() {
      _freezeFirstPaintDataSource = false;
      _chatInitSequenceComplete = true;
    });
    _switchingOffFirstPaintSnapshot = false;

    _postFrame(() {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final ScrollPosition pos = _scrollController.position;
      final double newMax = pos.maxScrollExtent;
      final double minExt = pos.minScrollExtent;
      if (preserveDistanceFromBottom != null) {
        final double target = newMax - preserveDistanceFromBottom;
        _scrollController.jumpTo(target.clamp(minExt, newMax));
      } else if (newMax > 0) {
        _scrollController.jumpTo(newMax);
      }
      _postFrame(() {
        if (mounted) {
          unawaited(_completeOpenChatSideEffects());
        }
      });
    });
  }

  Future<void> _completeOpenChatSideEffects() async {
    if (!mounted) {
      return;
    }
    final MessageProvider provider = context.read<MessageProvider>();
    if (_targetId != null) {
      final bool readOk = await provider.markAsRead(_targetId!, type: _type!);
      if (!mounted) {
        return;
      }
      if (_type == 1 && readOk) {
        await _syncOutgoingReadImmediate();
      }
    }
    if (!mounted) {
      return;
    }
    if (_type == 1 && _targetId != null) {
      await _loadPresence(_targetId!);
      _privateReadSyncTimer?.cancel();
      _privateReadSyncTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted) {
          return;
        }
        _syncPrivateOutgoingReadIfOpen();
      });
    } else {
      _privateReadSyncTimer?.cancel();
      _privateReadSyncTimer = null;
    }
    if (!mounted) {
      return;
    }
    if (_type == 2) {
      context.read<GroupProvider>().loadGroups();
    }
  }

  /// 私聊：对齐服务端「对方已读」后写回的 [MessageDTO.isRead]，便于双勾更新（无 IM 已读推送时的兜底）。
  void _syncPrivateOutgoingReadIfOpen() {
    if (_type != 1 || _targetId == null) {
      return;
    }
    final int? viewerId =
        _effectiveViewerForThread(context.read<AuthProvider>());
    if (viewerId == null) {
      return;
    }
    context.read<MessageProvider>().syncPrivateOutgoingReadFlags(
          _targetId!,
          viewerUserId: viewerId,
        );
  }

  /// [markAsRead] 成功后立刻从 REST 对齐「我→对方」的 [isRead]，规避 IM [readed] 延迟或未命中。
  Future<void> _syncOutgoingReadImmediate() async {
    if (!mounted || _type != 1 || _targetId == null) {
      return;
    }
    final int? viewerId =
        _effectiveViewerForThread(context.read<AuthProvider>());
    if (viewerId == null) {
      return;
    }
    await context.read<MessageProvider>().syncPrivateOutgoingReadFlags(
          _targetId!,
          viewerUserId: viewerId,
          skipIfRecentReadEvent: Duration.zero,
        );
  }

  Future<void> _runMarkReadThenSyncOutgoing() async {
    if (!mounted || _type != 1 || _targetId == null) {
      return;
    }
    final MessageProvider provider = context.read<MessageProvider>();
    if (!provider.isActiveConversation(_targetId!, _type!)) {
      return;
    }
    final bool ok = await provider.markAsRead(_targetId!, type: _type!);
    if (mounted && ok) {
      await _syncOutgoingReadImmediate();
    }
  }

  void _hydrateConversationMeta(List<ConversationDTO> conversations) {
    for (final ConversationDTO item in conversations) {
      if (item.targetId == _targetId && item.type == _type) {
        _avatarUrl ??= item.avatar;
        if ((item.name ?? '').trim().isNotEmpty) {
          _title = item.name!.trim();
        }
        break;
      }
    }
  }

  void _cacheDraft(String value) {
    context.read<MessageProvider>().setDraft(_targetId, _type, value);
  }

  void _restoreDraft(List<ConversationDTO> conversations) {
    final cachedDraft = context.read<MessageProvider>().getDraft(_targetId, _type);
    String? conversationDraft;
    for (final item in conversations) {
      if (item.targetId == _targetId &&
          item.type == _type &&
          item.draft != null &&
          item.draft!.trim().isNotEmpty) {
        conversationDraft = item.draft;
        break;
      }
    }
    final draft = cachedDraft ?? conversationDraft;
    if (draft == null || draft.isEmpty) {
      return;
    }
    _messageController.text = draft;
    _messageController.selection = TextSelection.collapsed(
      offset: draft.length,
    );
    _isTyping = draft.isNotEmpty;
  }

  /// 与 [ImEventBridge._effectiveMapperUserId] / IM 私聊 to/from 映射一致，避免 Windows 等场景 Auth 与 WK uid 短暂不一致时 [messagesForChat] 整条过滤掉 IM 行。
  int? _effectiveViewerForThread(AuthProvider auth) {
    final int? a = auth.messagingUserId;
    if (a != null) {
      return a;
    }
    final String? u = WKIM.shared.options.uid;
    if (u == null || u.isEmpty) {
      return null;
    }
    return int.tryParse(u);
  }

  List<MessageDTO> _threadMessages(
    MessageProvider messageProvider,
    int? viewerId,
  ) {
    final tid = _targetId;
    final typ = _type;
    if (tid == null || typ == null) {
      return const <MessageDTO>[];
    }
    final List<MessageDTO> thread = messageProvider.messagesForChat(
      targetId: tid,
      type: typ,
      currentUserId: viewerId,
    );
    if (kDebugMode) {
      debugPrint(
        '[im.chat.filter] _threadMessages len=${thread.length} '
        'target=$tid type=$typ viewer=$viewerId',
      );
    }
    return thread;
  }

  Future<void> _loadHistoryPage({
    required int page,
    bool reset = false,
  }) async {
    if (_targetId == null || _type == null) {
      return;
    }
    if (_loadingHistory) {
      return;
    }

    final bool willLoadOlder = !reset && page > 1;
    if (willLoadOlder) {
      _suppressAutoScrollOnNextThreadGrow = true;
    }

    setState(() {
      _loadingHistory = true;
    });

    final provider = context.read<MessageProvider>();
    final int? viewerId = _effectiveViewerForThread(context.read<AuthProvider>());
    final int beforeCount = _threadMessages(provider, viewerId).length;

    if (_type == 1) {
      await provider.loadPrivateMessages(
        _targetId!,
        page,
        _pageSize,
        viewerUserId: viewerId,
      );
    } else {
      await provider.loadGroupMessages(_targetId!, page, _pageSize);
    }

    if (!mounted) {
      if (willLoadOlder) {
        _suppressAutoScrollOnNextThreadGrow = false;
      }
      return;
    }

    final int afterCount = _threadMessages(provider, viewerId).length;
    final int loadedCount = reset ? afterCount : (afterCount - beforeCount);

    final String? loadErr = provider.error;
    if (loadErr != null && loadErr.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载消息失败：$loadErr'),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }

    setState(() {
      _currentPage = page;
      _hasMoreHistory = loadedCount >= _pageSize;
      _loadingHistory = false;
      if (!reset && loadedCount > 0) {
        _historyBoundaryIndex = loadedCount;
      } else if (reset) {
        _historyBoundaryIndex = null;
      }
    });
    if (reset && afterCount > 0 && kDebugMode) {
      debugPrint(
        '[im.chat.audit] _loadHistoryPage(reset) done afterCount=$afterCount',
      );
    }
    if (willLoadOlder && loadedCount <= 0) {
      _suppressAutoScrollOnNextThreadGrow = false;
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
      final lastOnline = (data['lastOnline'] ?? '').toString();
      setState(() {
        if (isOnline) {
          _statusText = '在线';
        } else if (lastOnline.isEmpty) {
          _statusText = '离线';
        } else {
          _statusText = _formatPeerLastOnlineLabel(lastOnline);
        }
      });
    } catch (_) {}
  }

  Future<void> _startCall(CallMediaType mediaType) async {
    if (_type != 1) {
      return;
    }
    final CallSignalBridge bridge = CallSignalBridge.instance;
    final CallProvider provider = CallProvider(
      callType: mediaType,
      name: _title,
      stage: CallStage.calling,
      avatarUrl: _avatarUrl,
      subtitle: _statusText,
      isMuted: false,
      isSpeakerOn: mediaType == CallMediaType.audio,
      isCameraEnabled: mediaType == CallMediaType.video,
      isFrontCamera: true,
    );
    bridge.onOutgoingStarted(provider);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CallScreen(
          name: _title,
          mediaType: mediaType,
          stage: CallStage.calling,
          avatarUrl: _avatarUrl,
          subtitle: _statusText,
          provider: provider,
          disposeProvidedProvider: true,
        ),
      ),
    );
  }

  /// [ChatInputBar] 及输入区独占行：多行按换行与 [TextField] style 估算，语音模式走单行占位。
  double _composerInputRowHeight() {
    const double barVerticalPadding = 12;
    const double sideSlot = ChatUiTokens.inputActionSize;
    if (_isVoiceMode) {
      return barVerticalPadding + ChatUiTokens.inputFieldMinHeight;
    }
    final String text = _messageController.text;
    int lines = 1;
    if (text.isNotEmpty) {
      lines = text.split('\n').length;
      final int cap = ChatUiTokens.inputFieldMaxLines.toInt();
      if (lines > cap) {
        lines = cap;
      }
    }
    const double lineHeight = 16 * 1.25;
    final double fieldH = max(
      ChatUiTokens.inputFieldMinHeight,
      lineHeight * lines,
    );
    final double rowH = max(sideSlot, fieldH);
    return barVerticalPadding + rowH;
  }

  /// Composer 内输入条以上固定条（拉黑 / 禁言 / 回复引用），不含表情或 + 内联面板。
  double _composerChromeAboveInputHeight({
    required bool isBlocked,
    required bool groupAllMuted,
    required bool replyVisible,
  }) {
    double h = 0;
    if (isBlocked) {
      h += 48;
    }
    if (groupAllMuted) {
      h += 56;
    }
    if (replyVisible) {
      h += 76;
    }
    return h;
  }

  /// 仅承载页面内自定义底栏（表情 / + 号）。系统键盘由 [Scaffold.resizeToAvoidBottomInset] 收缩布局，
  /// 不在此返回 [MediaQuery.viewInsets.bottom]，避免 list padding 与布局双算上推。
  double _resolveBottomPanelHeight(MediaQueryData mq, ChatScene scene) {
    final double ime = mq.viewInsets.bottom;
    if (ime > 0.5) {
      return 0;
    }
    if (_isEmojiPanelOpen) {
      return ChatEmojiPanel.embeddedHeight;
    }
    if (_isAttachPanelOpen) {
      final int cells = scene.isGroupChat ? 3 : 5;
      return ChatAttachPanel.embeddedHeightForItemCount(cells);
    }
    return 0;
  }

  bool _chatScrollIsNearBottom() {
    if (!_scrollController.hasClients) {
      return false;
    }
    final ScrollPosition pos = _scrollController.position;
    final double distanceFromBottom = pos.maxScrollExtent - pos.pixels;
    return distanceFromBottom <= _nearBottomScrollThreshold;
  }

  bool _firstPaintHandoffBlocksBottomAnchor() {
    return !_firstPaintSnapshotReady ||
        _useFirstPaintSnapshot ||
        _freezeFirstPaintDataSource;
  }

  /// IME 与 emoji / attach 切换的过渡帧：避免在键盘收缩尚未结束、bottomPanel 已开始计入时过早 [jumpTo]。
  static bool _isInImeCustomPanelTransition({
    required double previousViewInsetsBottom,
    required double currentViewInsetsBottom,
    required bool previousEmojiOpen,
    required bool previousAttachOpen,
    required bool currentEmojiOpen,
    required bool currentAttachOpen,
  }) {
    final bool prevIme = previousViewInsetsBottom > 0.5;
    final bool currIme = currentViewInsetsBottom > 0.5;
    final bool panelOpenChanged =
        previousEmojiOpen != currentEmojiOpen ||
        previousAttachOpen != currentAttachOpen;
    final bool prevPanel = previousEmojiOpen || previousAttachOpen;
    final bool currPanel = currentEmojiOpen || currentAttachOpen;

    if (prevIme &&
        panelOpenChanged &&
        (currIme ||
            (currentViewInsetsBottom - previousViewInsetsBottom).abs() > 1.0)) {
      return true;
    }
    if (prevPanel && !currPanel && currIme && !prevIme) {
      return true;
    }
    if (currIme && currPanel && (!prevPanel || panelOpenChanged)) {
      return true;
    }
    return false;
  }

  void _updateBottomAnchorTransitionTrack({
    required double viewInsetsBottom,
    required bool emojiOpen,
    required bool attachOpen,
  }) {
    _bottomAnchorTrackPrevInsets = viewInsetsBottom;
    _bottomAnchorTrackPrevEmoji = emojiOpen;
    _bottomAnchorTrackPrevAttach = attachOpen;
  }

  /// IME 已收起且 in-app 面板已进入 [listBottomPad]；或键盘已独占底部（自定义面板已关，避免 IME 仍可见且 emoji flag 已开但 bp 仍为 0 的过渡帧误触发）。
  bool _shouldCompensateAfterImePanelTransition(
    double viewInsetsBottom,
    double bottomPanelHeight,
  ) {
    final bool currPanel = _isEmojiPanelOpen || _isAttachPanelOpen;
    if (viewInsetsBottom <= 0.5 && bottomPanelHeight > 0.5) {
      return true;
    }
    if (viewInsetsBottom > 0.5 &&
        bottomPanelHeight <= 0.5 &&
        !currPanel) {
      return true;
    }
    return false;
  }

  void _tryCompensateAfterImePanelTransition({
    required double viewInsetsBottom,
    required double bottomPanelHeight,
  }) {
    if (!_pendingStablePanelAnchorAfterImeTransition) {
      return;
    }
    if (!_chatInitSequenceComplete || _firstPaintHandoffBlocksBottomAnchor()) {
      return;
    }
    if (!_chatScrollIsNearBottom()) {
      _pendingStablePanelAnchorAfterImeTransition = false;
      return;
    }
    if (!_shouldCompensateAfterImePanelTransition(
          viewInsetsBottom,
          bottomPanelHeight,
        )) {
      return;
    }
    _pendingStablePanelAnchorAfterImeTransition = false;
    _scheduleBottomAnchorJumpOnce();
  }

  void _scheduleBottomAnchorJumpOnce() {
    if (_bottomAnchorJumpScheduled) {
      return;
    }
    _bottomAnchorJumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bottomAnchorJumpScheduled = false;
      if (!mounted || !_chatInitSequenceComplete) {
        return;
      }
      if (_firstPaintHandoffBlocksBottomAnchor()) {
        return;
      }
      if (!_scrollController.hasClients) {
        return;
      }
      final ScrollPosition pos = _scrollController.position;
      final double maxExt = pos.maxScrollExtent;
      final double minExt = pos.minScrollExtent;
      final double target = maxExt.clamp(minExt, maxExt);
      if ((target - pos.pixels).abs() < 1.0) {
        return;
      }
      _scrollController.jumpTo(target);
    });
  }

  /// [composerHeight] / [bottomPanelHeight] / [safeAreaBottom] / [viewInsetsBottom] 签名变化且此前贴底时贴齐新 [maxScrollExtent]。
  /// [viewInsetsBottom] 仅参与签名以捕获 IME 显隐（不写进 [listBottomPad]，避免与 Scaffold 双算）。
  void _syncBottomAnchorIfLayoutChanged({
    required double composerHeight,
    required double bottomPanelHeight,
    required double safeAreaBottom,
    required double viewInsetsBottom,
  }) {
    final bool inTransition = _isInImeCustomPanelTransition(
      previousViewInsetsBottom: _bottomAnchorTrackPrevInsets,
      currentViewInsetsBottom: viewInsetsBottom,
      previousEmojiOpen: _bottomAnchorTrackPrevEmoji,
      previousAttachOpen: _bottomAnchorTrackPrevAttach,
      currentEmojiOpen: _isEmojiPanelOpen,
      currentAttachOpen: _isAttachPanelOpen,
    );

    void finishTrack() {
      _updateBottomAnchorTransitionTrack(
        viewInsetsBottom: viewInsetsBottom,
        emojiOpen: _isEmojiPanelOpen,
        attachOpen: _isAttachPanelOpen,
      );
    }

    final String sig =
        '${composerHeight.toStringAsFixed(1)}|${bottomPanelHeight.toStringAsFixed(1)}|${safeAreaBottom.toStringAsFixed(1)}|${viewInsetsBottom.toStringAsFixed(1)}';
    if (sig == _lastBottomLayoutSignature) {
      if (!inTransition) {
        _tryCompensateAfterImePanelTransition(
          viewInsetsBottom: viewInsetsBottom,
          bottomPanelHeight: bottomPanelHeight,
        );
      }
      finishTrack();
      return;
    }

    final bool keepBottom = _chatScrollIsNearBottom();
    _lastBottomLayoutSignature = sig;

    if (!_chatInitSequenceComplete) {
      finishTrack();
      return;
    }
    if (_firstPaintHandoffBlocksBottomAnchor()) {
      finishTrack();
      return;
    }
    if (!keepBottom) {
      _pendingStablePanelAnchorAfterImeTransition = false;
      finishTrack();
      return;
    }

    if (inTransition) {
      _pendingStablePanelAnchorAfterImeTransition = true;
      finishTrack();
      return;
    }

    if (_pendingStablePanelAnchorAfterImeTransition) {
      if (_shouldCompensateAfterImePanelTransition(
            viewInsetsBottom,
            bottomPanelHeight,
          )) {
        _pendingStablePanelAnchorAfterImeTransition = false;
        _scheduleBottomAnchorJumpOnce();
      }
      finishTrack();
      return;
    }

    _scheduleBottomAnchorJumpOnce();
    finishTrack();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loadingHistory || !_hasMoreHistory) {
      return;
    }
    if (_useFirstPaintSnapshot ||
        _freezeFirstPaintDataSource ||
        !_firstPaintSnapshotReady) {
      return;
    }
    if (_suppressPrependHistoryUntilInitialScrollSettled) {
      return;
    }
    if (_scrollController.position.pixels <= 80) {
      _loadHistoryPage(page: _currentPage + 1);
    }
  }

  /// 双帧后再滚：等 [maxScrollExtent] 稳定；真正滚动前再做 [hasClients] / [maxScrollExtent] 保护。
  ///
  /// [animated]==false 时 [jumpTo] 无动画；否则 [animateTo] 平滑滚底。
  void _scrollToLatest({bool animated = true}) {
    if (kDebugMode) {
      debugPrint(
        '[im.chat.audit] _scrollToLatest invoked animated=$animated',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (!_scrollController.hasClients) {
          if (kDebugMode) {
            debugPrint('[im.chat.audit] _scrollToLatest abort hasClients=false');
          }
          return;
        }
        final double max = _scrollController.position.maxScrollExtent;
        final double px = _scrollController.position.pixels;
        if (max <= 0) {
          if (kDebugMode) {
            debugPrint(
              '[im.chat.audit] _scrollToLatest skip max<=0 (already top or no overflow)',
            );
          }
          return;
        }
        if (animated) {
          if (kDebugMode) {
            debugPrint(
              '[im.chat.audit] before animateTo pixels=$px maxScrollExtent=$max',
            );
          }
          _scrollController
              .animateTo(
            max,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
              .then((_) {
            if (kDebugMode && mounted && _scrollController.hasClients) {
              debugPrint(
                '[im.chat.audit] after animateTo pixels=${_scrollController.position.pixels} '
                'maxScrollExtent=${_scrollController.position.maxScrollExtent}',
              );
            }
          });
        } else {
          if (kDebugMode) {
            debugPrint(
              '[im.chat.audit] before jumpTo pixels=$px maxScrollExtent=$max',
            );
          }
          _scrollController.jumpTo(max);
          if (kDebugMode && mounted && _scrollController.hasClients) {
            debugPrint(
              '[im.chat.audit] after jumpTo pixels=${_scrollController.position.pixels} '
              'maxScrollExtent=${_scrollController.position.maxScrollExtent}',
            );
          }
        }
      });
    });
  }

  /// 当前会话 thread 变长且非「正在拉更早历史」时滚到底（不做「仅贴近底部」门闸，避免键盘/安全区导致误判）。
  void _maybeScrollToLatestOnNewThreadMessage(
    int currentLen,
    List<MessageDTO> threadMessages,
  ) {
    if (_useFirstPaintSnapshot || _freezeFirstPaintDataSource) {
      return;
    }
    if (_targetId == null || _type == null) {
      _prevThreadLenForAutoScroll = currentLen;
      return;
    }
    if (_selectionMode) {
      _prevThreadLenForAutoScroll = currentLen;
      return;
    }

    final int? prev = _prevThreadLenForAutoScroll;
    if (prev == null) {
      _prevThreadLenForAutoScroll = currentLen;
      return;
    }
    final bool grew = currentLen > prev && !_loadingHistory;
    _prevThreadLenForAutoScroll = currentLen;

    if (grew) {
      if (_suppressAutoScrollOnNextThreadGrow) {
        _suppressAutoScrollOnNextThreadGrow = false;
        return;
      }
      if (kDebugMode) {
        debugPrint('[im.chat.scroll] thread grew $prev → $currentLen, schedule');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _loadingHistory) {
          return;
        }
        _scrollToLatest();
      });
    }
  }

  /// 私聊：thread 条数增长时尝试已读（与滚底逻辑独立）。
  void _maybeMarkPrivateReadOnThreadGrowth(List<MessageDTO> threadMessages) {
    final int currentLen = threadMessages.length;
    if (_type != 1 || _targetId == null) {
      _prevThreadLenForRead = currentLen;
      return;
    }
    if (!_chatInitSequenceComplete) {
      _prevThreadLenForRead = currentLen;
      return;
    }
    if (_loadingHistory) {
      _prevThreadLenForRead = currentLen;
      return;
    }
    if (threadMessages.isEmpty) {
      _prevThreadLenForRead = currentLen;
      return;
    }
    if (_selectionMode) {
      _prevThreadLenForRead = currentLen;
      return;
    }
    final int? prevLen = _prevThreadLenForRead;
    if (prevLen == null) {
      _prevThreadLenForRead = currentLen;
      return;
    }
    if (currentLen <= prevLen) {
      _prevThreadLenForRead = currentLen;
      return;
    }
    _prevThreadLenForRead = currentLen;
    if (kDebugMode) {
      debugPrint(
        '[im.chat.audit] thread growth read-check currentLen=$currentLen prevLen=$prevLen',
      );
    }
    _maybeMarkPrivateReadOnNewPeerLine(threadMessages);
  }

  /// 私聊：对方新消息到达且当前页正在展示该会话时，再上报一次已读（与打开会话时 [markAsRead] 互补）。
  void _maybeMarkPrivateReadOnNewPeerLine(List<MessageDTO> thread) {
    if (_type != 1 || _targetId == null || thread.isEmpty) {
      return;
    }
    final MessageProvider mp = context.read<MessageProvider>();
    final bool active = mp.isActiveConversation(_targetId!, _type!);
    if (!active) {
      if (kDebugMode) {
        debugPrint('[im.chat.audit] skip markAsRead activeConversation=false');
      }
      return;
    }
    final MessageDTO last = thread.last;
    final bool fromPeer = last.fromUserId == _targetId;
    if (kDebugMode) {
      debugPrint(
        '[im.chat.audit] last.fromUserId=${last.fromUserId} targetId=$_targetId active=$active',
      );
    }
    if (!fromPeer) {
      return;
    }
    final int? lid = last.id;
    final String? lcm = last.clientMsgNo?.trim();
    if (lid != null && lid > 0 && _lastPeerMessageMarkReadId == lid) {
      return;
    }
    if (lcm != null &&
        lcm.isNotEmpty &&
        _lastPeerMessageMarkReadClientMsgNo == lcm) {
      return;
    }
    _lastPeerMessageMarkReadId = lid;
    _lastPeerMessageMarkReadClientMsgNo = lcm;
    if (kDebugMode) {
      debugPrint('[im.chat.audit] scheduling markAsRead(peer=$_targetId)');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runMarkReadThenSyncOutgoing());
    });
  }

  bool get _selectionMode => _selectedMessageIds.isNotEmpty;

  void _toggleMessageSelection(MessageDTO message) {
    final messageId = message.id;
    if (messageId == null) {
      return;
    }
    final enteringSelectionMode = _selectedMessageIds.isEmpty;
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
    if (enteringSelectionMode && !_selectionHintShown && mounted) {
      _selectionHintShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '已进入多选模式，可在顶部筛选、转发、复制或移除所选消息。',
          ),
        ),
      );
    }
  }

  void _clearSelection() {
    if (_selectedMessageIds.isEmpty) {
      return;
    }
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  Future<void> _requestClearSelection() async {
    if (_selectedMessageIds.isEmpty) {
      return;
    }
    if (_selectedMessageIds.length < 5) {
      _clearSelection();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空选择'),
        content: Text(
          '当前已选择 ${_selectedMessageIds.length} 条消息，确定清空选择吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _clearSelection();
    }
  }

  /// 当前多选命中的消息（必须基于 [build] 里已 watch 得到的 [threadMessages]）。
  List<MessageDTO> _selectedMessagesInThread(List<MessageDTO> threadMessages) {
    final ids = _selectedMessageIds;
    return threadMessages
        .where((message) => message.id != null && ids.contains(message.id))
        .toList();
  }

  void _selectAllMessages() {
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final messages = _threadMessages(mp, viewer);
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds
        ..clear()
        ..addAll(
          messages
              .where((message) => message.id != null)
              .map((message) => message.id!),
        );
    });
  }

  void _invertSelectedMessages() {
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final messages = _threadMessages(mp, viewer);
    final currentIds = messages
        .where((message) => message.id != null)
        .map((message) => message.id!)
        .toList();
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      final next = <int>{};
      for (final id in currentIds) {
        if (!_selectedMessageIds.contains(id)) {
          next.add(id);
        }
      }
      _selectedMessageIds
        ..clear()
        ..addAll(next);
    });
  }

  void _selectMessagesForDate(String bucket) {
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final messages = _threadMessages(mp, viewer);
    final dayIds = messages
        .where((message) =>
            message.id != null && ChatMessageTimeline.dateKey(message) == bucket)
        .map((message) => message.id!)
        .toList();
    if (dayIds.isEmpty) {
      return;
    }
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds.addAll(dayIds);
    });
  }

  void _selectMessagesByType(int msgType) {
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final messages = _threadMessages(mp, viewer);
    final typeIds = messages
        .where((message) => message.id != null && message.safeBodyType == msgType)
        .map((message) => message.id!)
        .toList();
    if (typeIds.isEmpty) {
      return;
    }
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds.addAll(typeIds);
    });
  }

  void _selectMessagesBySender(bool selectMine) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final messages = _threadMessages(mp, viewer);
    final senderIds = messages
        .where(
          (message) =>
              message.id != null &&
              (selectMine
                  ? message.isSameSenderAs(currentUserId)
                  : !message.isSameSenderAs(currentUserId)),
        )
        .map((message) => message.id!)
        .toList();
    if (senderIds.isEmpty) {
      return;
    }
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds.addAll(senderIds);
    });
  }

  String _messageTypeLabel(MessageDTO message) {
    switch (message.safeBodyType) {
      case ChatMessageBodyTypes.image:
        return '图片';
      case ChatMessageBodyTypes.audio:
        return '音频';
      case ChatMessageBodyTypes.video:
        return '视频';
      case ChatMessageBodyTypes.file:
        return '文件';
      default:
        return '文本';
    }
  }

  String _messagePathLabel(MessageDTO message) {
    return (message.content ?? '').isEmpty ? '-' : message.content!;
  }

  String _selectionSummaryText(List<MessageDTO> threadMessages) {
    final messages = _selectedMessagesInThread(threadMessages);
    if (messages.isEmpty) {
      return '当前未选择消息';
    }

    final int? selfId = context.read<AuthProvider>().user?.id;
    final textCount =
        messages.where((item) => item.showsTextBubblePayload).length;
    final imageCount = messages
        .where((item) => item.safeBodyType == ChatMessageBodyTypes.image)
        .length;
    final audioCount = messages
        .where((item) => item.safeBodyType == ChatMessageBodyTypes.audio)
        .length;
    final videoCount = messages
        .where((item) => item.safeBodyType == ChatMessageBodyTypes.video)
        .length;
    final mineCount =
        messages.where((item) => item.isSameSenderAs(selfId)).length;
    final othersCount = messages.length - mineCount;

    final parts = <String>[
      if (textCount > 0) '$textCount 条文本',
      if (imageCount > 0) '$imageCount 条图片',
      if (audioCount > 0) '$audioCount 条音频',
      if (videoCount > 0) '$videoCount 条视频',
      '$mineCount 条我发的',
      '$othersCount 条对方发送',
    ];
    return parts.join(' · ');
  }

  String _mediaSummaryText(MessageDTO message) {
    return [
      '类型：${_messageTypeLabel(message)}',
      '时间：${ChatMessageTimeline.formatSeparatorLabel(message)}',
      '路径：${_messagePathLabel(message)}',
    ].join('\n');
  }

  Future<void> _showSelectionOverview() async {
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final thread = _threadMessages(mp, viewer);
    final messages = _selectedMessagesInThread(thread);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择概览',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                '已选择 ${messages.length} 条',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectionSummaryText(thread),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '可用操作',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '全选 / 反选 / 按类型选择 / 按发送方选择',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 6),
              const Text(
                '转发 / 复制摘要 / 移出当前视图',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMediaDetails(MessageDTO message) async {
    final path = message.content ?? '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_messageTypeLabel(message)}详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型：${_messageTypeLabel(message)}'),
            const SizedBox(height: 8),
            Text('时间：${ChatMessageTimeline.formatSeparatorLabel(message)}'),
            const SizedBox(height: 8),
            Text('路径：${_messagePathLabel(message)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
          if (!message.showsTextBubblePayload)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _openMediaPreview(message);
              },
              child: const Text('打开预览'),
            ),
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: _mediaSummaryText(message)),
              );
              if (!mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_messageTypeLabel(message)}摘要已复制'),
                ),
              );
            },
            child: const Text('复制摘要'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: path));
              if (!mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_messageTypeLabel(message)}路径已复制'),
                ),
              );
            },
            child: const Text('复制路径'),
          ),
        ],
      ),
    );
  }

  Future<void> _copySelectedMessagesSummary() async {
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final messages =
        _selectedMessagesInThread(_threadMessages(mp, viewer));
    if (messages.isEmpty) {
      return;
    }
    final summary = messages.length > 1
        ? '已复制 ${messages.length} 条消息摘要到剪贴板。'
        : '消息摘要已复制到剪贴板。';
    await _copyMessagesSummary(
      messages,
      title: '复制结果',
      successMessage: summary,
      trailingNote:
          '当前选择已保留，你可以继续转发或移除这一组消息。',
    );
  }

  String _messagesSummaryText(List<MessageDTO> messages) {
    final StringBuffer buffer = StringBuffer();
    for (final MessageDTO message in messages) {
      final DateTime? t = ChatMessageTimeline.tryParseMessageTime(message.createdAt);
      final String timeShort = t == null
          ? ''
          : '${t.hour.toString().padLeft(2, '0')}:'
              '${t.minute.toString().padLeft(2, '0')}';
      buffer.writeln(
        <String>[timeShort, _summary(message)]
            .where((String item) => item.isNotEmpty)
            .join(' '),
      );
    }
    return buffer.toString().trim();
  }

  Future<void> _copyMessagesSummary(
    List<MessageDTO> messages, {
    required String title,
    required String successMessage,
    String? trailingNote,
  }) async {
    if (messages.isEmpty) {
      return;
    }
    final String text = _messagesSummaryText(messages);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
    await _showBatchOperationSummary(
      title: title,
      summary: trailingNote == null ? text : '$text\n\n$trailingNote',
    );
  }

  void _removeMessagesFromSelection(Iterable<MessageDTO> messages) {
    final ids = messages
        .where((message) => message.id != null)
        .map((message) => message.id!)
        .toSet();
    if (ids.isEmpty) {
      return;
    }
    setState(() {
      _selectedMessageIds.removeAll(ids);
    });
  }

  Future<void> _focusFirstSelectedMessage() async {
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final selected = _selectedMessagesInThread(_threadMessages(mp, viewer));
    final message = selected.isNotEmpty ? selected.first : null;
    if (message?.id == null) {
      return;
    }
    await _focusMessage(message!.id);
  }

  Future<void> _removeMessagesFromCurrentView(
    List<MessageDTO> messages, {
    required String title,
    required String successMessage,
    String? trailingNote,
    bool clearSelectionAfter = false,
  }) async {
    final messageIds = messages.map((item) => item.id).whereType<int>().toList();
    if (messageIds.isEmpty) {
      return;
    }
    context.read<MessageProvider>().removeMessagesLocal(messageIds);
    if (clearSelectionAfter) {
      _clearSelection();
    } else {
      _removeMessagesFromSelection(messages);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
    await _showBatchOperationSummary(
      title: title,
      summary: trailingNote == null
          ? successMessage
          : '$successMessage\n\n$trailingNote',
    );
  }

  Future<void> _showBatchOperationSummary({
    required String title,
    required String summary,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _targetId == null ||
        _type == null) {
      return;
    }
    final MessageProvider provider = context.read<MessageProvider>();
    final ImEventBridge imBridge = context.read<ImEventBridge>();
    final content = EmojiList.replaceEmojisWithPlaceholders(
      _messageController.text.trim(),
    );
    bool success;

    final AuthProvider auth = context.read<AuthProvider>();
    final int? fromUid = auth.messagingUserId;

    if (_editingMessage?.id != null) {
      success = await provider.editMessage(_editingMessage!.id!, content);
    } else if (_replyingTo?.id != null) {
      if (fromUid == null) {
        success = false;
      } else {
        final int localId = provider.addOptimisticTextMessage(
          targetId: _targetId!,
          type: _type!,
          content: content,
          fromUserId: fromUid,
          replyToMsgId: _replyingTo!.id,
        );
        if (localId == 0) {
          success = false;
        } else {
          success = await provider.replyMessage(
            replyToMsgId: _replyingTo!.id!,
            toUserId: _type == 1 ? _targetId : null,
            groupId: _type == 1 ? null : _targetId,
            content: content,
            optimisticLocalId: localId,
          );
        }
      }
    } else {
      if (fromUid == null) {
        success = false;
      } else {
        final int localId = provider.addOptimisticTextMessage(
          targetId: _targetId!,
          type: _type!,
          content: content,
          fromUserId: fromUid,
        );
        if (localId == 0) {
          success = false;
        } else {
          final bool restOk = _type == 1
              ? await provider.sendPrivateTextMessage(
                    _targetId!,
                    content,
                    1,
                    optimisticLocalId: localId,
                  )
              : await provider.sendGroupTextMessage(
                    _targetId!,
                    content,
                    1,
                    optimisticLocalId: localId,
                  );
          if (restOk && !ImFeatureFlags.omitClientDirectImAfterRest) {
            await imBridge.sendTextMessage(
              targetId: _targetId!,
              type: _type!,
              text: content,
            );
          }
          success = restOk;
        }
      }
    }

    if (!mounted || !success) {
      return;
    }

    _messageController.clear();
    context.read<MessageProvider>().clearDraft(_targetId, _type);
    setState(() {
      _isTyping = false;
      _replyingTo = null;
      _editingMessage = null;
      _isEmojiPanelOpen = false;
      _isAttachPanelOpen = false;
      _isVoiceMode = false;
    });
    _scrollToLatest();
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(source: source);
    if (file == null || _targetId == null || _type == null) {
      return;
    }
    await _sendImageFromPath(file.path);
  }

  Future<void> _pickAndSendVideo() async {
    final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (file == null || _targetId == null || _type == null) {
      return;
    }
    await _sendVideoFromPath(file.path);
  }

  Future<void> _sendImageFromPath(String path) async {
    if (_targetId == null || _type == null) {
      return;
    }
    final int? uid = context.read<AuthProvider>().messagingUserId;
    if (uid == null) {
      return;
    }
    final MessageProvider provider = context.read<MessageProvider>();
    final int localId = provider.addOptimisticMediaMessage(
      targetId: _targetId!,
      type: _type!,
      msgType: ChatMessageBodyTypes.image,
      content: path,
      fromUserId: uid,
    );
    if (localId == 0) {
      return;
    }
    if (mounted) {
      _scrollToLatest();
    }

    final String? url = await provider.sendChatImageRest(
      targetId: _targetId!,
      chatType: _type!,
      filePath: path,
      optimisticLocalId: localId,
    );
    if (!mounted) {
      return;
    }
    if (url != null && url.isNotEmpty) {
      await context.read<ImEventBridge>().sendImageMessage(
            targetId: _targetId!,
            type: _type!,
            remoteUrl: url,
          );
    }
    _scrollToLatest();
  }

  Future<void> _sendVideoFromPath(String path) async {
    if (_targetId == null || _type == null) {
      return;
    }
    final success = await context.read<MessageProvider>().sendVideoMessage(
          _targetId!,
          path,
          isGroup: _type != 1,
        );
    if (!mounted) {
      return;
    }
    if (success) {
      _scrollToLatest();
      return;
    }
  }

  Future<void> _sendAudioFromPath(
    String path, {
    int duration = 0,
  }) async {
    if (_targetId == null || _type == null) {
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      _showRetrySnackBar(
        message: '未找到音频文件，请检查本地路径。',
        onRetry: () async {
          _promptAudioPathAndSend(initialPath: path, initialDuration: duration);
        },
      );
      return;
    }

    final success = await context.read<MessageProvider>().sendAudioMessage(
          _targetId!,
          path,
          duration,
          isGroup: _type != 1,
        );
    if (!mounted) {
      return;
    }
    if (success) {
      _scrollToLatest();
      return;
    }
  }

  Future<void> _promptAudioPathAndSend({
    String initialPath = '',
    int initialDuration = 0,
  }) async {
    final pathController = TextEditingController(text: initialPath);
    final durationController = TextEditingController(
      text: initialDuration > 0 ? initialDuration.toString() : '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('发送音频'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: '本地文件路径',
                  hintText: 'E:\\Music\\voice.mp3',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '时长（秒）',
                  hintText: '可选',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final path = pathController.text.trim();
              final duration = int.tryParse(durationController.text.trim()) ?? 0;
              Navigator.pop(dialogContext);
              if (path.isEmpty) {
                _showRetrySnackBar(
                  message: '请输入音频文件路径。',
                  onRetry: () async {
                    await _promptAudioPathAndSend(
                      initialPath: path,
                      initialDuration: duration,
                    );
                  },
                );
                return;
              }
              _sendAudioFromPath(path, duration: duration);
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  Future<void> _recallMessage(MessageDTO message) async {
    if (message.id == null) {
      return;
    }
    final success = await context.read<MessageProvider>().recallMessage(
          message.id!,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '消息已撤回' : '撤回失败')),
    );
  }

  void _showRetrySnackBar({
    required String message,
    required Future<void> Function() onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '重试',
          onPressed: () {
            onRetry();
          },
        ),
      ),
    );
  }

  Future<void> _openUserDetail() async {
    if (_selectionMode) {
      return;
    }
    if (_type != 1 || _targetId == null) {
      return;
    }
    await Navigator.pushNamed(
      context,
      '/user-detail',
      arguments: {'userId': _targetId},
    );
  }

  String _summary(MessageDTO? message) =>
      message == null ? '' : message.replyPreviewSummary;

  String? _audioDurationLabel(MessageDTO message) {
    final String extra = (message.extra ?? '').trim();
    if (extra.isEmpty) {
      return null;
    }

    final Match? match = RegExp(
      r'(?:duration|len|length|时长)?\D*(\d{1,4})\s*(?:s|sec|secs|秒)?',
      caseSensitive: false,
    ).firstMatch(extra);
    if (match == null) {
      return extra.length <= 14 ? extra : null;
    }

    final int? seconds = int.tryParse(match.group(1) ?? '');
    if (seconds == null) {
      return null;
    }
    if (seconds < 60) {
      return '$seconds秒';
    }
    final int minutes = seconds ~/ 60;
    final int remain = seconds % 60;
    return '$minutes分${remain.toString().padLeft(2, '0')}秒';
  }

  Future<void> _openMediaPreview(MessageDTO message) async {
    final path = message.content ?? '';
    if (path.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: message.safeBodyType == ChatMessageBodyTypes.image
                      ? (path.startsWith('http')
                          ? InteractiveViewer(
                              child: Image.network(
                                path,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (BuildContext c, Object e, StackTrace? s) =>
                                        const Text(
                                  '图片预览加载失败。',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          : InteractiveViewer(
                              child: Image.file(
                                File(path),
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (BuildContext c, Object e, StackTrace? s) =>
                                        const Text(
                                  '图片预览加载失败。',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle_fill,
                              size: 72,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '暂未内嵌视频预览。',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              path,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                await _openMediaDetails(message);
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text('查看详情'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _openMediaDetails(message);
                },
                icon: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeerLastOnlineLabel(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.contains('隐藏')) {
      return trimmed;
    }
    final DateTime? t = ChatMessageTimeline.tryParseMessageTime(trimmed);
    if (t == null) {
      return trimmed.startsWith('最后') ? trimmed : '最后在线 $trimmed';
    }
    final Duration diff = DateTime.now().difference(t);
    if (diff.isNegative) {
      return '离线';
    }
    if (diff.inMinutes < 1) {
      return '刚刚在线';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前在线';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}小时前在线';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}天前在线';
    }
    return '离线';
  }

  String _groupSubtitleLine(GroupDTO? g, ConversationDTO? conv) {
    final List<String> parts = <String>[];
    final int? n = g?.memberCount;
    if (n != null && n > 0) {
      parts.add('$n人');
    } else {
      parts.add('群聊');
    }
    if (g?.isMute == true) {
      parts.add('全员禁言');
    }
    if (conv?.isMute == true) {
      parts.add('免打扰');
    }
    if (parts.length == 1) {
      return parts.first;
    }
    return parts.take(3).join(' · ');
  }

  Future<void> _retryOutgoingFailed(MessageDTO message) async {
    if (_targetId == null || _type == null || message.id == null) {
      return;
    }
    final int? uid = context.read<AuthProvider>().messagingUserId;
    if (uid == null) {
      return;
    }
    final int mt = message.safeBodyType;
    if (mt == ChatMessageBodyTypes.text) {
      await _retryOutgoingText(messageId: message.id!);
    } else if (mt == ChatMessageBodyTypes.image ||
        mt == ChatMessageBodyTypes.video) {
      await _retryOutgoingMedia(messageId: message.id!);
    }
  }

  Future<void> _retryOutgoingText({required int messageId}) async {
    if (_targetId == null || _type == null) {
      return;
    }
    final int? uid = context.read<AuthProvider>().messagingUserId;
    if (uid == null) {
      return;
    }
    final MessageProvider provider = context.read<MessageProvider>();
    final String? text = provider.prepareRetryFailedTextMessage(
      messageId: messageId,
      targetId: _targetId!,
      type: _type!,
      fromUserId: uid,
    );
    if (text == null || !mounted) {
      return;
    }
    final bool restOk = _type == 1
        ? await provider.sendPrivateTextMessage(
              _targetId!,
              text,
              1,
              optimisticLocalId: messageId,
            )
        : await provider.sendGroupTextMessage(
              _targetId!,
              text,
              1,
              optimisticLocalId: messageId,
            );
    if (!mounted) {
      return;
    }
    if (restOk && !ImFeatureFlags.omitClientDirectImAfterRest) {
      await context.read<ImEventBridge>().sendTextMessage(
            targetId: _targetId!,
            type: _type!,
            text: text,
          );
    }
    _scrollToLatest();
  }

  Future<void> _retryOutgoingMedia({required int messageId}) async {
    if (_targetId == null || _type == null) {
      return;
    }
    final int? uid = context.read<AuthProvider>().messagingUserId;
    if (uid == null) {
      return;
    }
    final MessageProvider provider = context.read<MessageProvider>();
    final MediaRetryParams? params = provider.prepareRetryFailedMediaMessage(
      messageId: messageId,
      targetId: _targetId!,
      type: _type!,
      fromUserId: uid,
    );
    if (params == null || !mounted) {
      return;
    }

    switch (params.msgType) {
      case ChatMessageBodyTypes.image:
        final String? url = await provider.sendChatImageRest(
          targetId: _targetId!,
          chatType: _type!,
          filePath: params.path,
          optimisticLocalId: messageId,
        );
        if (!mounted) {
          return;
        }
        if (url != null && url.isNotEmpty) {
          await context.read<ImEventBridge>().sendImageMessage(
                targetId: _targetId!,
                type: _type!,
                remoteUrl: url,
              );
        }
        break;
      case ChatMessageBodyTypes.video:
        final String? url = await provider.sendChatVideoRest(
          targetId: _targetId!,
          chatType: _type!,
          filePath: params.path,
          optimisticLocalId: messageId,
          durationSeconds: params.durationSeconds,
        );
        if (!mounted) {
          return;
        }
        if (url != null && url.isNotEmpty) {
          await context.read<ImEventBridge>().sendVideoMessage(
                targetId: _targetId!,
                type: _type!,
                remoteUrl: url,
                durationSeconds: params.durationSeconds,
              );
        }
        break;
      default:
        break;
    }
    if (mounted) {
      _scrollToLatest();
    }
  }

  void _openGalleryChooser() {
    wxShowBottomSheetShell<void>(
      context,
      title: '从相册发送',
      showDragHandle: false,
      showCancelAction: true,
      contentPadding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Builder(
              builder: (BuildContext sheetContext) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      dense: true,
                      title: const Text('图片'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        unawaited(_pickAndSendImage(ImageSource.gallery));
                      },
                    ),
                    ListTile(
                      dense: true,
                      title: const Text('视频'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        unawaited(_pickAndSendVideo());
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  //
  // 必须使用 [build] 中通过 context.watch 得到的 [threadMessages]，
  // 避免在构建路径用 read 取消息列表导致多选条等与列表不同步；正常聊天列表已由 watch 订阅。
  //
  List<Widget> _chatAppBarTrailingActions(List<MessageDTO> threadMessages) {
    final selectedInThread = _selectedMessagesInThread(threadMessages);
    return <Widget>[
      if (_selectionMode)
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed:
              selectedInThread.isEmpty ? null : _showSelectionOverview,
        ),
      if (_selectionMode)
        IconButton(
          icon: const Icon(Icons.select_all_outlined),
          onPressed: _selectAllMessages,
        ),
      if (_selectionMode)
        IconButton(
          icon: const Icon(Icons.flip_outlined),
          onPressed: _invertSelectedMessages,
        ),
      if (_selectionMode)
        PopupMenuButton<int>(
          tooltip: '按类型选择',
          icon: const Icon(Icons.filter_list_outlined),
          onSelected: _selectMessagesByType,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 1,
              child: Text('选择文本'),
            ),
            PopupMenuItem(
              value: 2,
              child: Text('选择图片'),
            ),
            PopupMenuItem(
              value: 3,
              child: Text('选择音频'),
            ),
            PopupMenuItem(
              value: 4,
              child: Text('选择视频'),
            ),
          ],
        ),
      if (_selectionMode)
        PopupMenuButton<bool>(
          tooltip: '按发送方选择',
          icon: const Icon(Icons.person_search_outlined),
          onSelected: _selectMessagesBySender,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: true,
              child: Text('选择我发的'),
            ),
            PopupMenuItem(
              value: false,
              child: Text('选择对方发送'),
            ),
          ],
        ),
      if (_selectionMode)
        IconButton(
          icon: const Icon(Icons.forward_outlined),
          onPressed: selectedInThread.isEmpty
              ? null
              : () => _showForwardTargets(
                    selectedInThread.first,
                    messages: selectedInThread,
                  ),
        ),
      if (_selectionMode)
        IconButton(
          icon: const Icon(Icons.my_location_outlined),
          onPressed:
              selectedInThread.isEmpty ? null : _focusFirstSelectedMessage,
        ),
      if (!_selectionMode)
        IconButton(
          icon: const Icon(Icons.more_horiz),
          tooltip: '详情',
          onPressed: _openChatDetailFromAppBar,
        ),
      if (_selectionMode)
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed:
              _selectedMessageIds.isEmpty ? null : _removeSelectedMessagesLocal,
        ),
      if (_selectionMode)
        IconButton(
          icon: const Icon(Icons.content_copy_outlined),
          onPressed:
              selectedInThread.isEmpty ? null : _copySelectedMessagesSummary,
        ),
    ];
  }

  bool _isComposerBlockedForActions() {
    if (_type == 1 && _targetId != null) {
      if (context.read<BlacklistProvider>().isBlocked(_targetId!)) {
        return true;
      }
    }
    if (_type == 2 && _targetId != null) {
      final GroupDTO? g = _groupMeta(context.read<GroupProvider>().groups);
      if (g?.isMute == true) {
        return true;
      }
    }
    return false;
  }

  void _deleteLastComposerChar() {
    if (!mounted || _isComposerBlockedForActions()) {
      return;
    }
    final String s = _messageController.text;
    if (s.isEmpty) {
      return;
    }
    final String next = s.characters.skipLast(1).toString();
    _messageController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _cacheDraft(next);
    setState(() {
      _isTyping = next.isNotEmpty;
    });
  }

  void _clearComposerFromEmojiPanel() {
    if (!mounted || _isComposerBlockedForActions()) {
      return;
    }
    _messageController.clear();
    _cacheDraft('');
    setState(() => _isTyping = false);
  }

  void _toggleVoiceMode() {
    if (!mounted || _isComposerBlockedForActions()) {
      return;
    }
    if (_editingMessage != null) {
      return;
    }
    final bool voice = !_isVoiceMode;
    if (voice) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {
      _isVoiceMode = voice;
      if (voice) {
        _isEmojiPanelOpen = false;
        _isAttachPanelOpen = false;
      }
    });
    if (!voice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _composerFocus.requestFocus();
        }
      });
    }
  }

  void _toggleEmojiPanel() {
    if (!mounted || _isComposerBlockedForActions()) {
      return;
    }
    final bool open = !_isEmojiPanelOpen;
    if (open) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {
      _isEmojiPanelOpen = open;
      if (open) {
        _isAttachPanelOpen = false;
        _isVoiceMode = false;
      }
    });
    if (!open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _composerFocus.requestFocus();
        }
      });
    }
  }

  void _toggleAttachPanel() {
    if (!mounted || _isComposerBlockedForActions()) {
      return;
    }
    final bool open = !_isAttachPanelOpen;
    if (open) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {
      _isAttachPanelOpen = open;
      if (open) {
        _isEmojiPanelOpen = false;
        _isVoiceMode = false;
      }
    });
  }

  ConversationDTO? _conversationMeta(
    List<ConversationDTO> conversations,
  ) {
    for (final ConversationDTO c in conversations) {
      if (c.targetId == _targetId && c.type == _type) {
        return c;
      }
    }
    return null;
  }

  GroupDTO? _groupMeta(List<GroupDTO> groups) {
    if (_type != 2 || _targetId == null) {
      return null;
    }
    for (final GroupDTO g in groups) {
      if (g.id == _targetId) {
        return g;
      }
    }
    return null;
  }

  Future<void> _openGroupDetail() async {
    if (_selectionMode || _type != 2 || _targetId == null) {
      return;
    }
    await Navigator.pushNamed(
      context,
      '/group-detail',
      arguments: <String, dynamic>{
        'groupId': _targetId,
      },
    );
  }

  void _openChatDetailFromAppBar() {
    if (_selectionMode) {
      return;
    }
    if (_type == 1) {
      _openUserDetail();
    } else {
      _openGroupDetail();
    }
  }

  Future<void> _focusMessage(int? messageId) async {
    if (messageId == null) {
      return;
    }
    final mp0 = context.read<MessageProvider>();
    final viewer0 = _effectiveViewerForThread(context.read<AuthProvider>());
    var messages = _threadMessages(mp0, viewer0);
    var index = messages.indexWhere((message) => message.id == messageId);
    while (index == -1 && _hasMoreHistory) {
      await _loadHistoryPage(page: _currentPage + 1);
      final mp = context.read<MessageProvider>();
      final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
      messages = _threadMessages(mp, viewer);
      index = messages.indexWhere((message) => message.id == messageId);
    }
    if (index == -1) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已找到该消息，但它还没有加载到当前页面。'),
        ),
      );
      return;
    }

    setState(() {
      _highlightedMessageId = messageId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final targetOffset = (index * 120).toDouble();
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        targetOffset.clamp(0, maxScroll),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || _highlightedMessageId != messageId) {
      return;
    }
    setState(() {
      _highlightedMessageId = null;
    });
  }

  Future<void> _showForwardTargets(
    MessageDTO message, {
    List<MessageDTO>? messages,
  }) async {
    final provider = context.read<MessageProvider>();
    if (provider.conversations.isEmpty) {
      await provider.loadConversations();
    }
    if (!mounted) {
      return;
    }

    final candidates = provider.conversations.where((conversation) {
      final sameTarget = conversation.targetId == _targetId;
      final sameType = conversation.type == _type;
      return !(sameTarget && sameType);
    }).toList()
      ..sort((a, b) {
        final aTop = a.isTop == true ? 1 : 0;
        final bTop = b.isTop == true ? 1 : 0;
        final topCompare = bTop.compareTo(aTop);
        if (topCompare != 0) {
          return topCompare;
        }
        return (b.lastMessageTime ?? '').compareTo(a.lastMessageTime ?? '');
      });

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可转发到的会话。')),
      );
      return;
    }

    await wxShowBottomSheetShell(
      context,
      isScrollControlled: true,
      title: '转发给',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Builder(
        builder: (BuildContext sheetContext) {
          final TextEditingController searchController = TextEditingController();
          String keyword = '';
          final double sheetH = MediaQuery.sizeOf(sheetContext).height * 0.52;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              final List<ConversationDTO> filteredCandidates =
                  candidates.where((ConversationDTO conversation) {
                final String text = [
                  conversation.name ?? '',
                  conversation.lastMessage ?? '',
                ].join(' ').toLowerCase();
                return keyword.trim().isEmpty ||
                    text.contains(keyword.trim().toLowerCase());
              }).toList();

              return SizedBox(
                height: sheetH,
                child: Column(
                  children: <Widget>[
                    WxSearchBar(
                      controller: searchController,
                      hintText: '搜索',
                      onChanged: (String value) {
                        setSheetState(() => keyword = value);
                      },
                    ),
                    Expanded(
                      child: filteredCandidates.isEmpty
                          ? Center(
                              child: Text(
                                '没有匹配的会话',
                                style: TextStyle(
                                  color: CommonTokens.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(8, 0, 8, 12),
                              itemCount: filteredCandidates.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      Divider(
                                height: 1,
                                color: CommonTokens.lineSubtle,
                              ),
                              itemBuilder:
                                  (BuildContext context, int index) {
                                final ConversationDTO conversation =
                                    filteredCandidates[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: CircleAvatar(
                                    radius: 20,
                                    child: Text(
                                      (conversation.name?.isNotEmpty == true
                                              ? conversation.name![0]
                                              : '#')
                                          .toUpperCase(),
                                    ),
                                  ),
                                  title: Text(
                                    conversation.name ?? '未命名会话',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    conversation.type == 1 ? '单聊' : '群聊',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CommonTokens.textTertiary,
                                    ),
                                  ),
                                  trailing: index < 5
                                      ? Icon(
                                          Icons.history,
                                          size: 18,
                                          color: CommonTokens.brandBlue
                                              .withValues(alpha: 0.85),
                                        )
                                      : null,
                                  onTap: () async {
                                    Navigator.pop(sheetContext);
                                    await _forwardMessagesToConversation(
                                      messages ?? <MessageDTO>[message],
                                      conversation,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _forwardMessagesToConversation(
    List<MessageDTO> messages,
    ConversationDTO conversation,
  ) async {
    if (messages.isEmpty || conversation.targetId == null) {
      return;
    }
    var successCount = 0;
    final failedIds = <int>{};
    for (final message in messages) {
      if (message.id == null) {
        continue;
      }
      final success = await context.read<MessageProvider>().forwardMessage(
            originalMsgId: message.id!,
            toUserId: conversation.type == 1 ? conversation.targetId : null,
            groupId: conversation.type == 1 ? null : conversation.targetId,
          );
      if (success) {
        successCount++;
      } else {
        failedIds.add(message.id!);
      }
    }
    if (!mounted) {
      return;
    }
    if (_selectionMode) {
      setState(() {
        if (successCount == messages.length) {
          _selectedMessageIds.clear();
        } else if (failedIds.isNotEmpty) {
          _selectedMessageIds
            ..clear()
            ..addAll(failedIds);
        }
      });
    }
    final summary = successCount == messages.length
        ? (messages.length > 1
            ? '已成功转发 ${messages.length} 条消息。'
            : '消息已成功转发。')
        : successCount > 0
            ? '共转发成功 $successCount / ${messages.length} 条，失败的消息已保留，方便继续处理。'
            : '没有消息转发成功。';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(summary)),
    );
    await _showBatchOperationSummary(
      title: '转发结果',
      summary: summary,
    );
  }

  Future<void> _removeSelectedMessagesLocal() async {
    if (_selectedMessageIds.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('移除已选消息'),
        content: const Text(
          '这只会把已选消息从当前页面移除，不会删除服务器上的历史消息。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final removedCount = _selectedMessageIds.length;
    final mp = context.read<MessageProvider>();
    final viewer = _effectiveViewerForThread(context.read<AuthProvider>());
    final selectedInThread =
        _selectedMessagesInThread(_threadMessages(mp, viewer));
    await _removeMessagesFromCurrentView(
      selectedInThread,
      title: '移除结果',
      successMessage:
          '已从当前视图移除 $removedCount 条消息。',
      trailingNote:
          '这只清理了当前页面视图，不会删除服务器上的历史消息。',
      clearSelectionAfter: true,
    );
  }

  void _showMessageActions(MessageDTO message, bool isCurrentUser) {
    final List<ChatSheetActionItem> actions = <ChatSheetActionItem>[
      ChatSheetActionItem(
        icon: Icons.reply_outlined,
        label: '回复',
        onTap: () {
          setState(() {
            _replyingTo = message;
            _editingMessage = null;
          });
        },
      ),
      ChatSheetActionItem(
        icon: Icons.forward_outlined,
        label: '转发',
        onTap: () => _showForwardTargets(message),
      ),
      ChatSheetActionItem(
        icon: Icons.checklist_outlined,
        label: '多选',
        onTap: () => _toggleMessageSelection(message),
      ),
      ChatSheetActionItem(
        icon: Icons.content_copy_outlined,
        label: '复制',
        onTap: () {
          if ((message.content ?? '').isNotEmpty) {
            Clipboard.setData(ClipboardData(text: message.content!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('消息已复制')),
            );
          }
        },
      ),
      if (isCurrentUser &&
          message.showsTextBubblePayload &&
          !message.isRecalledMessage)
        ChatSheetActionItem(
          icon: Icons.edit_outlined,
          label: '编辑',
          onTap: () {
            setState(() {
              _editingMessage = message;
              _replyingTo = null;
              _messageController.text =
                  EmojiList.replacePlaceholders(message.content ?? '');
              _messageController.selection = TextSelection.collapsed(
                offset: _messageController.text.length,
              );
              _isTyping = _messageController.text.isNotEmpty;
            });
          },
        ),
      if (isCurrentUser && !message.isRecalledMessage)
        ChatSheetActionItem(
          icon: Icons.undo_outlined,
          label: '撤回',
          onTap: () => _recallMessage(message),
        ),
    ];
    showChatMessageActionsSheet(context, actions: actions);
  }

  Widget _buildTopContextBanner() {
    /// 在线状态仅展示在 AppBar 副标题，避免条带状 Banner 重复占位。
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final MessageProvider messageProvider = context.watch<MessageProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final BlacklistProvider blacklistProvider = context.watch<BlacklistProvider>();
    final GroupProvider groupProvider = context.watch<GroupProvider>();
    final int? currentUserId = _effectiveViewerForThread(authProvider);
    final List<MessageDTO> liveThreadMessages =
        _threadMessages(messageProvider, currentUserId);
    final bool awaitingSnapshotData =
        _useFirstPaintSnapshot && !_firstPaintSnapshotReady;
    final bool awaitingFirstPaintSnapshot =
        (_useFirstPaintSnapshot || _freezeFirstPaintDataSource) &&
            (!_firstPaintSnapshotReady || !_firstPaintSnapshotRevealed);
    final bool useSnapshotMessages = _firstPaintSnapshotReady &&
        (_useFirstPaintSnapshot || _freezeFirstPaintDataSource);
    final bool firstPaintHandoffActive =
        _useFirstPaintSnapshot || _freezeFirstPaintDataSource;
    final List<MessageDTO> effectiveThreadMessages = awaitingSnapshotData
        ? const <MessageDTO>[]
        : (useSnapshotMessages
            ? _firstPaintSnapshotMessages
            : liveThreadMessages);
    final bool isLoadingMessages = awaitingSnapshotData ||
        (!firstPaintHandoffActive &&
            messageProvider.isLoading &&
            effectiveThreadMessages.isEmpty);
    final bool isEmptyMessages =
        !isLoadingMessages && effectiveThreadMessages.isEmpty;
    if (kDebugMode) {
      debugPrint(
        '[im.chain] chat build liveLen=${liveThreadMessages.length} '
        'effectiveLen=${effectiveThreadMessages.length} snapshotSrc=$useSnapshotMessages '
        'awaitingSnapshot=$awaitingFirstPaintSnapshot revealed=$_firstPaintSnapshotRevealed '
        'freezeDs=$_freezeFirstPaintDataSource '
        'target=$_targetId type=$_type authViewer=${authProvider.messagingUserId} '
        'threadViewer=$currentUserId',
      );
    }
    _maybeScrollToLatestOnNewThreadMessage(
      effectiveThreadMessages.length,
      effectiveThreadMessages,
    );
    _maybeMarkPrivateReadOnThreadGrowth(liveThreadMessages);
    final bool isBlocked =
        _type == 1 && _targetId != null && blacklistProvider.isBlocked(_targetId!);
    final GroupDTO? groupMeta = _groupMeta(groupProvider.groups);
    final ConversationDTO? convMeta =
        _conversationMeta(messageProvider.conversations);
    final ChatScene chatScene = chatSceneFromConversationType(_type);
    final bool groupAllMuted =
        chatScene.isGroupChat && (groupMeta?.isMute == true);
    final bool composerEnabled = !isBlocked && !groupAllMuted;

    /// 统一底部：尾间距 + 输入区（条本体 + 条上固定 chrome）+ 内联底面板（表情 或 +；不含 IME）+ 安全区底。
    /// 键盘上推仅靠 Scaffold 视口收缩；贴底仍依赖 [_syncBottomAnchorIfLayoutChanged] 在 near-bottom 时 jump。
    final MediaQueryData mq = MediaQuery.of(context);
    final double safeAreaBottom = mq.padding.bottom;
    final double composerHeight = _selectionMode
        ? 0
        : _composerInputRowHeight() +
            _composerChromeAboveInputHeight(
              isBlocked: isBlocked,
              groupAllMuted: groupAllMuted,
              replyVisible:
                  _editingMessage != null || _replyingTo != null,
            );
    final double bottomPanelHeight = _selectionMode
        ? 0
        : _resolveBottomPanelHeight(mq, chatScene);
    final double listBottomPad = ChatUiTokens.messageListBottomSpacing +
        composerHeight +
        bottomPanelHeight +
        safeAreaBottom;
    _syncBottomAnchorIfLayoutChanged(
      composerHeight: composerHeight,
      bottomPanelHeight: bottomPanelHeight,
      safeAreaBottom: safeAreaBottom,
      viewInsetsBottom: mq.viewInsets.bottom,
    );
    if (kDebugMode) {
      debugPrint(
        '[im.chat.audit] composerH=$composerHeight bottomPanel=$bottomPanelHeight '
        'safe=$safeAreaBottom viewInsets=${mq.viewInsets.bottom} listBottomPad=$listBottomPad',
      );
    }

    return ChatPageScaffold(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ChatConversationAppBar(
            selectionMode: _selectionMode,
            centerTitle: _selectionMode
                ? Text(
                    '已选择 ${_selectedMessageIds.length} 条',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: ChatUiTokens.chatHeaderTitleText,
                  )
                : ChatAppBarTitle(
                    scene: chatScene,
                    title: _title,
                    centered: true,
                    singleStatusLabel: _statusText ?? '状态同步中',
                    groupSubtitle:
                        _groupSubtitleLine(groupMeta, convMeta),
                  ),
            onLeadingPressed: _selectionMode
                ? _requestClearSelection
                : () => Navigator.maybePop(context),
            actions: _chatAppBarTrailingActions(effectiveThreadMessages),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: ChatUiTokens.divider.withValues(alpha: 0.28),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ChatMessagesBody(
            selectionBar: _selectionMode
                ? ChatSelectionSummaryBar(
                    selectedCount: _selectedMessageIds.length,
                    summaryText:
                        _selectionSummaryText(effectiveThreadMessages),
                  )
                : null,
            topBanner: _buildTopContextBanner(),
            isLoading: isLoadingMessages,
            isEmpty: isEmptyMessages,
            loading: const Center(child: CircularProgressIndicator()),
            empty: const AppEmptyState(
              icon: Icons.chat_bubble_outline,
              text: '暂无消息',
              detail: '开始发送第一条消息吧',
            ),
            listScrollController: _scrollController,
            listPadding: EdgeInsets.fromLTRB(
              12,
              ChatUiTokens.messageListTopSpacing,
              12,
              listBottomPad,
            ),
            messageCount: effectiveThreadMessages.length,
            loadingHistory: _loadingHistory,
            hasMoreHistory: _hasMoreHistory,
            onLoadOlderTap: () {
              if (_useFirstPaintSnapshot ||
                  _freezeFirstPaintDataSource ||
                  !_firstPaintSnapshotReady) {
                return;
              }
              _loadHistoryPage(page: _currentPage + 1);
            },
            itemBuilder: (BuildContext context, int index) {
              final MessageDTO row = effectiveThreadMessages[index];
              return ChatThreadMessageItem(
                key: ValueKey<String>(chatMessageListItemValueKey(row)),
                message: row,
                index: index,
                messages: effectiveThreadMessages,
                currentUserId: currentUserId,
                historyBoundaryIndex: _historyBoundaryIndex,
                selectionMode: _selectionMode,
                selectedMessageIds: _selectedMessageIds,
                highlightedMessageId: _highlightedMessageId,
                scene: chatScene,
                onShowMessageActions: _showMessageActions,
                onToggleSelection: _toggleMessageSelection,
                onOpenMediaPreview: _openMediaPreview,
                onOpenMediaDetails: _openMediaDetails,
                audioDurationLabel: _audioDurationLabel,
                onRetryOutgoingFailed: _retryOutgoingFailed,
                onSelectMessagesForDate: _selectMessagesForDate,
              );
            },
          ),
          if (awaitingFirstPaintSnapshot)
            ColoredBox(
              color: ChatUiTokens.pageBackground,
              child: const SizedBox.expand(),
            ),
        ],
      ),
      inputBar: !_selectionMode
          ? ChatComposerColumn(
              scene: chatScene,
              controller: _messageController,
              focusNode: _composerFocus,
              inputEnabled: composerEnabled,
              canSendMessage: composerEnabled,
              hintText: _editingMessage != null ? '编辑消息' : '输入消息',
              isTyping: _isTyping,
              isVoiceMode: _isVoiceMode,
              voiceModeAllowed:
                  composerEnabled && _editingMessage == null,
              onVoiceModeToggle: _toggleVoiceMode,
              isEmojiPanelOpen: _isEmojiPanelOpen,
              isAttachPanelOpen: _isAttachPanelOpen,
              onEmojiPanelToggle: _toggleEmojiPanel,
              onAttachPanelToggle: _toggleAttachPanel,
              onTextChanged: (String value) {
                _cacheDraft(value);
                setState(() {
                  _isTyping = value.isNotEmpty;
                });
              },
              onSubmitText: () {
                unawaited(_sendMessage());
              },
              onHoldToSpeakTap: () {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('语音消息开发中'),
                  ),
                );
              },
              showBlockedBanner: isBlocked,
              showGroupMuteHint: groupAllMuted,
              replyBannerVisible:
                  _editingMessage != null || _replyingTo != null,
              replyBannerEditing: _editingMessage != null,
              replySummaryText: (_editingMessage ?? _replyingTo) == null
                  ? ''
                  : _summary(_editingMessage ?? _replyingTo!),
              onCloseReplyBanner: () {
                setState(() {
                  _replyingTo = null;
                  _editingMessage = null;
                });
              },
              onDeleteLastComposerChar: _deleteLastComposerChar,
              onClearComposerFromEmojiPanel: _clearComposerFromEmojiPanel,
              onEmojiAuxiliarySend: () {
                unawaited(_sendMessage());
              },
              onOpenGalleryChooser: () {
                setState(() => _isAttachPanelOpen = false);
                _openGalleryChooser();
              },
              onPickCameraImage: () {
                setState(() => _isAttachPanelOpen = false);
                unawaited(_pickAndSendImage(ImageSource.camera));
              },
              onAttachFileStub: () {
                setState(() => _isAttachPanelOpen = false);
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('文件发送开发中'),
                  ),
                );
              },
              onVoiceCall: !chatScene.isGroupChat
                  ? () {
                      setState(() => _isAttachPanelOpen = false);
                      _startCall(CallMediaType.audio);
                    }
                  : null,
              onVideoCall: !chatScene.isGroupChat
                  ? () {
                      setState(() => _isAttachPanelOpen = false);
                      _startCall(CallMediaType.video);
                    }
                  : null,
            )
          : null,
    );
  }
}

