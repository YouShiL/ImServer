import 'package:hailiao_flutter/config/app_config.dart';
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
  static const String _listenerKey = 'hailiao_im_bridge';

  int? get _currentUserId => _authProvider.messagingUserId;
  String? get _currentUid => _currentUserId?.toString();
  String? get _currentToken => _authProvider.token;

  bool get isBound => _isBound;

  /// Returns true when IM SDK setup/listeners/connect have been applied for
  /// the current auth credentials. Returns false if uid/token are missing.
  bool bind() {
    if (_isBound) {
      return true;
    }

    final uid = _currentUid;
    final token = _currentToken;
    if (uid == null || uid.isEmpty || token == null || token.isEmpty) {
      return false;
    }

    if (!_isSetup) {
      final opts = Options.newDefault(
        uid,
        token,
        addr: AppConfig.imTcpAddr,
      )..debug = AppConfig.imSdkDebug;
      WKIM.shared.setup(opts);
      _isSetup = true;
    }

    if (!_isInsertedListenerRegistered) {
      WKIM.shared.messageManager.addOnMsgInsertedListener((wkMsg) {
        onIncomingMessage(wkMsg);
      });
      _isInsertedListenerRegistered = true;
    }

    WKIM.shared.connectionManager.addOnConnectionStatus(
      _listenerKey,
      (status, reason, connectInfo) {
        // TODO: Optionally expose connection state to the app when needed.
      },
    );

    WKIM.shared.messageManager.addOnNewMsgListener(_listenerKey, (msgs) {
      onIncomingMessages(msgs);
    });

    WKIM.shared.messageManager.addOnRefreshMsgListener(_listenerKey, (WKMsg msg) {
      // WuKongIM routes both send acks and send failures through refresh
      // (updateSendResult / updateMsgStatusFail → setRefreshMsg). There is no
      // separate failure listener; branch on [WKMsg.status].
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
    if (!_isBound) {
      return;
    }

    WKIM.shared.messageManager.removeNewMsgListener(_listenerKey);
    WKIM.shared.messageManager.removeOnRefreshMsgListener(_listenerKey);
    WKIM.shared.connectionManager.removeOnConnectionStatus(_listenerKey);
    WKIM.shared.connectionManager.disconnect(true);
    _isBound = false;
  }

  void dispose() {
    unbind();
  }

  void onIncomingMessage(Object? rawEvent) {
    if (_callSignalBridge.consumeRawImEvent(rawEvent)) {
      return;
    }

    final message = _mapper.mapIncomingMessage(
      rawEvent,
      currentUserId: _currentUserId,
    );
    if (message == null) {
      return;
    }

    _messageProvider.receiveIncomingMessage(
      message,
      currentUserId: _currentUserId,
    );
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
      currentUserId: _currentUserId,
    );
    if (messages.isEmpty) {
      return;
    }

    _messageProvider.receiveIncomingMessages(
      messages,
      currentUserId: _currentUserId,
    );
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
        currentUserId: _currentUserId,
      );
      if (refreshed != null) {
        _messageProvider.receiveIncomingMessage(
          refreshed,
          currentUserId: _currentUserId,
        );
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
  bool sendTextMessage({
    required int targetId,
    required int type,
    required String text,
  }) {
    if (text.trim().isEmpty) {
      return false;
    }

    if (!bind()) {
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
  bool sendImageMessage({
    required int targetId,
    required int type,
    String? filePath,
    String? remoteUrl,
  }) {
    final url = remoteUrl?.trim() ?? '';
    final local = filePath?.trim() ?? '';
    if (url.isEmpty && local.isEmpty) {
      return false;
    }

    if (!bind()) {
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

  bool sendAudioMessage({
    required int targetId,
    required int type,
    required int duration,
    String? filePath,
    String? remoteUrl,
  }) {
    final url = remoteUrl?.trim() ?? '';
    final local = filePath?.trim() ?? '';
    if (url.isEmpty && local.isEmpty) {
      return false;
    }

    if (!bind()) {
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

  bool sendVideoMessage({
    required int targetId,
    required int type,
    int durationSeconds = 0,
    String? filePath,
    String? remoteUrl,
    String coverUrl = '',
  }) {
    final url = remoteUrl?.trim() ?? '';
    final local = filePath?.trim() ?? '';
    if (url.isEmpty && local.isEmpty) {
      return false;
    }

    if (!bind()) {
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
