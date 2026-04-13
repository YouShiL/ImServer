import 'dart:async';

import 'package:hailiao_flutter/config/app_config.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_message_mapper.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_send_args_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_event.dart';
import 'package:wukongimfluttersdk/common/options.dart';
import 'package:wukongimfluttersdk/entity/channel.dart';
import 'package:wukongimfluttersdk/entity/msg.dart';
import 'package:wukongimfluttersdk/model/wk_image_content.dart';
import 'package:wukongimfluttersdk/model/wk_text_content.dart';
import 'package:wukongimfluttersdk/type/const.dart';
import 'package:wukongimfluttersdk/wkim.dart';

class WukongImService {
  WukongImService({
    required ImMessageMapper mapper,
  }) : _mapper = mapper;

  final ImMessageMapper _mapper;
  final StreamController<WukongImEvent> _eventController =
      StreamController<WukongImEvent>.broadcast();
  final String _listenerKey =
      'hailiao_flutter_v2_wukong_${identityHashCode(Object())}';

  bool _isBound = false;
  bool _isSetup = false;
  int? _currentUserId;
  String? _boundUid;
  String? _boundToken;

  Stream<WukongImEvent> get events => _eventController.stream;
  bool get isBound => _isBound;

  Future<void> bind({
    required int? currentUserId,
    String? authToken,
  }) async {
    _currentUserId = currentUserId;
    final String? uid = currentUserId?.toString() ?? WKIM.shared.options.uid;
    final String? token = authToken?.trim().isNotEmpty == true
        ? authToken!.trim()
        : null;
    final bool credsChanged = _boundUid != uid || _boundToken != token;

    if (_isBound && !credsChanged) {
      return;
    }

    if (_isBound) {
      unbind();
    }

    if (!_isSetup &&
        uid != null &&
        uid.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      final bool setupOk = await WKIM.shared.setup(
        Options.newDefault(uid, token, addr: AppConfig.imTcpAddr),
      );
      if (!setupOk) {
        throw Exception('Failed to setup WuKongIM.');
      }
      _isSetup = true;
      _boundUid = uid;
      _boundToken = token;
    }

    WKIM.shared.messageManager.addOnNewMsgListener(_listenerKey, _onNewMessages);
    WKIM.shared.messageManager.addOnRefreshMsgListener(
      _listenerKey,
      _onRefreshMessage,
    );
    WKIM.shared.connectionManager.addOnConnectionStatus(
      _listenerKey,
      _onConnectionStatus,
    );
    _registerImageUploadAttachmentListener();
    _isBound = true;

    if (uid != null && uid.isNotEmpty && token != null && token.isNotEmpty) {
      WKIM.shared.connectionManager.connect();
    }
  }

  /// 业务侧已上传 OSS 并将 URL 写入 [WKImageContent] 时，通知 SDK「附件就绪」，以走通媒体分支并真正 [sendMessage]。
  /// SDK 内部为单例回调，每次 [bind] 成功路径上重新注册即可覆盖，不会叠加。
  void _registerImageUploadAttachmentListener() {
    WKIM.shared.messageManager.addOnUploadAttachmentListener(
      (WKMsg wkMsg, void Function(bool, WKMsg) back) {
        final dynamic mc = wkMsg.messageContent;
        if (mc is WKImageContent) {
          final String u = mc.url.trim();
          if (u.isNotEmpty) {
            imImageSendLog('wukong_attachment_listener_pass_image', <String, Object?>{
              'channelId': wkMsg.channelID,
              'urlLen': u.length.toString(),
            });
            back(true, wkMsg);
            return;
          }
        }
        back(false, wkMsg);
      },
    );
  }

  Future<void> sendText({
    required int targetId,
    required int type,
    required String text,
  }) async {
    final String resolvedText = text.trim();
    if (resolvedText.isEmpty) {
      throw Exception('Message text is empty.');
    }
    if (!_isBound) {
      throw Exception('WuKongIM is not bound for the current chat session.');
    }

    final int channelType =
        type == 2 ? WKChannelType.group : WKChannelType.personal;
    final String channelIdStr = targetId.toString();
    imSendArgsLog('wukong_sendText_before_sdk', <String, Object?>{
      'inputTargetId': targetId.toString(),
      'inputType': type.toString(),
      'resolvedChannelId': channelIdStr,
      'resolvedChannelType': channelType.toString(),
      'selfUserId': _currentUserId?.toString() ?? '-',
      'clientId': '-',
      'clientMsgNO': '(sdk_generates)',
      'textPreview': imSendTextPreview(resolvedText),
    });
    await WKIM.shared.messageManager.sendMessage(
      WKTextContent(resolvedText),
      WKChannel(channelIdStr, channelType),
    );
  }

