import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/message_send_state.dart';
import 'package:hailiao_flutter_v2/domain_v2/local/chat_message_local_cache.dart';
import 'package:hailiao_flutter_v2/domain_v2/local/persistent_chat_message_local_cache.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/chat_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_message_mapper.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_event.dart';
import 'package:hailiao_flutter_v2/domain_v2/use_cases/load_chat_messages_use_case.dart';
import 'package:hailiao_flutter_v2/domain_v2/use_cases/send_text_message_use_case.dart';

class ChatCoordinator extends ChangeNotifier {
  ChatCoordinator({
    required this.targetId,
    required this.type,
    required this.currentUserId,
    this.currentUserToken,
    this.currentUserName,
    required LoadChatMessagesUseCase loadChatMessagesUseCase,
    required SendTextMessageUseCase sendTextMessageUseCase,
    required ChatRepository repository,
    required ConversationRepository conversationRepository,
    required ImMessageMapper mapper,
    ChatMessageLocalCache? localCache,
  }) : _loadChatMessagesUseCase = loadChatMessagesUseCase,
       _sendTextMessageUseCase = sendTextMessageUseCase,
       _repository = repository,
       _conversationRepository = conversationRepository,
       _mapper = mapper,
       _localCache = localCache ?? defaultChatMessageLocalCache;

  final int targetId;
  final int type;
  final int? currentUserId;
  final String? currentUserToken;
  final String? currentUserName;
  final LoadChatMessagesUseCase _loadChatMessagesUseCase;
  final SendTextMessageUseCase _sendTextMessageUseCase;
  final ChatRepository _repository;
  final ConversationRepository _conversationRepository;
  final ImMessageMapper _mapper;
  final ChatMessageLocalCache _localCache;

  final List<ChatMessage> _messages = <ChatMessage>[];
  StreamSubscription<WukongImEvent>? _subscription;
  bool _isRealtimeAttached = false;
  bool _initialRemoteInFlight = false;
  bool _cacheHydrateCompleted = false;
  bool _isSending = false;
  bool _isSyncingRead = false;
  String? _error;
  String _draftText = '';

  static const int _historyPageSize = 20;

  /// 首屏 refreshRemoteFirstPage 成功完成后才可拉取更早分页，避免页码与缓存不一致。
  bool _olderPaginationReady = false;
  int _nextOlderPage = 2;
  bool _hasMoreOlder = true;
  bool _isLoadingOlder = false;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  /// 远端第一页请求中；与 [shouldShowInitialLoading] 配合：仅当列表仍为空时展示首屏加载指示。
  bool get initialRemoteInFlight => _initialRemoteInFlight;

  /// 无本地消息且正在拉取远端第一页时展示加载圈；有缓存时即使远端在飞也不打断列表。
  bool get shouldShowInitialLoading => _initialRemoteInFlight && _messages.isEmpty;

  bool get isSending => _isSending;
  String? get error => _error;
  String get draftText => _draftText;

  /// 会话维度缓存键（与存储层一致）。
  String get cacheKey => '$type-$targetId';

  /// 是否还可能存在更早一页（上一页满页且未判定结束）。
  bool get hasMoreHistory => _olderPaginationReady && _hasMoreOlder;

  bool get isLoadingHistory => _isLoadingOlder;

