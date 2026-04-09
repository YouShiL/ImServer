import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/config/app_config.dart';
import 'package:hailiao_flutter/config/im_feature_flags.dart';
import 'package:hailiao_flutter/im/im_event_mapper.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/services/call_signal_bridge.dart';
import 'package:wukongimfluttersdk/common/options.dart';
import 'package:wukongimfluttersdk/entity/channel.dart';
import 'package:wukongimfluttersdk/entity/msg.dart';
import 'package:wukongimfluttersdk/model/wk_image_content.dart';
import 'package:wukongimfluttersdk/model/wk_text_content.dart';
import 'package:wukongimfluttersdk/model/wk_video_content.dart';
import 'package:wukongimfluttersdk/model/wk_voice_content.dart';
import 'package:wukongimfluttersdk/type/const.dart';
import 'package:wukongimfluttersdk/wkim.dart';

/// Thin bridge between an IM SDK event source and MessageProvider.
/// This class only owns subscription lifecycle, reads currentUserId from
/// AuthProvider, and forwards mapped events into MessageProvider.
class ImEventBridge {
  ImEventBridge({
    required AuthProvider authProvider,
    required MessageProvider messageProvider,
    ImEventMapper? mapper,
  }) : _authProvider = authProvider,
       _messageProvider = messageProvider,
       _mapper = mapper ?? const ImEventMapper();

  final AuthProvider _authProvider;
  final MessageProvider _messageProvider;
  final ImEventMapper _mapper;
  final CallSignalBridge _callSignalBridge = CallSignalBridge.instance;

  bool _isBound = false;
  bool _isSetup = false;
  bool _isInsertedListenerRegistered = false;
  String? _boundUid;
  String? _boundToken;
  static const String _listenerKey = 'hailiao_im_bridge';

  /// inserted / new 可能对同一条各回调一次：短时去重，避免双注 Provider。
  static const int _imRtDedupCapacity = 48;
  final ListQueue<String> _imRtRecentKeys = ListQueue<String>();

  int? get _currentUserId => _authProvider.messagingUserId;
  String? get _currentUid => _currentUserId?.toString();
  String? get _currentToken => _authProvider.token;

  /// TCP / setup 用的 uid：与 [_effectiveMapperUserId] 同源思路，避免仅 Auth 尚未解析出 id 时 Windows 永远 bind 失败。
  String? get _resolvedBindUidString {
    final String? authStr = _currentUid;
    if (authStr != null && authStr.isNotEmpty) {
      return authStr;
    }
    final String? wk = WKIM.shared.options.uid;
    if (wk != null && wk.isNotEmpty) {
      return wk;
    }
    return null;
  }

  /// 映射私聊 to/from 与 [MessageProvider] 过滤使用的「当前用户」：优先 Auth，其次 WKIM [Options.uid]。
  /// 桌面端偶现 Auth 尚未带出 [messagingUserId] 但 TCP 已 bind 时，避免 toUserId 全空导致 [messagesForChat] 丢行。
  int? get _effectiveMapperUserId {
    final int? authId = _authProvider.messagingUserId;
    if (authId != null) {
      return authId;
    }
    final String? uidStr = WKIM.shared.options.uid;
    if (uidStr == null || uidStr.isEmpty) {
      return null;
    }
    return int.tryParse(uidStr);
  }

  void _logRt(String source, WKMsg m) {
    if (!kDebugMode) {
      return;
    }
    final String dk = _imRtDedupKey(m);
    debugPrint(
      '[im.rt] source=$source dedupKey=$dk channelID=${m.channelID} channelType=${m.channelType} '
      'fromUID=${m.fromUID} clientMsgNO=${m.clientMsgNO} messageID=${m.messageID} '
      'messageSeq=${m.messageSeq} timestamp=${m.timestamp} '
      'authMessaging=$_currentUserId mapperViewer=$_effectiveMapperUserId',
    );
  }

