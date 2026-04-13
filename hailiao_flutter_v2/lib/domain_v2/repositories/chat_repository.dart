import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_message_mapper.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_send_args_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_event.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_service.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> loadMessages({
    required int targetId,
    required int type,
    required int? currentUserId,
    int page,
    int size,
  });

  Future<void> sendText({
    required int targetId,
    required int type,
    required int senderId,
    required String text,
    String? clientId,
  });

  Future<void> sendImage({
    required int targetId,
    required int type,
    required int senderId,
    required String imageUrl,
    String? clientId,
    int? imageWidth,
    int? imageHeight,
  });

  Future<void> markConversationRead({
    required int targetId,
    required int type,
  });

  Future<void> bindRealtime({
    required int? currentUserId,
    String? authToken,
  });

  void unbindRealtime();

  Stream<WukongImEvent> watchRealtimeEvents();
}

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({
    required ImMessageMapper mapper,
    required WukongImService imService,
  }) : _mapper = mapper,
       _imService = imService;

  final ImMessageMapper _mapper;
  final WukongImService _imService;

  @override
  Future<List<ChatMessage>> loadMessages({
    required int targetId,
    required int type,
    required int? currentUserId,
    int page = 1,
    int size = 20,
  }) async {
    final response = type == 2
        ? await ApiService.getGroupMessages(targetId, page, size)
        : await ApiService.getPrivateMessages(targetId, page, size);

    if (!response.isSuccess || response.data == null) {
      throw Exception(
        response.message.isNotEmpty ? response.message : '加载消息失败',
      );
    }

    final List<ChatMessage> messages = response.data!
        .map(
          (dto) => _mapper.mapMessage(
            dto,
            targetId: targetId,
            type: type,
            currentUserId: currentUserId,
          ),
        )
        .toList(growable: false);

    messages.sort((a, b) {
      final int aTime =
          DateTime.tryParse(a.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
      final int bTime =
          DateTime.tryParse(b.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
      return aTime.compareTo(bTime);
    });
    return messages;
  }

  @override
  Future<void> sendText({
    required int targetId,
    required int type,
    required int senderId,
    required String text,
    String? clientId,
  }) async {
    imSendArgsLog('repository_sendText', <String, Object?>{
      'inputTargetId': targetId.toString(),
      'inputType': type.toString(),
      'resolvedChannelId': targetId.toString(),
      'resolvedChannelType': type == 2 ? '2' : '1',
      'selfUserId': senderId.toString(),
      'clientId': clientId ?? '-',
      'clientMsgNO': '-',
      'textPreview': imSendTextPreview(text),
    });
    try {
      await _imService.sendText(
        targetId: targetId,
        type: type,
        text: text,
      );
    } catch (error) {
      throw Exception('发送文本消息失败: $error');
    }
  }

  @override
  Future<void> sendImage({
    required int targetId,
    required int type,
    required int senderId,
    required String imageUrl,
    String? clientId,
    int? imageWidth,
    int? imageHeight,
  }) async {
    imSendArgsLog('repository_sendImage', <String, Object?>{
      'inputTargetId': targetId.toString(),
      'inputType': type.toString(),
      'resolvedChannelId': targetId.toString(),
      'resolvedChannelType': type == 2 ? '2' : '1',
      'selfUserId': senderId.toString(),
      'clientId': clientId ?? '-',
      'clientMsgNO': '-',
      'textPreview': imageUrl.length > 80 ? '${imageUrl.substring(0, 80)}…' : imageUrl,
    });
    try {
      await _imService.sendImage(
        targetId: targetId,
        type: type,
        imageUrl: imageUrl,
        imageWidth: imageWidth ?? 0,
        imageHeight: imageHeight ?? 0,
      );
      imImageSendLog('repository_sendImage_ok', <String, Object?>{
        'targetId': targetId.toString(),
        'clientId': clientId ?? '-',
      });
    } catch (error, st) {
      imImageSendLog('repository_sendImage_rethrow', <String, Object?>{
        'targetId': targetId.toString(),
        'error': error.toString(),
        'stack': st.toString(),
      });
      throw Exception('发送图片消息失败: $error');
    }
  }

  @override
  Future<void> markConversationRead({
    required int targetId,
    required int type,
  }) async {
    // 后端仅有私聊「按对端用户」清零未读：POST /api/message/read/{fromUserId}。
    // 群会话未读目前仅依赖本地缓存清零 + 会话列表拉取；无对应 REST 时不在此调用。
    if (type != 1) {
      return;
    }

    final response = await ApiService.markAsRead(targetId);
    if (!response.isSuccess) {
      throw Exception(
        response.message.isNotEmpty ? response.message : '同步已读失败',
      );
    }
  }

  @override
  Future<void> bindRealtime({
    required int? currentUserId,
    String? authToken,
  }) {
    return _imService.bind(
      currentUserId: currentUserId,
      authToken: authToken,
    );
  }

  @override
  void unbindRealtime() {
    _imService.unbind();
  }

  @override
  Stream<WukongImEvent> watchRealtimeEvents() => _imService.events;
}