  Future<void> hydrateFromCache() async {
    if (_cacheHydrateCompleted) {
      return;
    }
    _cacheHydrateCompleted = true;

    try {
      final List<ChatMessage>? cached =
          await _localCache.getRecentMessages(cacheKey);
      if (cached == null || cached.isEmpty) {
        if (kDebugMode) {
          debugPrint('[chat.localFirst] miss cacheKey=$cacheKey');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('[chat.localFirst] hit cacheKey=$cacheKey');
        debugPrint(
          '[chat.localFirst] hydrateFromCache before=0 after=${cached.length}',
        );
      }

      _messages
        ..clear()
        ..addAll(cached);
      _sortMessages();
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[chat.localFirst] hydrateFromCache failed cacheKey=$cacheKey err=$e',
        );
        debugPrint('$st');
      }
    }
  }

  /// 拉取远端第一页并与当前内存列表温和 merge（不清空、不整表替换）。
  Future<void> refreshRemoteFirstPage() async {
    if (_initialRemoteInFlight) {
      return;
    }
    _initialRemoteInFlight = true;
    final bool showSpinner = _messages.isEmpty;
    if (showSpinner) {
      notifyListeners();
    }

    Object? caught;
    bool didChange = false;
    try {
      if (kDebugMode) {
        debugPrint('[chat.localFirst] refreshRemote page=1 cacheKey=$cacheKey');
      }

      final List<ChatMessage> remote = await _loadChatMessagesUseCase(
        targetId: targetId,
        type: type,
        currentUserId: currentUserId,
        page: 1,
        size: _historyPageSize,
      );

      final int before = _messages.length;
      didChange = _mergeRemoteFirstPage(remote);
      if (kDebugMode) {
        debugPrint(
          '[chat.localFirst] mergeRemote before=$before fetched=${remote.length} after=${_messages.length}',
        );
      }

      await _persistMessagesToCache();

      await _syncConversationRead();

      _olderPaginationReady = true;
      _nextOlderPage = 2;
      _hasMoreOlder = remote.length >= _historyPageSize;
      if (kDebugMode) {
        debugPrint(
          '[chat.history] firstPagePagination hasMoreOlder=$_hasMoreOlder nextOlderPage=$_nextOlderPage',
        );
      }
    } catch (e) {
      caught = e;
      _error = e.toString();
    } finally {
      _initialRemoteInFlight = false;
      final bool needNotify =
          showSpinner || caught != null || didChange;
      if (needNotify) {
        notifyListeners();
      } else if (kDebugMode) {
        debugPrint(
          '[chat.localFirst] skipNotify reason=noChangeAfterMerge',
        );
      }
    }
  }

  Future<void> _persistMessagesToCache() async {
    if (kDebugMode) {
      debugPrint(
        '[chat.localFirst] writeCache cacheKey=$cacheKey count=${_messages.length}',
      );
    }
    await _localCache.putRecentMessages(
      cacheKey,
      List<ChatMessage>.from(_messages),
      maxRetain: 120,
    );
  }

  String _fingerprintMessages() {
    final StringBuffer b = StringBuffer();
    for (final ChatMessage m in _messages) {
      b.write(m.id);
      b.write(':');
      b.write(m.sendState.name);
      b.write(':');
      b.write(m.serverId);
      b.write(':');
      b.write(m.clientId);
      b.write(':');
      b.write(m.text);
      b.write('|');
    }
    return b.toString();
  }

  /// 上拉加载更早一页；prepend 语义由列表侧锚点保持，此处只做 merge + 排序。
  Future<void> loadOlderMessages() async {
    if (!_olderPaginationReady) {
      if (kDebugMode) {
        debugPrint(
          '[chat.history] skip loadOlder reason=paginationNotReady',
        );
      }
      return;
    }
    if (_isLoadingOlder) {
      if (kDebugMode) {
        debugPrint('[chat.history] skip loadOlder reason=alreadyLoading');
      }
      return;
    }
    if (!_hasMoreOlder) {
      if (kDebugMode) {
        debugPrint('[chat.history] skip loadOlder reason=noMoreOlder');
      }
      return;
    }

    _isLoadingOlder = true;
    notifyListeners();

    try {
      final int before = _messages.length;
      if (kDebugMode) {
        debugPrint(
          '[chat.history] loadOlderMessages page=$_nextOlderPage before=$before '
          'hasMoreOlder=$_hasMoreOlder isLoadingOlder=$_isLoadingOlder',
        );
      }

      final List<ChatMessage> older = await _loadChatMessagesUseCase(
        targetId: targetId,
        type: type,
        currentUserId: currentUserId,
        page: _nextOlderPage,
        size: _historyPageSize,
      );

      if (kDebugMode) {
        debugPrint(
          '[chat.history] fetched older count=${older.length}',
        );
      }

      for (final ChatMessage m in older) {
        _mergeRemoteSingle(m);
      }
      _sortMessages();

      if (kDebugMode) {
        debugPrint(
          '[chat.history] mergeOlder after=${_messages.length}',
        );
      }

      _nextOlderPage++;
      if (older.length < _historyPageSize) {
        _hasMoreOlder = false;
      }

      if (kDebugMode) {
        debugPrint(
          '[chat.history] hasMoreOlder=$_hasMoreOlder nextOlderPage=$_nextOlderPage',
        );
      }

      await _persistMessagesToCache();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[chat.history] loadOlderMessages failed err=$e');
      }
      _error = e.toString();
    } finally {
      _isLoadingOlder = false;
      notifyListeners();
    }
  }

  /// 将远端第一页并入列表；返回是否发生可观测的数据变化。
  bool _mergeRemoteFirstPage(List<ChatMessage> remote) {
    final String before = _fingerprintMessages();
    for (final ChatMessage m in remote) {
      _mergeRemoteSingle(m);
    }
    _sortMessages();
    return before != _fingerprintMessages();
  }

  void _mergeRemoteSingle(ChatMessage message) {
    if (!_belongsToCurrentChat(message)) {
      return;
    }

    final int index = _findMergeIndexForRemotePage(message);
    if (index != -1) {
      _messages[index] = message;
    } else {
      _messages.add(message);
    }
  }

  /// 远端首屏 merge：强匹配（clientId / serverId / id）+ 软匹配兜底。
  int _findMergeIndexForRemotePage(ChatMessage message) {
    final int strong = _findMergeIndex(message);
    if (strong != -1) {
      return strong;
    }

    final int? ms = message.createdAt != null
        ? DateTime.tryParse(message.createdAt!)?.millisecondsSinceEpoch
        : null;
    if (ms == null) {
      return -1;
    }
    for (int i = 0; i < _messages.length; i++) {
      final ChatMessage item = _messages[i];
      if (item.senderId != message.senderId) {
        continue;
      }
      if (item.text != message.text) {
        continue;
      }
      if (item.targetId != message.targetId || item.type != message.type) {
        continue;
      }
      final int? itemMs = item.createdAt != null
          ? DateTime.tryParse(item.createdAt!)?.millisecondsSinceEpoch
          : null;
      if (itemMs == null) {
        continue;
      }
      if ((itemMs - ms).abs() <= 60000) {
        return i;
      }
    }
    return -1;
  }

  Future<void> attachImStream() async {
    if (_isRealtimeAttached) {
      return;
    }
    _conversationRepository.markConversationActive(targetId, type);
    _subscription = _repository.watchRealtimeEvents().listen(_handleRealtimeEvent);
    await _repository.bindRealtime(
      currentUserId: currentUserId,
      authToken: currentUserToken,
    );
    _isRealtimeAttached = true;
    await _syncConversationRead();
  }

  Future<void> detachImStream() async {
    await _subscription?.cancel();
    _subscription = null;
    _conversationRepository.clearConversationActive(targetId, type);
    _repository.unbindRealtime();
    _isRealtimeAttached = false;
  }

  void updateDraft(String value) {
    if (_draftText == value) {
      return;
    }
    _draftText = value;
    notifyListeners();
  }

  Future<void> sendText([String? rawText]) async {
    final String text = (rawText ?? _draftText).trim();
    if (text.isEmpty || currentUserId == null) {
      return;
    }

    final ChatMessage optimistic = _mapper.createOptimisticText(
      targetId: targetId,
      type: type,
      senderId: currentUserId!,
      text: text,
    );

    _messages.add(optimistic);
    _sortMessages();
    _draftText = '';
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await _sendTextMessageUseCase(
        targetId: targetId,
        type: type,
        senderId: currentUserId!,
        text: text,
        clientId: optimistic.clientId,
      );
      await _persistMessagesToCache();
    } catch (error) {
      final int index = _messages.indexWhere((item) => item.id == optimistic.id);
      if (index != -1) {
        _messages[index] = optimistic.copyWith(sendState: MessageSendState.failed);
      }
      _error = error.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void _handleRealtimeEvent(WukongImEvent event) {
    switch (event.type) {
      case WukongImEventType.incoming:
        final ChatMessage? message = event.message;
        if (message != null) {
          _mergeMessage(message);
        }
        break;
      case WukongImEventType.refresh:
        final ChatMessage? message = event.message;
        if (message != null) {
          _applyRefreshMessage(
            message,
            event.sendState ?? message.sendState,
          );
        }
        break;
      case WukongImEventType.connection:
        break;
    }
  }

  void _applyRefreshMessage(ChatMessage message, MessageSendState sendState) {
    if (!_belongsToCurrentChat(message)) {
      return;
    }

    final int index = _findMergeIndex(message);
    final ChatMessage refreshed = message.copyWith(sendState: sendState);
    if (index != -1) {
      _messages[index] = refreshed;
    } else {
      _messages.add(refreshed);
      _sortMessages();
    }

    if (sendState == MessageSendState.sent ||
        sendState == MessageSendState.read) {
      _conversationRepository.upsertPreviewFromMessage(
        refreshed,
        clearDraft: true,
      );
    }
    notifyListeners();
  }

  void _mergeMessage(ChatMessage message) {
    if (!_belongsToCurrentChat(message)) {
      return;
    }

    final int existingIndex = _findMergeIndex(message);
    if (existingIndex != -1) {
      _messages[existingIndex] = message;
    } else {
      _messages.add(message);
      _sortMessages();
    }

    _conversationRepository.upsertPreviewFromMessage(
      message,
      clearDraft: true,
    );
    if (!message.isMine) {
      unawaited(_syncConversationRead());
    }
    notifyListeners();
  }

  Future<void> _syncConversationRead() async {
    if (_isSyncingRead) {
      return;
    }

    _isSyncingRead = true;
    _conversationRepository.clearUnread(targetId, type);
    try {
      await _repository.markConversationRead(
        targetId: targetId,
        type: type,
      );
    } catch (_) {
      // Keep current chat usable; later events can retry read sync.
    } finally {
      _isSyncingRead = false;
    }
  }

  bool _belongsToCurrentChat(ChatMessage message) {
    return message.targetId == targetId && message.type == type;
  }

  int _findMergeIndex(ChatMessage message) {
    if (message.clientId != null) {
      final int byClient = _messages.indexWhere(
        (item) => item.clientId != null && item.clientId == message.clientId,
      );
      if (byClient != -1) {
        return byClient;
      }
    }

    if (message.serverId != null) {
      final int byServerId = _messages.indexWhere(
        (item) => item.serverId != null && item.serverId == message.serverId,
      );
      if (byServerId != -1) {
        return byServerId;
      }
    }

    final int byId = _messages.indexWhere((item) => item.id == message.id);
    if (byId != -1) {
      return byId;
    }

    if (message.isMine) {
      return _messages.lastIndexWhere(
        (item) =>
            item.isMine &&
            item.sendState == MessageSendState.sending &&
            item.text == message.text,
      );
    }

    return -1;
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final int aTime =
          DateTime.tryParse(a.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
      final int bTime =
          DateTime.tryParse(b.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
      return aTime.compareTo(bTime);
    });
  }

  @override
  void dispose() {
    detachImStream();
    super.dispose();
  }
}