  String _imRtDedupKey(WKMsg m) {
    final String c = m.clientMsgNO.trim();
    if (c.isNotEmpty) {
      return 'c:$c';
    }
    return 'm:${m.messageID}|s:${m.messageSeq}|f:${m.fromUID}|ch:${m.channelID}|ts:${m.timestamp}';
  }

  void _imRtDedupClear() {
    _imRtRecentKeys.clear();
  }

  /// 若与最近事件重复则返回 true（且不把 key 再次入队）。
  bool _imRtDedupShouldSkip(WKMsg m) {
    final String key = _imRtDedupKey(m);
    if (_imRtRecentKeys.contains(key)) {
      if (kDebugMode) {
        debugPrint('[im.rt] dedup_skip key=$key');
      }
      return true;
    }
    _imRtRecentKeys.addLast(key);
    while (_imRtRecentKeys.length > _imRtDedupCapacity) {
      _imRtRecentKeys.removeFirst();
    }
    return false;
  }

  bool get isBound => _isBound;

  /// 必须 await：[WKIM.setup] 内会异步打开 SQLite（[WKDBHelper.init]）。
  /// 若未等待完成就 [connect]，收包落库时 [WKDBHelper.getDB] 仍为 null，
  /// SDK [MessageDB.insert] 中 `getDB()!` 会在 Windows 等机子上直接崩溃。
  Future<bool> bind() async {
    final uid = _resolvedBindUidString;
    final token = _currentToken;
    if (uid == null || uid.isEmpty || token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[ImEventBridge] bind skipped: need numeric user id + JWT. '
          'messagingUserId=${_authProvider.messagingUserId} uidStr=$uid '
          'wkUid=${WKIM.shared.options.uid} '
          'tokenEmpty=${token == null || token.isEmpty} '
          'imTcpAddr=${AppConfig.imTcpAddr}',
        );
      }
      unbind();
      return false;
    }

    if (kDebugMode) {
      debugPrint(
        '[im.chain] bind uid=$uid authMessaging=${_authProvider.messagingUserId} '
        'mapperViewer=$_effectiveMapperUserId',
      );
    }

    final credsChanged = _boundUid != uid || _boundToken != token;
    if (_isBound && !credsChanged) {
      return true;
    }

    if (_isBound) {
      _imRtDedupClear();
      WKIM.shared.messageManager.removeNewMsgListener(_listenerKey);
      WKIM.shared.messageManager.removeOnRefreshMsgListener(_listenerKey);
      WKIM.shared.connectionManager.removeOnConnectionStatus(_listenerKey);
      WKIM.shared.connectionManager.disconnect(true);
      _isBound = false;
    }

    if (credsChanged || !_isSetup) {
      final opts = Options.newDefault(
        uid,
        token,
        addr: AppConfig.imTcpAddr,
      )..debug = AppConfig.imSdkDebug;
      final bool setupOk = await WKIM.shared.setup(opts);
      if (!setupOk) {
        if (kDebugMode) {
          debugPrint(
            '[ImEventBridge] WKIM.setup returned false (local DB init failed?) '
            'uid=$uid',
          );
        }
        return false;
      }
      _isSetup = true;
      _boundUid = uid;
      _boundToken = token;
      if (kDebugMode) {
        debugPrint(
          '[ImEventBridge] WKIM.setup completed uid=$uid addr=${AppConfig.imTcpAddr}',
        );
      }
    }

    if (!_isInsertedListenerRegistered) {
      WKIM.shared.messageManager.addOnMsgInsertedListener((wkMsg) {
        _logRt('inserted', wkMsg);
        if (_imRtDedupShouldSkip(wkMsg)) {
          return;
        }
        onIncomingMessage(wkMsg);
      });
      _isInsertedListenerRegistered = true;
    }

    WKIM.shared.connectionManager.addOnConnectionStatus(
      _listenerKey,
      (status, reason, connectInfo) {
        if (kDebugMode) {
          debugPrint(
            '[ImEventBridge] connection status=$status reason=$reason info=$connectInfo',
          );
        }
      },
    );

    WKIM.shared.messageManager.addOnNewMsgListener(_listenerKey, (msgs) {
      if (msgs.isEmpty) {
        return;
      }
      final List<WKMsg> forward = <WKMsg>[];
      for (final WKMsg m in msgs) {
        _logRt('new', m);
        if (_imRtDedupShouldSkip(m)) {
          continue;
        }
        forward.add(m);
      }
      if (forward.isEmpty) {
        return;
      }
      onIncomingMessages(forward);
    });

    WKIM.shared.messageManager.addOnRefreshMsgListener(_listenerKey, (WKMsg msg) {
      // WuKongIM routes send ack / fail、消息扩展（含已读 readed）、回应等 refresh 到同一监听。
      // 出站已读：优先走事件，避免误把「已读同步」当发送 ACK。
      if (_mapper.isOutgoingPrivateReadReceipt(msg) &&
          msg.status != WKSendMsgResult.sendLoading) {
        _onOutgoingReadFromWkRefresh(msg);
        return;
      }
      final int s = msg.status;
      if (s == WKSendMsgResult.sendFail ||
          s == WKSendMsgResult.noRelation ||
          s == WKSendMsgResult.blackList ||
          s == WKSendMsgResult.notOnWhiteList) {
        onSendFailure(msg);
        return;
      }
      onSendAck(msg);
    });

    WKIM.shared.connectionManager.connect();
    _isBound = true;
    return true;
  }

  void unbind() {
    _imRtDedupClear();
    if (_isBound) {
      WKIM.shared.messageManager.removeNewMsgListener(_listenerKey);
      WKIM.shared.messageManager.removeOnRefreshMsgListener(_listenerKey);
      WKIM.shared.connectionManager.removeOnConnectionStatus(_listenerKey);
      WKIM.shared.connectionManager.disconnect(true);
      _isBound = false;
    }
    _isSetup = false;
    _boundUid = null;
    _boundToken = null;
  }

  void dispose() {
    unbind();
  }

  void onIncomingMessage(Object? rawEvent) {
    if (_callSignalBridge.consumeRawImEvent(rawEvent)) {
      if (kDebugMode) {
        debugPrint('[im.chain] onIncomingMessage consumed by CallSignal');
      }
      return;
    }

    final message = _mapper.mapIncomingMessage(
      rawEvent,
      currentUserId: _effectiveMapperUserId,
    );
    if (message == null) {
      if (kDebugMode) {
        debugPrint(
          '[im.chain] onIncomingMessage map=null type=${rawEvent.runtimeType}',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[im.chain] onIncomingMessage→provider id=${message.id} '
        'cmn=${message.clientMsgNo} from=${message.fromUserId} to=${message.toUserId} '
        'g=${message.groupId} mapperViewer=$_effectiveMapperUserId',
      );
    }

    scheduleMicrotask(() {
      _messageProvider.receiveIncomingMessage(
        message,
        currentUserId: _effectiveMapperUserId,
      );
    });
  }

  void onIncomingMessages(Object? rawEvent) {
    if (rawEvent is List) {
      final List<Object?> regularEvents = <Object?>[];
      for (final Object? item in rawEvent) {
        if (!_callSignalBridge.consumeRawImEvent(item)) {
          regularEvents.add(item);
        }
      }
      if (regularEvents.isEmpty) {
        return;
      }
      rawEvent = regularEvents;
    } else if (_callSignalBridge.consumeRawImEvent(rawEvent)) {
      return;
    }

    final messages = _mapper.mapIncomingMessages(
      rawEvent,
      currentUserId: _effectiveMapperUserId,
    );
    if (messages.isEmpty) {
      if (kDebugMode) {
        debugPrint('[im.chain] onIncomingMessages map batch empty');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[im.chain] onIncomingMessages→provider count=${messages.length} '
        'mapperViewer=$_effectiveMapperUserId',
      );
    }

    scheduleMicrotask(() {
      _messageProvider.receiveIncomingMessages(
        messages,
        currentUserId: _effectiveMapperUserId,
      );
    });
  }

  /// WuKong：[WKMsgExtra.readed] 同步后的 refresh（见 [ImEventMapper.isOutgoingPrivateReadReceipt]）。
  void _onOutgoingReadFromWkRefresh(WKMsg msg) {
    final int? peerUserId = int.tryParse(msg.channelID);
    final int? viewerUserId = _effectiveMapperUserId;
    if (peerUserId == null || viewerUserId == null) {
      if (kDebugMode) {
        debugPrint(
          '[im.read] wk refresh skipped peer=$peerUserId viewer=$viewerUserId',
        );
      }
      return;
    }
    final int? uptoMessageId = int.tryParse(msg.messageID);
    final String cm = msg.clientMsgNO.trim();

    if (kDebugMode) {
      debugPrint(
        '[im.read] wk refresh peer=$peerUserId readed=${msg.wkMsgExtra?.readed} '
        'messageID=${msg.messageID} clientMsgNO=$cm',
      );
    }

    scheduleMicrotask(() {
      _messageProvider.applyOutgoingReadEvent(
        peerUserId: peerUserId,
        viewerUserId: viewerUserId,
        uptoMessageId: uptoMessageId != null && uptoMessageId > 0
            ? uptoMessageId
            : null,
        uptoClientMsgNo: cm.isNotEmpty ? cm : null,
      );
    });
  }

  void onSendAck(Object? rawEvent) {
    final localMessageId = _mapper.mapLocalMessageId(rawEvent);
    final status = _mapper.mapSendSuccessStatus(rawEvent);
    final hintMsgType = _mapper.mapAppMsgType(rawEvent);
    final applied = _messageProvider.applyMessageSendResult(
      localMessageId: localMessageId,
      serverMessageId: _mapper.mapServerMessageId(rawEvent),
      status: status,
      content: _mapper.mapUpdatedContent(rawEvent),
      hintMsgType: hintMsgType,
      fromUserId: _currentUserId,
    );
    if (!applied) {
      final refreshed = _mapper.mapIncomingMessage(
        rawEvent,
        currentUserId: _effectiveMapperUserId,
      );
      if (refreshed != null) {
        scheduleMicrotask(() {
          _messageProvider.receiveIncomingMessage(
            refreshed,
            currentUserId: _effectiveMapperUserId,
          );
        });
      }
    }
  }

  void onSendFailure(Object? rawEvent) {
    _messageProvider.applyMessageSendResult(
      localMessageId: _mapper.mapLocalMessageId(rawEvent),
      serverMessageId: _mapper.mapServerMessageId(rawEvent),
      status: _mapper.mapSendFailureStatus(rawEvent),
      content: _mapper.mapUpdatedContent(rawEvent),
      hintMsgType: _mapper.mapAppMsgType(rawEvent),
      fromUserId: _currentUserId,
    );
  }

  void onReadReceipt(Object? rawEvent) {
    // 独立「会话未读」事件仍保留；私聊消息级已读走 [addOnRefreshMsgListener] + [WKMsgExtra.readed]。
    final targetId = _mapper.mapReadReceiptTargetId(rawEvent);
    final type = _mapper.mapReadReceiptType(rawEvent);
    final unreadCount = _mapper.mapReadReceiptUnreadCount(rawEvent);
    if (targetId == null || type == null || unreadCount == null) {
      return;
    }

    _messageProvider.updateConversationUnread(
      targetId: targetId,
      type: type,
      unreadCount: unreadCount,
    );
  }

  void onRecall(Object? rawEvent) {
    final messageId = _mapper.mapRecallMessageId(rawEvent);
    if (messageId == null) {
      return;
    }

    _messageProvider.applyMessageStatusUpdate(
      messageId: messageId,
      isRecalled: true,
    );
  }

  void onEdit(Object? rawEvent) {
    final messageId = _mapper.mapEditedMessageId(rawEvent);
    if (messageId == null) {
      return;
    }

    _messageProvider.applyMessageStatusUpdate(
      messageId: messageId,
      content: _mapper.mapUpdatedContent(rawEvent),
      isEdited: true,
    );
  }

  void onConversationUnreadSync(Object? rawEvent) {
    final targetId = _mapper.mapConversationUnreadTargetId(rawEvent);
    final type = _mapper.mapConversationUnreadType(rawEvent);
    final unreadCount = _mapper.mapConversationUnreadCount(rawEvent);
    if (targetId == null || type == null || unreadCount == null) {
      return;
    }

    _messageProvider.updateConversationUnread(
      targetId: targetId,
      type: type,
      unreadCount: unreadCount,
    );
  }

  /// Sends text only after [bind] succeeds. Returns false if not ready or
  /// text is empty (nothing sent).
  Future<bool> sendTextMessage({
    required int targetId,
    required int type,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      return false;
    }

    if (ImFeatureFlags.omitClientDirectImAfterRest) {
      if (kDebugMode) {
        debugPrint('[im.send] text via server only');
      }
      return true;
    }

    if (!await bind()) {
      return false;
    }
    final channel = _buildChannel(targetId: targetId, type: type);
    WKIM.shared.messageManager.sendMessage(
      WKTextContent(text.trim()),
      channel,
    );
    return true;
  }

  /// [remoteUrl] 优先：仅带已上传 OSS 的地址走 IM，避免再次传原文件。
  /// 否则使用 [filePath] 作为本地路径（兼容未先走 REST 的场景）。
  Future<bool> sendImageMessage({
    required int targetId,
    required int type,
    String? filePath,
    String? remoteUrl,
  }) async {
    final url = remoteUrl?.trim() ?? '';
    final local = filePath?.trim() ?? '';
    if (url.isEmpty && local.isEmpty) {
      return false;
    }

    if (!await bind()) {
      return false;
    }
    final channel = _buildChannel(targetId: targetId, type: type);
    final content = WKImageContent(0, 0);
    if (url.isNotEmpty) {
      content.url = url;
      content.localPath = '';
    } else {
      content.localPath = local;
    }
    WKIM.shared.messageManager.sendMessage(content, channel);
    return true;
  }

  Future<bool> sendAudioMessage({
    required int targetId,
    required int type,
    required int duration,
    String? filePath,
    String? remoteUrl,
  }) async {
    final url = remoteUrl?.trim() ?? '';
    final local = filePath?.trim() ?? '';
    if (url.isEmpty && local.isEmpty) {
      return false;
    }

    if (!await bind()) {
      return false;
    }
    final channel = _buildChannel(targetId: targetId, type: type);
    final content = WKVoiceContent(duration);
    if (url.isNotEmpty) {
      content.url = url;
      content.localPath = '';
    } else {
      content.localPath = local;
    }
    WKIM.shared.messageManager.sendMessage(content, channel);
    return true;
  }

  Future<bool> sendVideoMessage({
    required int targetId,
    required int type,
    int durationSeconds = 0,
    String? filePath,
    String? remoteUrl,
    String coverUrl = '',
  }) async {
    final url = remoteUrl?.trim() ?? '';
    final local = filePath?.trim() ?? '';
    if (url.isEmpty && local.isEmpty) {
      return false;
    }

    if (!await bind()) {
      return false;
    }
    final channel = _buildChannel(targetId: targetId, type: type);
    final content = WKVideoContent()
      ..second = durationSeconds;
    final c = coverUrl.trim();
    if (url.isNotEmpty) {
      content.url = url;
      content.localPath = '';
      if (c.isNotEmpty) {
        content.cover = c;
      }
    } else {
      content.localPath = local;
    }
    WKIM.shared.messageManager.sendMessage(content, channel);
    return true;
  }

  WKChannel _buildChannel({
    required int targetId,
    required int type,
  }) {
    final channelType =
        type == 2 ? WKChannelType.group : WKChannelType.personal;
    return WKChannel(targetId.toString(), channelType);
  }
}