  static const int _fallbackImageDim = 200;
  static const int _maxImageDim = 8192;

  /// [imageWidth]/[imageHeight] 为本地选图解码得到的像素；无效时回退为 [_fallbackImageDim]。
  Future<void> sendImage({
    required int targetId,
    required int type,
    required String imageUrl,
    int imageWidth = 0,
    int imageHeight = 0,
  }) async {
    final String url = imageUrl.trim();
    if (url.isEmpty) {
      throw Exception('Image url is empty.');
    }
    if (!_isBound) {
      throw Exception('WuKongIM is not bound for the current chat session.');
    }

    final int channelType =
        type == 2 ? WKChannelType.group : WKChannelType.personal;
    final String channelIdStr = targetId.toString();
    final int w;
    final int h;
    if (imageWidth > 0 && imageHeight > 0) {
      w = imageWidth.clamp(1, _maxImageDim);
      h = imageHeight.clamp(1, _maxImageDim);
    } else {
      w = _fallbackImageDim;
      h = _fallbackImageDim;
    }
    final WKImageContent content = WKImageContent(w, h);
    content.url = url;

    imSendArgsLog('wukong_sendImage_before_sdk', <String, Object?>{
      'inputTargetId': targetId.toString(),
      'inputType': type.toString(),
      'resolvedChannelId': channelIdStr,
      'resolvedChannelType': channelType.toString(),
      'selfUserId': _currentUserId?.toString() ?? '-',
      'imageUrlPreview': url.length > 120 ? '${url.substring(0, 120)}…' : url,
      'imageW': w.toString(),
      'imageH': h.toString(),
    });

    imImageSendLog('wukong_sendImage_sdk_call', <String, Object?>{
      'targetId': targetId.toString(),
      'channelType': channelType.toString(),
      'channelId': channelIdStr,
      'imageW': w.toString(),
      'imageH': h.toString(),
      'urlLen': url.length.toString(),
      'sdkNote':
          'WKImageContent extends WKMediaMessageContent: SDK sendWithOption routes media to addOnUploadAttachmentListener; if listener missing, connectionManager.sendMessage is not invoked (see wukong message_manager sendWithOption).',
    });

    try {
      await WKIM.shared.messageManager.sendMessage(
        content,
        WKChannel(channelIdStr, channelType),
      );
      imImageSendLog('wukong_sendImage_sdk_await_returned', <String, Object?>{
        'targetId': targetId.toString(),
        'channelId': channelIdStr,
      });
    } catch (e, st) {
      imImageSendLog('wukong_sendImage_sdk_throw', <String, Object?>{
        'targetId': targetId.toString(),
        'channelId': channelIdStr,
        'error': e.toString(),
        'stack': st.toString(),
      });
      rethrow;
    }
  }

  void unbind() {
    if (!_isBound) {
      return;
    }
    WKIM.shared.messageManager.removeNewMsgListener(_listenerKey);
    WKIM.shared.messageManager.removeOnRefreshMsgListener(_listenerKey);
    WKIM.shared.connectionManager.removeOnConnectionStatus(_listenerKey);
    _isBound = false;
  }

  void _onNewMessages(List<WKMsg> messages) {
    for (final WKMsg message in messages) {
      final WukongImEvent? event = _mapper.mapIncomingEvent(
        message,
        currentUserId: _currentUserId,
      );
      if (event != null && !_eventController.isClosed) {
        _eventController.add(event);
      }
    }
  }

  void _onRefreshMessage(WKMsg message) {
    if (message.messageContent is WKImageContent) {
      final WKImageContent ic = message.messageContent! as WKImageContent;
      imImageSendLog('wukong_refresh_sdk_image', <String, Object?>{
        'channelId': message.channelID,
        'channelType': message.channelType.toString(),
        'status': message.status.toString(),
        'contentType': message.contentType.toString(),
        'clientMsgNO': message.clientMsgNO,
        'messageID': message.messageID,
        'clientSeq': message.clientSeq.toString(),
        'content_url_len': ic.url.trim().length.toString(),
        'content_localPath_len': ic.localPath.trim().length.toString(),
        'raw_content_len': message.content.trim().length.toString(),
        'statusHint':
            '0=sendLoading 1=sendSuccess 2=sendFail 3=noRelation 4=blackList 13=notOnWhiteList',
      });
    }
    final WukongImEvent? event = _mapper.mapRefreshEvent(
      message,
      currentUserId: _currentUserId,
    );
    if (event != null && !_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _onConnectionStatus(int status, int? reason, dynamic _) {
    if (_eventController.isClosed) {
      return;
    }
    _eventController.add(
      WukongImEvent.connection(
        status: status,
        reason: reason,
      ),
    );
  }

  void dispose() {
    unbind();
    _eventController.close();
  }
}
