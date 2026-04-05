import 'package:hailiao_flutter/im/im_event_mapper.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/services/call_signal_bridge.dart';
import 'package:wukongimfluttersdk/common/options.dart';
import 'package:wukongimfluttersdk/entity/channel.dart';
import 'package:wukongimfluttersdk/model/wk_image_content.dart';
import 'package:wukongimfluttersdk/model/wk_text_content.dart';
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

  int? get _currentUserId => _authProvider.user?.id;
  String? get _currentUid => _authProvider.user?.id?.toString();
  String? get _currentToken => _authProvider.token;

  bool get isBound => _isBound;

  void bind() {
    if (_isBound) {
      return;
    }

    final uid = _currentUid;
    final token = _currentToken;
    if (uid == null || uid.isEmpty || token == null || token.isEmpty) {
      return;
    }

    if (!_isSetup) {
      WKIM.shared.setup(Options.newDefault(uid, token));
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

    WKIM.shared.messageManager.addOnRefreshMsgListener(_listenerKey, (msg) {
      // The public docs explicitly show this refresh hook. We reuse it as the
      // minimal ack/message-refresh entry point for now.
      onSendAck(msg);
    });

    WKIM.shared.connectionManager.connect();
    _isBound = true;
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

    final message = _mapper.mapIncomingMessage(rawEvent);
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

    final messages = _mapper.mapIncomingMessages(rawEvent);
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
    if (localMessageId == null) {
      final refreshed = _mapper.mapIncomingMessage(rawEvent);
      if (refreshed != null) {
        _messageProvider.receiveIncomingMessage(
          refreshed,
          currentUserId: _currentUserId,
        );
      }
      return;
    }

    _messageProvider.applyMessageSendResult(
      localMessageId: localMessageId,
      serverMessageId: _mapper.mapServerMessageId(rawEvent),
      status: status,
      content: _mapper.mapUpdatedContent(rawEvent),
    );
  }

  void onSendFailure(Object? rawEvent) {
    final localMessageId = _mapper.mapLocalMessageId(rawEvent);
    if (localMessageId == null) {
      return;
    }

    _messageProvider.applyMessageSendResult(
      localMessageId: localMessageId,
      status: _mapper.mapSendFailureStatus(rawEvent),
      content: _mapper.mapUpdatedContent(rawEvent),
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

  void sendTextMessage({
    required int targetId,
    required int type,
    required String text,
  }) {
    if (text.trim().isEmpty) {
      return;
    }

    _ensureReadyForSend();
    final channel = _buildChannel(targetId: targetId, type: type);
    WKIM.shared.messageManager.sendMessage(
      WKTextContent(text.trim()),
      channel,
    );
  }

  void sendImageMessage({
    required int targetId,
    required int type,
    required String filePath,
  }) {
    if (filePath.trim().isEmpty) {
      return;
    }

    _ensureReadyForSend();
    final channel = _buildChannel(targetId: targetId, type: type);
    final content = WKImageContent(0, 0)..localPath = filePath;
    WKIM.shared.messageManager.sendMessage(content, channel);
  }

  void sendAudioMessage({
    required int targetId,
    required int type,
    required String filePath,
    required int duration,
  }) {
    if (filePath.trim().isEmpty) {
      return;
    }

    _ensureReadyForSend();
    final channel = _buildChannel(targetId: targetId, type: type);
    final content = WKVoiceContent(duration)..localPath = filePath;
    WKIM.shared.messageManager.sendMessage(content, channel);
  }

  void _ensureReadyForSend() {
    if (!_isBound) {
      bind();
    }
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
