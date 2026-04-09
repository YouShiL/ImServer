import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/file_upload_result_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/message_outgoing_status.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/config/im_feature_flags.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/theme/chat_date_format.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';
import 'package:uuid/uuid.dart';

abstract class MessageApi {
  Future<ResponseDTO<List<ConversationDTO>>> getConversations();
  Future<ResponseDTO<List<MessageDTO>>> getPrivateMessages(
    int toUserId,
    int page,
    int size,
  );
  Future<ResponseDTO<List<MessageDTO>>> getGroupMessages(
    int groupId,
    int page,
    int size,
  );
  Future<ResponseDTO<MessageDTO>> sendPrivateMessage(
    int toUserId,
    String content,
    int msgType, {
    String? clientMsgNo,
  });
  Future<ResponseDTO<MessageDTO>> sendGroupMessage(
    int groupId,
    String content,
    int msgType, {
    String? clientMsgNo,
  });
  Future<ResponseDTO<String>> recallMessage(int messageId);
  Future<ResponseDTO<MessageDTO>> replyMessage({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType,
  });
  Future<ResponseDTO<MessageDTO>> editMessage(int messageId, String newContent);
  Future<ResponseDTO<MessageDTO>> forwardMessage({
    required int originalMsgId,
    int? toUserId,
    int? groupId,
  });
  Future<ResponseDTO<String>> markAsRead(int fromUserId);
  Future<ResponseDTO<ConversationDTO>> updateConversation(
    int conversationId,
    Map<String, dynamic> data,
  );
  Future<ResponseDTO<String>> deleteConversation(
    int conversationId, {
    required int type,
  });
  Future<ResponseDTO<FileUploadResultDTO>> uploadImage(String filePath);
  Future<ResponseDTO<FileUploadResultDTO>> uploadVideo(String filePath);
  Future<ResponseDTO<FileUploadResultDTO>> uploadAudio(String filePath);
  Future<ResponseDTO<MessageDTO>> sendImageMessage(
    int targetId,
    String imageUrl, {
    bool isGroup,
  });
  Future<ResponseDTO<MessageDTO>> sendVideoMessage(
    int targetId,
    String videoUrl,
    String coverUrl,
    int duration, {
    bool isGroup,
  });
  Future<ResponseDTO<MessageDTO>> sendAudioMessage(
    int targetId,
    String audioUrl,
    int duration, {
    bool isGroup,
  });
}

class ApiMessageApi implements MessageApi {
  @override
  Future<ResponseDTO<List<ConversationDTO>>> getConversations() {
    return ApiService.getConversations();
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> getPrivateMessages(
    int toUserId,
    int page,
    int size,
  ) {
    return ApiService.getPrivateMessages(toUserId, page, size);
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> getGroupMessages(
    int groupId,
    int page,
    int size,
  ) {
    return ApiService.getGroupMessages(groupId, page, size);
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendPrivateMessage(
    int toUserId,
    String content,
    int msgType, {
    String? clientMsgNo,
  }) {
    return ApiService.sendPrivateMessage(
      toUserId,
      content,
      msgType,
      clientMsgNo: clientMsgNo,
    );
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendGroupMessage(
    int groupId,
    String content,
    int msgType, {
    String? clientMsgNo,
  }) {
    return ApiService.sendGroupMessage(
      groupId,
      content,
      msgType,
      clientMsgNo: clientMsgNo,
    );
  }

  @override
  Future<ResponseDTO<String>> recallMessage(int messageId) {
    return ApiService.recallMessage(messageId);
  }

  @override
  Future<ResponseDTO<MessageDTO>> replyMessage({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType = 1,
  }) {
    return ApiService.replyMessage(
      replyToMsgId: replyToMsgId,
      toUserId: toUserId,
      groupId: groupId,
      content: content,
      msgType: msgType,
    );
  }

  @override
  Future<ResponseDTO<MessageDTO>> editMessage(int messageId, String newContent) {
    return ApiService.editMessage(messageId, newContent);
  }

  @override
  Future<ResponseDTO<MessageDTO>> forwardMessage({
    required int originalMsgId,
    int? toUserId,
    int? groupId,
  }) {
    return ApiService.forwardMessage(
      originalMsgId: originalMsgId,
      toUserId: toUserId,
      groupId: groupId,
    );
  }

  @override
  Future<ResponseDTO<String>> markAsRead(int fromUserId) {
    return ApiService.markAsRead(fromUserId);
  }

  @override
  Future<ResponseDTO<ConversationDTO>> updateConversation(
    int conversationId,
    Map<String, dynamic> data,
  ) {
    return ApiService.updateConversation(conversationId, data);
  }

  @override
  Future<ResponseDTO<String>> deleteConversation(
    int conversationId, {
    required int type,
  }) {
    return ApiService.deleteConversation(conversationId, type: type);
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadImage(String filePath) {
    return ApiService.uploadImage(filePath);
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadVideo(String filePath) {
    return ApiService.uploadVideo(filePath);
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadAudio(String filePath) {
    return ApiService.uploadAudio(filePath);
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendImageMessage(
    int targetId,
    String imageUrl, {
    bool isGroup = false,
  }) {
    return ApiService.sendImageMessage(targetId, imageUrl, isGroup: isGroup);
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendVideoMessage(
    int targetId,
    String videoUrl,
    String coverUrl,
    int duration, {
    bool isGroup = false,
  }) {
    return ApiService.sendVideoMessage(
      targetId,
      videoUrl,
      coverUrl,
      duration,
      isGroup: isGroup,
    );
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendAudioMessage(
    int targetId,
    String audioUrl,
    int duration, {
    bool isGroup = false,
  }) {
    return ApiService.sendAudioMessage(
      targetId,
      audioUrl,
      duration,
      isGroup: isGroup,
    );
  }
}

/// Local retry payload for failed optimistic media sends (in-memory only).
class MediaRetryParams {
  const MediaRetryParams({
    required this.path,
    required this.msgType,
    this.durationSeconds = 0,
  });

  final String path;
  final int msgType;
  final int durationSeconds;
}

class MessageProvider extends ChangeNotifier {
  MessageProvider({MessageApi? api}) : _api = api ?? ApiMessageApi();

  final MessageApi _api;
  List<ConversationDTO> _conversations = [];
  List<MessageDTO> _messages = [];
  final Map<String, String> _drafts = {};
  bool _isLoading = false;
  String? _error;

  /// 每条私聊会话最近一次由 IM 已读事件更新的时间（用于轻量轮询跳过）。
  final Map<int, DateTime> _lastOutgoingReadEventAtByPeer = {};

  /// 聊天页当前打开的会话：`type_targetId`，与 [_findConversationIndex] 一致。
  String? _activeConversationKey;

  List<ConversationDTO> get conversations => _conversations;

  static String conversationActivityKey(int targetId, int type) =>
      '${type}_$targetId';

  void setActiveConversation(int targetId, int type) {
    _activeConversationKey = conversationActivityKey(targetId, type);
  }

  void clearActiveConversation() {
    _activeConversationKey = null;
  }

  bool _isActiveConversation(int targetId, int type) =>
      _activeConversationKey == conversationActivityKey(targetId, type);

  /// 供聊天页判断是否与当前打开的会话一致（已读上报等）。
  bool isActiveConversation(int targetId, int type) =>
      _isActiveConversation(targetId, type);

  List<MessageDTO> get messages => _messages;

  /// 当前聊天页应展示的行（与 [retainEphemeralMessagesForChat] / 历史合并的归属判定一致）。
  List<MessageDTO> messagesForChat({
    required int targetId,
    required int type,
    int? currentUserId,
  }) {
    final out = _messages
        .where(
          (m) => _messageBelongsToConversation(
                m,
                targetId,
                type,
                currentUserId: currentUserId,
              ),
        )
        .toList(growable: false);

    if (kDebugMode) {
      final tailStart = _messages.length <= 5 ? 0 : _messages.length - 5;
      for (var i = tailStart; i < _messages.length; i++) {
        final MessageDTO m = _messages[i];
        final bool belongs = _messageBelongsToConversation(
          m,
          targetId,
          type,
          currentUserId: currentUserId,
        );
        debugPrint(
          '[im.chat.filter] store#$i id=${m.id} clientMsgNo=${m.clientMsgNo} '
          'from=${m.fromUserId} to=${m.toUserId} g=${m.groupId} belongs=$belongs '
          '(openTarget=$targetId openType=$type viewer=$currentUserId threadLen=${out.length})',
        );
      }
    }

    return out;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Monotonic negative ids for local optimistic rows (not persisted).
  int _optimisticLocalIdSeq = 0;

  String _newClientMsgNoV4() => const Uuid().v4();

  /// 文本 REST：优先用乐观行已有键（重试必须一致）；无乐观行则现生成。
  String? _resolveClientMsgNoForTextApi(int msgType, int? optimisticLocalId) {
    if (msgType != 1) return null;
    if (optimisticLocalId != null && optimisticLocalId != 0) {
      final idx = _findMessageIndexById(optimisticLocalId);
      if (idx != null) {
        final c = _messages[idx].clientMsgNo?.trim();
        if (c != null && c.isNotEmpty) return c;
      }
    }
    return _newClientMsgNoV4();
  }

  /// 乐观合并 / IM 回显：clientMsgNo — id — 正文（旧逻辑兜底）。
  bool _outgoingTextMatchesForMerge(
    MessageDTO local,
    MessageDTO incoming,
    String incomingContentTrimmed,
  ) {
    final ic = incoming.clientMsgNo?.trim();
    final lc = local.clientMsgNo?.trim();
    if (ic != null &&
        ic.isNotEmpty &&
        lc != null &&
        lc.isNotEmpty &&
        ic != lc) {
      return false;
    }
    if (ic != null &&
        ic.isNotEmpty &&
        lc != null &&
        lc.isNotEmpty &&
        ic == lc) {
      return true;
    }
    final ii = incoming.id;
    final li = local.id;
    if (ii != null && li != null && ii == li) {
      return true;
    }
    return (local.content ?? '').trim() == incomingContentTrimmed;
  }

  bool _confirmedTextRowDuplicate(MessageDTO incoming, MessageDTO row) {
    final ic = incoming.clientMsgNo?.trim();
    final rc = row.clientMsgNo?.trim();
    if (ic != null &&
        ic.isNotEmpty &&
        rc != null &&
        rc.isNotEmpty &&
        ic != rc) {
      return false;
    }
    if (ic != null &&
        ic.isNotEmpty &&
        rc != null &&
        rc.isNotEmpty &&
        ic == rc) {
      return true;
    }
    final ii = incoming.id;
    final ri = row.id;
    if (ii != null && ri != null && ii == ri) {
      return true;
    }
    return (incoming.content ?? '').trim() == (row.content ?? '').trim();
  }

  int addOptimisticTextMessage({
    required int targetId,
    required int type,
    required String content,
    int? fromUserId,
    int? replyToMsgId,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return 0;
    }

    final failedIdx = _findFailedOptimisticText(
      targetId: targetId,
      type: type,
      content: trimmed,
      fromUserId: fromUserId,
    );
    if (failedIdx != null) {
      final current = _messages[failedIdx];
      final String cm = (current.clientMsgNo != null &&
              current.clientMsgNo!.trim().isNotEmpty)
          ? current.clientMsgNo!.trim()
          : _newClientMsgNoV4();
      final reused = MessageDTO(
        id: current.id,
        msgId: current.msgId,
        clientMsgNo: cm,
        fromUserId: current.fromUserId,
        toUserId: current.toUserId,
        groupId: current.groupId,
        content: trimmed,
        msgType: 1,
        subType: current.subType,
        extra: current.extra,
        isRead: current.isRead,
        isRecalled: current.isRecalled,
        isDeleted: current.isDeleted,
        replyToMsgId: current.replyToMsgId,
        forwardFromMsgId: current.forwardFromMsgId,
        forwardFromUserId: current.forwardFromUserId,
        isEdited: current.isEdited,
        status: MessageOutgoingStatus.sending,
        createdAt: current.createdAt ??
            ChatDateFormat.fromMillis(
              DateTime.now().millisecondsSinceEpoch,
            ),
        fromUserInfo: current.fromUserInfo,
      );
      _messages[failedIdx] = reused;
      upsertConversationFromMessage(
        reused,
        currentUserId: fromUserId,
        increaseUnread: false,
      );
      refreshConversationPreview(targetId: targetId, type: type);
      notifyListeners();
      return current.id ?? 0;
    }

    final localId = --_optimisticLocalIdSeq;
    final message = MessageDTO(
      id: localId,
      clientMsgNo: _newClientMsgNoV4(),
      fromUserId: fromUserId,
      toUserId: type == 1 ? targetId : null,
      groupId: type == 2 ? targetId : null,
      content: trimmed,
      msgType: 1,
      replyToMsgId: replyToMsgId,
      status: MessageOutgoingStatus.sending,
      createdAt:
          ChatDateFormat.fromMillis(DateTime.now().millisecondsSinceEpoch),
    );
    _insertMessage(message, currentUserId: fromUserId);
    upsertConversationFromMessage(
      message,
      currentUserId: fromUserId,
      increaseUnread: false,
    );
    refreshConversationPreview(targetId: targetId, type: type);
    notifyListeners();
    return localId;
  }

  /// Optimistic image / audio / video (local path in [content]).
  int addOptimisticMediaMessage({
    required int targetId,
    required int type,
    required int msgType,
    required String content,
    int? fromUserId,
    int durationSeconds = 0,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    if (msgType < 2 || msgType > 4) {
      return 0;
    }

    final failedIdx = _findFailedOptimisticMedia(
      targetId: targetId,
      type: type,
      msgType: msgType,
      content: trimmed,
      fromUserId: fromUserId,
    );
    final String? extraDur = (msgType == 3 || msgType == 4) && durationSeconds > 0
        ? 'dur:$durationSeconds'
        : null;

    if (failedIdx != null) {
      final current = _messages[failedIdx];
      final reused = MessageDTO(
        id: current.id,
        msgId: current.msgId,
        fromUserId: current.fromUserId,
        toUserId: current.toUserId,
        groupId: current.groupId,
        content: trimmed,
        msgType: msgType,
        subType: current.subType,
        extra: extraDur ?? current.extra,
        isRead: current.isRead,
        isRecalled: current.isRecalled,
        isDeleted: current.isDeleted,
        replyToMsgId: current.replyToMsgId,
        forwardFromMsgId: current.forwardFromMsgId,
        forwardFromUserId: current.forwardFromUserId,
        isEdited: current.isEdited,
        status: MessageOutgoingStatus.sending,
        createdAt: current.createdAt ??
            ChatDateFormat.fromMillis(
              DateTime.now().millisecondsSinceEpoch,
            ),
        fromUserInfo: current.fromUserInfo,
      );
      _messages[failedIdx] = reused;
      upsertConversationFromMessage(
        reused,
        currentUserId: fromUserId,
        increaseUnread: false,
      );
      refreshConversationPreview(targetId: targetId, type: type);
      notifyListeners();
      return current.id ?? 0;
    }

    final localId = --_optimisticLocalIdSeq;
    final message = MessageDTO(
      id: localId,
      fromUserId: fromUserId,
      toUserId: type == 1 ? targetId : null,
      groupId: type == 2 ? targetId : null,
      content: trimmed,
      msgType: msgType,
      extra: extraDur,
      status: MessageOutgoingStatus.sending,
      createdAt:
          ChatDateFormat.fromMillis(DateTime.now().millisecondsSinceEpoch),
    );
    _insertMessage(message, currentUserId: fromUserId);
    upsertConversationFromMessage(
      message,
      currentUserId: fromUserId,
      increaseUnread: false,
    );
    refreshConversationPreview(targetId: targetId, type: type);
    notifyListeners();
    return localId;
  }

  void markOutgoingTextSendFailed(int messageId) {
    if (messageId == 0) {
      return;
    }
    final updated = _updateMessageById(
      messageId,
      (current) => MessageDTO(
        id: current.id,
        msgId: current.msgId,
        clientMsgNo: current.clientMsgNo,
        fromUserId: current.fromUserId,
        toUserId: current.toUserId,
        groupId: current.groupId,
        content: current.content,
        msgType: current.msgType,
        subType: current.subType,
        extra: current.extra,
        isRead: current.isRead,
        isRecalled: current.isRecalled,
        isDeleted: current.isDeleted,
        replyToMsgId: current.replyToMsgId,
        forwardFromMsgId: current.forwardFromMsgId,
        forwardFromUserId: current.forwardFromUserId,
        isEdited: current.isEdited,
        status: MessageOutgoingStatus.failed,
        createdAt: current.createdAt,
        fromUserInfo: current.fromUserInfo,
      ),
    );
    if (!updated) {
      return;
    }
    final idx = _findMessageIndexById(messageId);
    if (idx == null) {
      return;
    }
    final m = _messages[idx];
    final tid = _resolveConversationTargetId(m, currentUserId: m.fromUserId);
    final typ = _resolveConversationType(m);
    if (tid != null) {
      refreshConversationPreview(targetId: tid, type: typ);
    } else {
      upsertConversationFromMessage(m, increaseUnread: false);
    }
  }

  String? prepareRetryFailedTextMessage({
    required int messageId,
    required int targetId,
    required int type,
    required int fromUserId,
  }) {
    final idx = _findMessageIndexById(messageId);
    if (idx == null) {
      return null;
    }
    final m = _messages[idx];
    if (m.fromUserId != fromUserId) {
      return null;
    }
    if ((m.msgType ?? 1) != 1) {
      return null;
    }
    if (m.status != MessageOutgoingStatus.failed) {
      return null;
    }
    if (!_messageBelongsToConversation(
      m,
      targetId,
      type,
      currentUserId: fromUserId,
    )) {
      return null;
    }
    final text = (m.content ?? '').trim();
    if (text.isEmpty) {
      return null;
    }

    _messages[idx] = MessageDTO(
      id: m.id,
      msgId: m.msgId,
      clientMsgNo: m.clientMsgNo,
      fromUserId: m.fromUserId,
      toUserId: m.toUserId,
      groupId: m.groupId,
      content: m.content,
      msgType: m.msgType,
      subType: m.subType,
      extra: m.extra,
      isRead: m.isRead,
      isRecalled: m.isRecalled,
      isDeleted: m.isDeleted,
      replyToMsgId: m.replyToMsgId,
      forwardFromMsgId: m.forwardFromMsgId,
      forwardFromUserId: m.forwardFromUserId,
      isEdited: m.isEdited,
      status: MessageOutgoingStatus.sending,
      createdAt: m.createdAt,
      fromUserInfo: m.fromUserInfo,
    );
    refreshConversationPreview(targetId: targetId, type: type);
    return text;
  }

  MediaRetryParams? prepareRetryFailedMediaMessage({
    required int messageId,
    required int targetId,
    required int type,
    required int fromUserId,
  }) {
    final idx = _findMessageIndexById(messageId);
    if (idx == null) {
      return null;
    }
    final m = _messages[idx];
    if (m.fromUserId != fromUserId) {
      return null;
    }
    final mt = m.msgType ?? 1;
    if (mt < 2 || mt > 4) {
      return null;
    }
    if (m.status != MessageOutgoingStatus.failed) {
      return null;
    }
    if (!_messageBelongsToConversation(
      m,
      targetId,
      type,
      currentUserId: fromUserId,
    )) {
      return null;
    }
    final path = (m.content ?? '').trim();
    if (path.isEmpty) {
      return null;
    }
    var durationSeconds = 0;
    final ex = (m.extra ?? '').trim();
    if (ex.startsWith('dur:')) {
      durationSeconds = int.tryParse(ex.substring(4)) ?? 0;
    }

    _messages[idx] = MessageDTO(
      id: m.id,
      msgId: m.msgId,
      clientMsgNo: m.clientMsgNo,
      fromUserId: m.fromUserId,
      toUserId: m.toUserId,
      groupId: m.groupId,
      content: m.content,
      msgType: m.msgType,
      subType: m.subType,
      extra: m.extra,
      isRead: m.isRead,
      isRecalled: m.isRecalled,
      isDeleted: m.isDeleted,
      replyToMsgId: m.replyToMsgId,
      forwardFromMsgId: m.forwardFromMsgId,
      forwardFromUserId: m.forwardFromUserId,
      isEdited: m.isEdited,
      status: MessageOutgoingStatus.sending,
      createdAt: m.createdAt,
      fromUserInfo: m.fromUserInfo,
    );
    refreshConversationPreview(targetId: targetId, type: type);
    notifyListeners();
    return MediaRetryParams(
      path: path,
      msgType: mt,
      durationSeconds: durationSeconds,
    );
  }

  void receiveIncomingMessage(
    MessageDTO message, {
    int? currentUserId,
    bool notify = true,
  }) {
    if (kDebugMode) {
      debugPrint(
        '[im.insert] recv pre-insert id=${message.id} clientMsgNo=${message.clientMsgNo} '
        'from=${message.fromUserId} to=${message.toUserId} g=${message.groupId} '
        'content=${_debugImSnippet(message.content)}',
      );
    }
    final preview = _insertMessage(message, currentUserId: currentUserId);
    if (preview == null) {
      if (kDebugMode) {
        debugPrint('[im.insert] recv dropped (insert returned null)');
      }
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[im.chain] receiveIncomingMessage storeOk id=${preview.id} '
        'notify=$notify _messagesLen=${_messages.length}',
      );
    }
    upsertConversationFromMessage(
      preview,
      currentUserId: currentUserId,
      increaseUnread: _shouldIncreaseUnread(
        preview,
        currentUserId: currentUserId,
      ),
      notify: notify,
    );
  }

  void receiveIncomingMessages(
    List<MessageDTO> messages, {
    int? currentUserId,
    bool notify = true,
  }) {
    if (messages.isEmpty) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[im.insert] recv batch count=${messages.length} currentUserId=$currentUserId',
      );
    }

    final previews = _mergeMessages(messages, currentUserId: currentUserId);
    for (final preview in previews) {
      if (preview == null) {
        continue;
      }
      upsertConversationFromMessage(
        preview,
        currentUserId: currentUserId,
        increaseUnread: _shouldIncreaseUnread(
          preview,
          currentUserId: currentUserId,
        ),
        notify: false,
      );
    }
    if (notify) {
      notifyListeners();
    }
  }

  bool applyMessageStatusUpdate({
    required int messageId,
    int? status,
    bool? isRead,
    bool? isRecalled,
    bool? isEdited,
    String? content,
    bool notify = true,
  }) {
    final updated = _updateMessageById(
      messageId,
      (current) => MessageDTO(
        id: current.id,
        msgId: current.msgId,
        clientMsgNo: current.clientMsgNo,
        fromUserId: current.fromUserId,
        toUserId: current.toUserId,
        groupId: current.groupId,
        content: content ?? current.content,
        msgType: current.msgType,
        subType: current.subType,
        extra: current.extra,
        isRead: isRead ?? current.isRead,
        isRecalled: isRecalled ?? current.isRecalled,
        isDeleted: current.isDeleted,
        replyToMsgId: current.replyToMsgId,
        forwardFromMsgId: current.forwardFromMsgId,
        forwardFromUserId: current.forwardFromUserId,
        isEdited: isEdited ?? current.isEdited,
        status: status ?? current.status,
        createdAt: current.createdAt,
        fromUserInfo: current.fromUserInfo,
      ),
    );
    if (!updated) {
      return false;
    }

    final updatedMessage = _messages[_findMessageIndexById(messageId)!];
    upsertConversationFromMessage(
      updatedMessage,
      increaseUnread: false,
      notify: false,
    );
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  bool applyMessageSendResult({
    int? localMessageId,
    int? serverMessageId,
    required int status,
    String? content,
    int? hintMsgType,
    int? fromUserId,
    bool notify = true,
  }) {
    MessageDTO applySendResult(MessageDTO current) {
      final nextId = serverMessageId ??
          ((current.id != null && current.id! > 0)
              ? current.id
              : (localMessageId ?? current.id));
      final MessageDTO built = MessageDTO(
        id: nextId,
        msgId: current.msgId,
        clientMsgNo: current.clientMsgNo,
        fromUserId: current.fromUserId,
        toUserId: current.toUserId,
        groupId: current.groupId,
        content: content ?? current.content,
        msgType: current.msgType,
        subType: current.subType,
        extra: current.extra,
        isRead: current.isRead,
        isRecalled: current.isRecalled,
        isDeleted: current.isDeleted,
        replyToMsgId: current.replyToMsgId,
        forwardFromMsgId: current.forwardFromMsgId,
        forwardFromUserId: current.forwardFromUserId,
        isEdited: current.isEdited,
        status: status,
        createdAt: current.createdAt,
        fromUserInfo: current.fromUserInfo,
      );
      // SDK 可能先回 ACK 且仍为 sendLoading(0)，不可提前标为已送达。
      if (status == MessageOutgoingStatus.sending) {
        return built;
      }
      return _outgoingAfterSendSuccess(built);
    }

    var updated = false;
    if (localMessageId != null) {
      updated = _updateMessageById(localMessageId, applySendResult);
    }
    if (!updated) {
      var fallbackIdx = _findPendingOptimisticForSendResult(
        content: content,
        hintMsgType: hintMsgType,
        fromUserId: fromUserId,
      );
      if (fallbackIdx == null) {
        if (status == 1 &&
            (hintMsgType ?? 1) == 1 &&
            _swallowNearDuplicateSendAck(
              content: content,
              fromUserId: fromUserId,
            )) {
          if (notify) {
            notifyListeners();
          }
          return true;
        }
        if (status == MessageOutgoingStatus.sent &&
            _isAppMediaMsgType(hintMsgType) &&
            _swallowNearDuplicateMediaSendAck(
              content: content,
              hintMsgType: hintMsgType,
              fromUserId: fromUserId,
            )) {
          if (notify) {
            notifyListeners();
          }
          return true;
        }
        if (notify) {
          notifyListeners();
        }
        return false;
      }
      _messages[fallbackIdx] = applySendResult(_messages[fallbackIdx]);
      updated = true;
    }

    final resolvedId = serverMessageId ?? localMessageId;
    var syncIndex =
        resolvedId != null ? _findMessageIndexById(resolvedId) : null;
    syncIndex ??=
        serverMessageId != null ? _findMessageIndexById(serverMessageId) : null;
    if (syncIndex != null) {
      final synced = _messages[syncIndex];
      upsertConversationFromMessage(
        synced,
        increaseUnread: false,
        notify: false,
      );
      final tid = _resolveConversationTargetId(
        synced,
        currentUserId: synced.fromUserId,
      );
      final typ = _resolveConversationType(synced);
      if (tid != null) {
        refreshConversationPreview(targetId: tid, type: typ, notify: false);
      }
    }
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  void upsertConversationFromMessage(
    MessageDTO message, {
    int? currentUserId,
    bool increaseUnread = true,
    bool notify = true,
  }) {
    _updateConversationPreviewFromMessage(
      message,
      currentUserId: currentUserId,
      increaseUnread: increaseUnread,
    );
    _sortConversationsInternal();
    if (notify) {
      notifyListeners();
    }
  }

  void refreshConversationPreview({
    required int targetId,
    required int type,
    bool notify = true,
  }) {
    final conversationIndex = _findConversationIndex(targetId, type);
    if (conversationIndex == null) {
      return;
    }

    final int? ownerUserId = _conversations[conversationIndex].userId;

    MessageDTO? latestMessage;
    for (final message in _messages.reversed) {
      if (_messageBelongsToConversation(
            message,
            targetId,
            type,
            currentUserId: ownerUserId,
          )) {
        latestMessage = message;
        break;
      }
    }

    if (latestMessage == null) {
      return;
    }

    _updateConversationPreviewFromMessage(
      latestMessage,
      increaseUnread: false,
    );
    _sortConversationsInternal();
    if (notify) {
      notifyListeners();
    }
  }

  void updateConversationUnread({
    required int targetId,
    required int type,
    required int unreadCount,
    bool notify = true,
  }) {
    _setConversationUnread(targetId, type, unreadCount);
    _sortConversationsInternal();
    if (notify) {
      notifyListeners();
    }
  }

  String _draftKey(int? targetId, int? type) => '${type ?? 0}-${targetId ?? 0}';

  String? getDraft(int? targetId, int? type) {
    return _drafts[_draftKey(targetId, type)];
  }

  void setDraft(int? targetId, int? type, String value) {
    final key = _draftKey(targetId, type);
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _drafts.remove(key);
      _syncConversationDraftField(targetId, type, null);
    } else {
      _drafts[key] = value;
    }
    _sortConversations();
    notifyListeners();
  }

  void clearDraft(int? targetId, int? type) {
    _drafts.remove(_draftKey(targetId, type));
    _syncConversationDraftField(targetId, type, null);
    _sortConversations();
    notifyListeners();
  }

  /// 仅更新内存列表中的 [ConversationDTO.draft]，避免清空本地草稿后仍回落到滞后字段。
  void _syncConversationDraftField(int? targetId, int? type, String? draft) {
    if (targetId == null || type == null) {
      return;
    }
    final index = _findConversationIndex(targetId, type);
    if (index == null) {
      return;
    }
    final current = _conversations[index];
    _conversations[index] = ConversationDTO(
      id: current.id,
      userId: current.userId,
      targetId: current.targetId,
      type: current.type,
      name: current.name,
      avatar: current.avatar,
      lastMessage: current.lastMessage,
      lastMessageTime: current.lastMessageTime,
      unreadCount: current.unreadCount,
      isTop: current.isTop,
      isMute: current.isMute,
      draft: draft,
      isDeleted: current.isDeleted,
    );
  }

  Future<void> loadConversations() async {
    await _runListTask<ConversationDTO>(
      task: _api.getConversations,
      onSuccess: (data) {
        _conversations = data;
        _sortConversations();
      },
      fallbackError: 'Failed to load conversations.',
    );
  }

  Future<void> loadPrivateMessages(
    int toUserId,
    int page,
    int size, {
    int? viewerUserId,
  }) async {
    await _runListTask<MessageDTO>(
      task: () => _api.getPrivateMessages(toUserId, page, size),
      onSuccess: (data) {
        if (page == 1) {
          _messages = _mergeHistoryPage1WithPreservedLocals(
            data,
            conversationTargetId: toUserId,
            conversationType: 1,
            viewerUserId: viewerUserId,
          );
          _debugLogPrivateHistoryMerged(
            peerId: toUserId,
            viewerUserId: viewerUserId,
            serverSample: data,
          );
        } else {
          final chunk = data.map(_normalizeServerMessage).toList();
          final tie = <MessageDTO, int>{};
          for (var i = 0; i < chunk.length; i++) {
            tie[chunk[i]] = i;
          }
          chunk.sort((a, b) {
            final c = _compareMessagesForSort(a, b);
            if (c != 0) {
              return c;
            }
            return (tie[a] ?? 0).compareTo(tie[b] ?? 0);
          });
          _messages = [...chunk, ..._messages];
        }
      },
      fallbackError: 'Failed to load messages.',
    );
  }

  Future<void> loadGroupMessages(int groupId, int page, int size) async {
    await _runListTask<MessageDTO>(
      task: () => _api.getGroupMessages(groupId, page, size),
      onSuccess: (data) {
        if (page == 1) {
          _messages = _mergeHistoryPage1WithPreservedLocals(
            data,
            conversationTargetId: groupId,
            conversationType: 2,
            viewerUserId: null,
          );
        } else {
          final chunk = data.map(_normalizeServerMessage).toList();
          final tie = <MessageDTO, int>{};
          for (var i = 0; i < chunk.length; i++) {
            tie[chunk[i]] = i;
          }
          chunk.sort((a, b) {
            final c = _compareMessagesForSort(a, b);
            if (c != 0) {
              return c;
            }
            return (tie[a] ?? 0).compareTo(tie[b] ?? 0);
          });
          _messages = [...chunk, ..._messages];
        }
      },
      fallbackError: 'Failed to load messages.',
    );
  }

  Future<bool> sendPrivateMessage(
    int toUserId,
    String content,
    int msgType,
  ) async {
    return _sendMessageTask(
      task: () => _api.sendPrivateMessage(toUserId, content, msgType),
      fallbackError: 'Failed to send message.',
    );
  }

  MessageDTO _normalizeServerMessage(MessageDTO raw) {
    final at = ChatDateFormat.display(raw.createdAt) ?? raw.createdAt;
    final int? gid = raw.groupId;
    return MessageDTO(
      id: raw.id,
      msgId: raw.msgId,
      clientMsgNo: raw.clientMsgNo,
      fromUserId: raw.fromUserId,
      toUserId: raw.toUserId,
      groupId: gid == null || gid == 0 ? null : gid,
      content: raw.content,
      msgType: raw.msgType,
      subType: raw.subType,
      extra: raw.extra,
      isRead: raw.isRead,
      isRecalled: raw.isRecalled,
      isDeleted: raw.isDeleted,
      replyToMsgId: raw.replyToMsgId,
      forwardFromMsgId: raw.forwardFromMsgId,
      forwardFromUserId: raw.forwardFromUserId,
      isEdited: raw.isEdited,
      status: raw.status ?? 1,
      createdAt: at,
      fromUserInfo: raw.fromUserInfo,
    );
  }

  /// REST 成功后供 IM 携带的媒体 URL（优先用落库后的 content）。
  String? _urlForImAfterRest(MessageDTO merged, String uploadedUrl) {
    final fromServer = merged.content?.trim();
    if (fromServer != null && fromServer.isNotEmpty) {
      return fromServer;
    }
    final fb = uploadedUrl.trim();
    return fb.isNotEmpty ? fb : null;
  }

  /// REST/业务发送成功：保证不为「发送中」占位（避免服务端未填 status 时 UI 卡在 sending）。
  MessageDTO _outgoingAfterSendSuccess(MessageDTO merged) {
    if ((merged.status ?? MessageOutgoingStatus.sent) ==
        MessageOutgoingStatus.failed) {
      return merged;
    }
    return MessageDTO(
      id: merged.id,
      msgId: merged.msgId,
      clientMsgNo: merged.clientMsgNo,
      fromUserId: merged.fromUserId,
      toUserId: merged.toUserId,
      groupId: merged.groupId,
      content: merged.content,
      msgType: merged.msgType,
      subType: merged.subType,
      extra: merged.extra,
      isRead: merged.isRead,
      isRecalled: merged.isRecalled,
      isDeleted: merged.isDeleted,
      replyToMsgId: merged.replyToMsgId,
      forwardFromMsgId: merged.forwardFromMsgId,
      forwardFromUserId: merged.forwardFromUserId,
      isEdited: merged.isEdited,
      status: MessageOutgoingStatus.sent,
      createdAt: merged.createdAt,
      fromUserInfo: merged.fromUserInfo,
    );
  }

  void _applySentMessage(
    MessageDTO merged, {
    int? optimisticLocalId,
  }) {
    final MessageDTO row = _outgoingAfterSendSuccess(merged);
    if (optimisticLocalId != null && optimisticLocalId != 0) {
      final replaced =
          _updateMessageById(optimisticLocalId, (_) => row);
      if (!replaced) {
        _messages = [..._messages, row];
      }
    } else {
      _messages = [..._messages, row];
    }
  }

  /// IM / 服务端已读扩展：**只更新**已有「我→对方」且已送达（[MessageOutgoingStatus.sent]）的行的 [MessageDTO.isRead]。
  ///
  /// - [uptoMessageId]：所有本地 `id` 在 `(0, uptoMessageId]` 的出站消息标已读。
  /// - [uptoClientMsgNo]：`clientMsgNo` 精确匹配（兼容尚无服务端 id 的乐观行）；与 id 条件并集。
  void applyOutgoingReadEvent({
    required int peerUserId,
    required int viewerUserId,
    String? uptoClientMsgNo,
    int? uptoMessageId,
  }) {
    final String? ucm =
        uptoClientMsgNo != null && uptoClientMsgNo.trim().isNotEmpty
            ? uptoClientMsgNo.trim()
            : null;
    final int? umid =
        uptoMessageId != null && uptoMessageId > 0 ? uptoMessageId : null;
    if (ucm == null && umid == null) {
      return;
    }

    bool isSentForRead(MessageDTO m) {
      final int s = m.status ?? MessageOutgoingStatus.sent;
      return s == MessageOutgoingStatus.sent;
    }

    var any = false;
    for (final MessageDTO m in _messages) {
      if (m.groupId != null) {
        continue;
      }
      if (m.fromUserId != viewerUserId || m.toUserId != peerUserId) {
        continue;
      }
      if (!isSentForRead(m)) {
        continue;
      }
      if (m.isRead == true) {
        continue;
      }

      var mark = false;
      if (umid != null) {
        final int? id = m.id;
        if (id != null && id > 0 && id <= umid) {
          mark = true;
        }
      }
      if (!mark && ucm != null) {
        final String? c = m.clientMsgNo?.trim();
        if (c != null && c == ucm) {
          mark = true;
        }
      }
      if (!mark) {
        continue;
      }

      final int? mid = m.id;
      if (mid == null) {
        continue;
      }
      applyMessageStatusUpdate(
        messageId: mid,
        isRead: true,
        notify: false,
      );
      any = true;
    }

    if (any) {
      _lastOutgoingReadEventAtByPeer[peerUserId] = DateTime.now();
      notifyListeners();
    }
  }

  /// 私聊：对方已读后服务端会把「我→对方」消息的 [MessageDTO.isRead] 置 true。
  /// 无推送时拉最新一页对齐内存中的出站已读；轮询侧可 [skipIfRecentReadEvent] 与 IM 事件协同。
  Future<void> syncPrivateOutgoingReadFlags(
    int peerId, {
    required int viewerUserId,
    Duration skipIfRecentReadEvent = const Duration(seconds: 10),
  }) async {
    final DateTime? last = _lastOutgoingReadEventAtByPeer[peerId];
    if (last != null &&
        DateTime.now().difference(last) < skipIfRecentReadEvent) {
      return;
    }
    try {
      final response = await _api.getPrivateMessages(peerId, 1, 60);
      if (!response.isSuccess || response.data == null) {
        return;
      }
      final List<MessageDTO> slice =
          response.data!.map(_normalizeServerMessage).toList();
      final Set<int> readIds = <int>{};
      final Set<String> readCm = <String>{};
      for (final MessageDTO s in slice) {
        if (s.fromUserId != viewerUserId || s.toUserId != peerId) {
          continue;
        }
        if (s.isRead != true) {
          continue;
        }
        final int? id = s.id;
        if (id != null && id > 0) {
          readIds.add(id);
        }
        final String? cm = s.clientMsgNo?.trim();
        if (cm != null && cm.isNotEmpty) {
          readCm.add(cm);
        }
      }
      if (readIds.isEmpty && readCm.isEmpty) {
        return;
      }
      var any = false;
      for (final MessageDTO m in _messages) {
        if (m.fromUserId != viewerUserId || m.toUserId != peerId) {
          continue;
        }
        if (m.isRead == true) {
          continue;
        }
        final int? mid = m.id;
        bool shouldRead = false;
        if (mid != null && mid > 0 && readIds.contains(mid)) {
          shouldRead = true;
        } else {
          final String? c = m.clientMsgNo?.trim();
          if (c != null && c.isNotEmpty && readCm.contains(c)) {
            shouldRead = true;
          }
        }
        if (shouldRead && mid != null) {
          applyMessageStatusUpdate(
            messageId: mid,
            isRead: true,
            notify: false,
          );
          any = true;
        }
      }
      if (any) {
        notifyListeners();
      }
    } catch (_) {
      // 静默：不影响聊天主流程
    }
  }

  /// 私聊文本：先落库 REST（与会话历史一致），再交由调用方决定是否补发 IM。
  Future<bool> sendPrivateTextMessage(
    int toUserId,
    String content,
    int msgType, {
    int? optimisticLocalId,
  }) async {
    _startLoading();
    try {
      final String? clientMsgNo = _resolveClientMsgNoForTextApi(
        msgType,
        optimisticLocalId,
      );
      final response = await _api.sendPrivateMessage(
        toUserId,
        content,
        msgType,
        clientMsgNo: clientMsgNo,
      );
      if (response.isSuccess && response.data != null) {
        final merged = _normalizeServerMessage(response.data as MessageDTO);
        _applySentMessage(merged, optimisticLocalId: optimisticLocalId);
        await loadConversations();
        if (kDebugMode && ImFeatureFlags.omitClientDirectImAfterRest) {
          debugPrint('[im.send] text via server only');
        }
        return true;
      }
      _error = response.message;
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return false;
    } catch (_) {
      _error = 'Failed to send message.';
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> sendGroupMessage(
    int groupId,
    String content,
    int msgType,
  ) async {
    return _sendMessageTask(
      task: () => _api.sendGroupMessage(groupId, content, msgType),
      fallbackError: 'Failed to send message.',
    );
  }

  /// 群聊文本：先 REST 落库（与 getGroupMessages 一致），再由调用方补发 IM。
  Future<bool> sendGroupTextMessage(
    int groupId,
    String content,
    int msgType, {
    int? optimisticLocalId,
  }) async {
    _startLoading();
    try {
      final String? clientMsgNo = _resolveClientMsgNoForTextApi(
        msgType,
        optimisticLocalId,
      );
      final response = await _api.sendGroupMessage(
        groupId,
        content,
        msgType,
        clientMsgNo: clientMsgNo,
      );
      if (response.isSuccess && response.data != null) {
        final merged = _normalizeServerMessage(response.data as MessageDTO);
        _applySentMessage(merged, optimisticLocalId: optimisticLocalId);
        await loadConversations();
        if (kDebugMode && ImFeatureFlags.omitClientDirectImAfterRest) {
          debugPrint('[im.send] text via server only');
        }
        return true;
      }
      _error = response.message;
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return false;
    } catch (_) {
      _error = 'Failed to send message.';
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return false;
    } finally {
      _finishLoading();
    }
  }

  /// 图片：上传 OSS → REST 发图消息 → 替换乐观行；成功返回供 IM 使用的 URL。
  Future<String?> sendChatImageRest({
    required int targetId,
    required int chatType,
    required String filePath,
    int? optimisticLocalId,
  }) async {
    final isGroup = chatType == 2;
    _startLoading();
    try {
      final up = await _api.uploadImage(filePath);
      final url = up.data?.fileUrl;
      if (!up.isSuccess || url == null || url.trim().isEmpty) {
        _error =
            up.message.isNotEmpty ? up.message : '图片上传失败，请重试。';
        if (optimisticLocalId != null && optimisticLocalId != 0) {
          markOutgoingTextSendFailed(optimisticLocalId);
        }
        return null;
      }
      final trimmed = url.trim();
      final send =
          await _api.sendImageMessage(targetId, trimmed, isGroup: isGroup);
      if (send.isSuccess && send.data != null) {
        final merged = _normalizeServerMessage(send.data as MessageDTO);
        _applySentMessage(merged, optimisticLocalId: optimisticLocalId);
        await loadConversations();
        return _urlForImAfterRest(merged, trimmed);
      }
      _error = send.message.isNotEmpty ? send.message : '图片发送失败。';
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return null;
    } catch (_) {
      _error = '图片发送失败，请检查网络后重试。';
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return null;
    } finally {
      _finishLoading();
    }
  }

  /// 视频：上传 → REST；成功返回供 IM 使用的 URL。
  Future<String?> sendChatVideoRest({
    required int targetId,
    required int chatType,
    required String filePath,
    int? optimisticLocalId,
    String coverUrl = '',
    int durationSeconds = 0,
  }) async {
    final isGroup = chatType == 2;
    _startLoading();
    try {
      final up = await _api.uploadVideo(filePath);
      final url = up.data?.fileUrl;
      if (!up.isSuccess || url == null || url.trim().isEmpty) {
        _error =
            up.message.isNotEmpty ? up.message : '视频上传失败，请重试。';
        if (optimisticLocalId != null && optimisticLocalId != 0) {
          markOutgoingTextSendFailed(optimisticLocalId);
        }
        return null;
      }
      final trimmed = url.trim();
      final send = await _api.sendVideoMessage(
        targetId,
        trimmed,
        coverUrl,
        durationSeconds,
        isGroup: isGroup,
      );
      if (send.isSuccess && send.data != null) {
        final merged = _normalizeServerMessage(send.data as MessageDTO);
        _applySentMessage(merged, optimisticLocalId: optimisticLocalId);
        await loadConversations();
        return _urlForImAfterRest(merged, trimmed);
      }
      _error = send.message.isNotEmpty ? send.message : '视频发送失败。';
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return null;
    } catch (_) {
      _error = '视频发送失败，请检查网络后重试。';
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return null;
    } finally {
      _finishLoading();
    }
  }

  /// 语音：上传 → REST；成功返回供 IM 使用的 URL。
  Future<String?> sendChatAudioRest({
    required int targetId,
    required int chatType,
    required String filePath,
    required int durationSeconds,
    int? optimisticLocalId,
  }) async {
    final isGroup = chatType == 2;
    _startLoading();
    try {
      final up = await _api.uploadAudio(filePath);
      final url = up.data?.fileUrl;
      if (!up.isSuccess || url == null || url.trim().isEmpty) {
        _error =
            up.message.isNotEmpty ? up.message : '语音上传失败，请重试。';
        if (optimisticLocalId != null && optimisticLocalId != 0) {
          markOutgoingTextSendFailed(optimisticLocalId);
        }
        return null;
      }
      final trimmed = url.trim();
      final send = await _api.sendAudioMessage(
        targetId,
        trimmed,
        durationSeconds,
        isGroup: isGroup,
      );
      if (send.isSuccess && send.data != null) {
        final merged = _normalizeServerMessage(send.data as MessageDTO);
        _applySentMessage(merged, optimisticLocalId: optimisticLocalId);
        await loadConversations();
        return _urlForImAfterRest(merged, trimmed);
      }
      _error = send.message.isNotEmpty ? send.message : '语音发送失败。';
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return null;
    } catch (_) {
      _error = '语音发送失败，请检查网络后重试。';
      if (optimisticLocalId != null && optimisticLocalId != 0) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return null;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> recallMessage(int messageId) async {
    _startLoading();
    try {
      final response = await _api.recallMessage(messageId);
      if (!response.isSuccess) {
        _error = response.message;
        return false;
      }

      int? previewTargetId;
      var previewType = 1;
      final index = _messages.indexWhere((message) => message.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRecalled: true);
        final m = _messages[index];
        previewType = _resolveConversationType(m);
        previewTargetId =
            _resolveConversationTargetId(m, currentUserId: m.fromUserId);
      }
      await loadConversations();
      if (previewTargetId != null) {
        refreshConversationPreview(targetId: previewTargetId, type: previewType);
      }
      return true;
    } catch (_) {
      _error = 'Failed to recall message.';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> replyMessage({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType = 1,
    int? optimisticLocalId,
  }) async {
    MessageDTO mergeReplyResult(MessageDTO raw) {
      final mergedReplyId = raw.replyToMsgId ?? replyToMsgId;
      return MessageDTO(
        id: raw.id,
        msgId: raw.msgId,
        fromUserId: raw.fromUserId,
        toUserId: raw.toUserId,
        groupId: raw.groupId,
        content: raw.content,
        msgType: raw.msgType,
        subType: raw.subType,
        extra: raw.extra,
        isRead: raw.isRead,
        isRecalled: raw.isRecalled,
        isDeleted: raw.isDeleted,
        replyToMsgId: mergedReplyId,
        forwardFromMsgId: raw.forwardFromMsgId,
        forwardFromUserId: raw.forwardFromUserId,
        isEdited: raw.isEdited,
        status: raw.status ?? 1,
        createdAt: raw.createdAt,
        fromUserInfo: raw.fromUserInfo,
      );
    }

    _startLoading();
    try {
      final response = await _api.replyMessage(
        replyToMsgId: replyToMsgId,
        toUserId: toUserId,
        groupId: groupId,
        content: content,
        msgType: msgType,
      );
      if (response.isSuccess && response.data != null) {
        final merged =
            _outgoingAfterSendSuccess(mergeReplyResult(response.data as MessageDTO));
        if (optimisticLocalId != null) {
          final replaced =
              _updateMessageById(optimisticLocalId, (_) => merged);
          if (!replaced) {
            _messages = [..._messages, merged];
          }
        } else {
          _messages = [..._messages, merged];
        }
        await loadConversations();
        return true;
      }
      _error = response.message;
      if (optimisticLocalId != null) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return false;
    } catch (_) {
      _error = 'Failed to send reply.';
      if (optimisticLocalId != null) {
        markOutgoingTextSendFailed(optimisticLocalId);
      }
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> editMessage(int messageId, String newContent) async {
    _startLoading();
    try {
      final response = await _api.editMessage(messageId, newContent);
      if (!response.isSuccess || response.data == null) {
        _error = response.message;
        return false;
      }

      int? previewTargetId;
      var previewType = 1;
      final index = _messages.indexWhere((message) => message.id == messageId);
      if (index != -1) {
        _messages[index] = response.data as MessageDTO;
        final m = _messages[index];
        previewType = _resolveConversationType(m);
        previewTargetId =
            _resolveConversationTargetId(m, currentUserId: m.fromUserId);
      }
      await loadConversations();
      if (previewTargetId != null) {
        refreshConversationPreview(targetId: previewTargetId, type: previewType);
      }
      return true;
    } catch (_) {
      _error = 'Failed to edit message.';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> forwardMessage({
    required int originalMsgId,
    int? toUserId,
    int? groupId,
  }) async {
    _startLoading();
    try {
      final response = await _api.forwardMessage(
        originalMsgId: originalMsgId,
        toUserId: toUserId,
        groupId: groupId,
      );
      if (response.isSuccess) {
        await loadConversations();
        return true;
      }
      _error = response.message;
      return false;
    } catch (_) {
      _error = 'Failed to forward message.';
      return false;
    } finally {
      _finishLoading();
    }
  }

  /// [type]==1 时走 REST；群聊仅本地未读清零（与接口现状一致）。
  Future<bool> markAsRead(int targetId, {int type = 1}) async {
    if (kDebugMode) {
      debugPrint('[im.chat.audit] markAsRead enter targetId=$targetId type=$type');
    }
    try {
      if (type == 1) {
        final response = await _api.markAsRead(targetId);
        final bool ok = response.isSuccess;
        if (kDebugMode) {
          debugPrint(
            '[im.chat.audit] markAsRead ${ok ? 'success' : 'fail'} msg=${response.message}',
          );
        }
        if (ok) {
          _setConversationUnread(targetId, 1, 0);
          _sortConversationsInternal();
          notifyListeners();
        }
        return ok;
      }
      _setConversationUnread(targetId, type, 0);
      _sortConversationsInternal();
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[im.chat.audit] markAsRead success (local group clear)');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[im.chat.audit] markAsRead fail exception=$e\n$st');
      }
      return false;
    }
  }

  Future<bool> updateConversationSetting(
    int conversationId, {
    required int type,
    bool? isTop,
    bool? isMute,
  }) async {
    _startLoading();
    try {
      final payload = <String, dynamic>{'type': type};
      if (isTop != null) {
        payload['isTop'] = isTop;
      }
      if (isMute != null) {
        payload['isMute'] = isMute;
      }

      final response = await _api.updateConversation(conversationId, payload);
      if (!response.isSuccess) {
        _error = response.message;
        return false;
      }

      final index = _conversations.indexWhere(
        (conversation) => conversation.targetId == conversationId,
      );
      if (index != -1) {
        final current = _conversations[index];
        _conversations[index] = ConversationDTO(
          id: current.id,
          userId: current.userId,
          targetId: current.targetId,
          type: current.type,
          name: current.name,
          avatar: current.avatar,
          lastMessage: current.lastMessage,
          lastMessageTime: current.lastMessageTime,
          unreadCount: current.unreadCount,
          isTop: isTop ?? current.isTop,
          isMute: isMute ?? current.isMute,
          draft: current.draft,
          isDeleted: current.isDeleted,
        );
        _sortConversations();
      }

      return true;
    } catch (_) {
      _error = 'Failed to update conversation settings.';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> deleteConversation(int conversationId, {required int type}) async {
    _startLoading();
    try {
      final response =
          await _api.deleteConversation(conversationId, type: type);
      if (!response.isSuccess) {
        _error = response.message;
        return false;
      }

      _conversations = _conversations
          .where((conversation) => conversation.targetId != conversationId)
          .toList();
      return true;
    } catch (_) {
      _error = 'Failed to delete conversation.';
      return false;
    } finally {
      _finishLoading();
    }
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  /// 进入聊天页时调用：只保留当前会话在内存中的行（含推送/乐观写入已带正 [MessageDTO.id] 的消息），
  /// 去掉其他会话缓存，避免串会话；负 id 的本地行仍会在下方与远端第 1 页合并。
  void retainEphemeralMessagesForChat(
    int targetId,
    int type, {
    int? currentUserId,
  }) {
    final int before = _messages.length;
    _messages = _messages
        .where(
          (m) => _messageBelongsToConversation(
            m,
            targetId,
            type,
            currentUserId: currentUserId,
          ),
        )
        .toList();
    _debugLogRetainPrivate(
      type: type,
      targetId: targetId,
      currentUserId: currentUserId,
      before: before,
      after: _messages.length,
    );
    notifyListeners();
  }

  /// 与远端第 1 页历史合并仍保留在内存中的行：
  /// - 负 id：发送中/失败等本地行；
  /// - 正 id：本会话已在内存中、但第 1 页尚未返回的行（例如推送早于 REST 一致）。
  /// 接口分页多为「最新在前」，此处统一为升序：旧消息在上、最新在下。
  List<MessageDTO> _mergeHistoryPage1WithPreservedLocals(
    List<MessageDTO> serverPage, {
    required int conversationTargetId,
    required int conversationType,
    int? viewerUserId,
  }) {
    final serverNorm = serverPage.map(_normalizeServerMessage).toList();
    final serverIds = serverNorm.map((m) => m.id).whereType<int>().toSet();

    final preservedLocals = _messages
        .where(
          (m) =>
              m.id != null &&
              m.id! < 0 &&
              _messageBelongsToConversation(
                m,
                conversationTargetId,
                conversationType,
                currentUserId: viewerUserId,
              ),
        )
        .toList();

    final preservedSyncedNotInPage = _messages
        .where(
          (m) =>
              m.id != null &&
              m.id! > 0 &&
              _messageBelongsToConversation(
                m,
                conversationTargetId,
                conversationType,
                currentUserId: viewerUserId,
              ) &&
              !serverIds.contains(m.id),
        )
        .where(
          (m) => !_preservedDupOfServerPage1(
                serverNorm,
                m,
                viewerUserId,
              ),
        )
        .toList();

    final combined = [
      ...serverNorm,
      ...preservedLocals,
      ...preservedSyncedNotInPage,
    ];
    if (combined.isEmpty) {
      return combined;
    }
    final originalOrder = <MessageDTO, int>{};
    for (var i = 0; i < combined.length; i++) {
      originalOrder[combined[i]] = i;
    }

    return List<MessageDTO>.from(combined)
      ..sort((a, b) {
        final c = _compareMessagesForSort(a, b);
        if (c != 0) {
          return c;
        }
        return (originalOrder[a] ?? 0).compareTo(originalOrder[b] ?? 0);
      });
  }

  /// 升序：时间早的在前，适合 ListView 顶部→底部为旧→新。
  int _compareMessagesForSort(MessageDTO a, MessageDTO b) {
    final ma = ChatDateFormat.parseToMillis(a.createdAt);
    final mb = ChatDateFormat.parseToMillis(b.createdAt);
    if (ma != null && mb != null) {
      final cmp = ma.compareTo(mb);
      if (cmp != 0) {
        return cmp;
      }
    } else {
      final sa = (a.createdAt ?? '').trim();
      final sb = (b.createdAt ?? '').trim();
      if (sa.isNotEmpty || sb.isNotEmpty) {
        final sc = sa.compareTo(sb);
        if (sc != 0) {
          return sc;
        }
      }
    }

    final ia = a.id;
    final ib = b.id;
    if (ia != null && ib != null && ia != ib) {
      return ia.compareTo(ib);
    }
    if (ia != null && ib == null) {
      return -1;
    }
    if (ia == null && ib != null) {
      return 1;
    }
    return 0;
  }

  void removeMessagesLocal(Iterable<int> messageIds) {
    final ids = messageIds.toSet();
    if (ids.isEmpty) {
      return;
    }
    _messages = _messages
        .where((message) => message.id == null || !ids.contains(message.id))
        .toList();
    notifyListeners();
  }

  /// App [MessageDTO.msgType]: 2 image, 3 voice, 4 video.
  bool _isAppMediaMsgType(int? msgType) {
    final t = msgType ?? 0;
    return t >= 2 && t <= 4;
  }

  /// 与乐观行合并（仅 Sending / Failed）。已 REST 送达（status==1）的媒体 IM 回显由
  /// [_isMediaEchoDuplicateOfConfirmedOutgoing] 吞并，避免把业务 id 换成 IM id。
  int? _tryMergeOptimisticOutgoing(MessageDTO incoming, int? currentUserId) {
    if (currentUserId == null) {
      return null;
    }
    if (incoming.fromUserId != currentUserId) {
      return null;
    }

    final incomingType = incoming.msgType ?? 1;
    final incomingContent = (incoming.content ?? '').trim();
    final incomingKey = incoming.clientMsgNo?.trim();
    if (incomingContent.isEmpty &&
        (incomingKey == null || incomingKey.isEmpty)) {
      return null;
    }

    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.id == null) {
        continue;
      }
      final st = m.status;
      if (st == 1) {
        continue;
      }
      if (st != 0 && st != 2) {
        continue;
      }
      if ((m.msgType ?? 1) != incomingType) {
        continue;
      }
      if (m.fromUserId != currentUserId) {
        continue;
      }
      if (!_sameConversationForMerge(m, incoming)) {
        continue;
      }
      if (incomingType == 1) {
        if (!_outgoingTextMatchesForMerge(m, incoming, incomingContent)) {
          continue;
        }
      } else {
        if (!_mediaPathsRelate(m.content, incoming.content)) {
          continue;
        }
      }
      return i;
    }
    return null;
  }

  bool _sameConversationForMerge(MessageDTO a, MessageDTO b) {
    final ga = a.groupId;
    final gb = b.groupId;
    if (ga != null || gb != null) {
      return ga != null && gb != null && ga == gb;
    }
    return (a.toUserId == b.toUserId && a.fromUserId == b.fromUserId) ||
        (a.toUserId == b.fromUserId && a.fromUserId == b.toUserId);
  }

  int? _findFailedOptimisticText({
    required int targetId,
    required int type,
    required String content,
    int? fromUserId,
  }) {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.id == null || m.id! >= 0) {
        continue;
      }
      if (m.status != MessageOutgoingStatus.failed) {
        continue;
      }
      if ((m.msgType ?? 1) != 1) {
        continue;
      }
      if ((m.content ?? '').trim() != content) {
        continue;
      }
      if (fromUserId != null && m.fromUserId != fromUserId) {
        continue;
      }
      if (type == 2) {
        if (m.groupId != targetId) {
          continue;
        }
      } else {
        if (m.toUserId != targetId) {
          continue;
        }
      }
      return i;
    }
    return null;
  }

  int? _findFailedOptimisticMedia({
    required int targetId,
    required int type,
    required int msgType,
    required String content,
    int? fromUserId,
  }) {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.id == null || m.id! >= 0) {
        continue;
      }
      if (m.status != MessageOutgoingStatus.failed) {
        continue;
      }
      if ((m.msgType ?? 1) != msgType) {
        continue;
      }
      if ((m.content ?? '').trim() != content) {
        continue;
      }
      if (fromUserId != null && m.fromUserId != fromUserId) {
        continue;
      }
      if (type == 2) {
        if (m.groupId != targetId) {
          continue;
        }
      } else {
        if (m.toUserId != targetId) {
          continue;
        }
      }
      return i;
    }
    return null;
  }

  int? _findPendingOptimisticForSendResult({
    String? content,
    int? hintMsgType,
    int? fromUserId,
  }) {
    final ht = hintMsgType ?? 1;
    if (ht != 1) {
      for (var i = _messages.length - 1; i >= 0; i--) {
        final m = _messages[i];
        if (m.id == null || m.id! >= 0) {
          continue;
        }
        if ((m.status ?? 0) != 0) {
          continue;
        }
        if ((m.msgType ?? 1) != ht) {
          continue;
        }
        if (fromUserId != null && m.fromUserId != fromUserId) {
          continue;
        }
        final inc = (content ?? '').trim();
        if (inc.isNotEmpty &&
            !_mediaPathsRelate(m.content, content)) {
          continue;
        }
        return i;
      }
      return null;
    }

    final trimmed = (content ?? '').trim();
    int? found;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.id == null || m.id! >= 0) {
        continue;
      }
      if ((m.status ?? 0) != 0) {
        continue;
      }
      if ((m.msgType ?? 1) != 1) {
        continue;
      }
      if (fromUserId != null && m.fromUserId != fromUserId) {
        continue;
      }
      if (trimmed.isNotEmpty && (m.content ?? '').trim() != trimmed) {
        continue;
      }
      found = i;
    }
    return found;
  }

  bool _mediaPathsRelate(String? a, String? b) {
    final x = (a ?? '').trim();
    final y = (b ?? '').trim();
    if (x.isEmpty || y.isEmpty) {
      return false;
    }
    if (x == y) {
      return true;
    }
    return _mediaBasename(x) == _mediaBasename(y) &&
        _mediaBasename(x).isNotEmpty;
  }

  String _mediaBasename(String p) {
    final u = p.replaceAll('\\', '/');
    final i = u.lastIndexOf('/');
    return i < 0 ? u : u.substring(i + 1);
  }

  /// IM 发送成功回调时，REST 已先把乐观项换成正 id，找不到 pending 时若仅匹配到一条近期已送达文本则吞掉重复 ack。
  bool _swallowNearDuplicateSendAck({String? content, int? fromUserId}) {
    if (fromUserId == null) {
      return false;
    }
    final trimmed = (content ?? '').trim();
    if (trimmed.isEmpty) {
      return false;
    }
    var count = 0;
    for (var i = _messages.length - 1;
        i >= 0 && i >= _messages.length - 3;
        i--) {
      final m = _messages[i];
      if (m.fromUserId != fromUserId) {
        continue;
      }
      if (m.id == null || m.id! <= 0) {
        continue;
      }
      if ((m.status ?? 1) != 1) {
        continue;
      }
      if ((m.msgType ?? 1) != 1) {
        continue;
      }
      if ((m.content ?? '').trim() != trimmed) {
        continue;
      }
      count++;
    }
    return count == 1;
  }

  /// IM 媒体发送成功回执：REST 已把同一媒体行换成正 id 且 status==1 时，吞掉 ack，避免走
  /// [onSendAck] 的 [receiveIncomingMessage] 插第二条。
  bool _swallowNearDuplicateMediaSendAck({
    String? content,
    int? hintMsgType,
    int? fromUserId,
  }) {
    if (fromUserId == null) {
      return false;
    }
    if (!_isAppMediaMsgType(hintMsgType)) {
      return false;
    }
    final mt = hintMsgType!;
    final inc = (content ?? '').trim();
    if (inc.isEmpty) {
      return false;
    }
    var count = 0;
    for (var i = _messages.length - 1;
        i >= 0 && i >= _messages.length - 5;
        i--) {
      final m = _messages[i];
      if (m.fromUserId != fromUserId) {
        continue;
      }
      if (m.id == null || m.id! <= 0) {
        continue;
      }
      if ((m.status ?? 1) != 1) {
        continue;
      }
      if ((m.msgType ?? 1) != mt) {
        continue;
      }
      if (!_mediaPathsRelate(m.content, content)) {
        continue;
      }
      count++;
    }
    return count == 1;
  }

  /// 私聊/群聊：IM 回显把 from 标成别人时，与仍 Sending 的己方乐观行合并。
  int? _tryMergeMisattributedOutgoingEcho(
    MessageDTO incoming,
    int? currentUserId,
  ) {
    if (currentUserId == null) {
      return null;
    }
    if ((incoming.msgType ?? 1) != 1) {
      return null;
    }
    final inc = (incoming.content ?? '').trim();
    if (inc.isEmpty) {
      return null;
    }
    if (incoming.fromUserId == currentUserId) {
      return null;
    }

    final int? gIn = incoming.groupId;
    if (gIn != null) {
      for (var i = _messages.length - 1; i >= 0; i--) {
        final m = _messages[i];
        if (m.id == null) {
          continue;
        }
        if (m.fromUserId != currentUserId) {
          continue;
        }
        if (m.groupId != gIn) {
          continue;
        }
        if ((m.msgType ?? 1) != 1) {
          continue;
        }
        if (!_outgoingTextMatchesForMerge(m, incoming, inc)) {
          continue;
        }
        final st = m.status;
        if (st == 1) {
          continue;
        }
        if (st != 0 && st != 2) {
          continue;
        }
        return i;
      }
      return null;
    }

    if (incoming.toUserId == null) {
      return null;
    }

    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.id == null) {
        continue;
      }
      if (m.fromUserId != currentUserId) {
        continue;
      }
      if (m.toUserId != incoming.toUserId) {
        continue;
      }
      if ((m.msgType ?? 1) != 1) {
        continue;
      }
      if (!_outgoingTextMatchesForMerge(m, incoming, inc)) {
        continue;
      }
      final st = m.status;
      if (st == 1) {
        continue;
      }
      if (st != 0 && st != 2) {
        continue;
      }
      return i;
    }
    return null;
  }

  MessageDTO _mergeImEchoKeepingLocalSender({
    required MessageDTO im,
    required MessageDTO local,
  }) {
    return MessageDTO(
      id: im.id ?? local.id,
      msgId: im.msgId ?? local.msgId,
      clientMsgNo: local.clientMsgNo ?? im.clientMsgNo,
      fromUserId: local.fromUserId,
      toUserId: local.toUserId,
      groupId: local.groupId,
      content: im.content ?? local.content,
      msgType: im.msgType ?? local.msgType,
      subType: im.subType ?? local.subType,
      extra: im.extra ?? local.extra,
      isRead: im.isRead ?? local.isRead,
      isRecalled: im.isRecalled ?? local.isRecalled,
      isDeleted: local.isDeleted,
      replyToMsgId: local.replyToMsgId,
      forwardFromMsgId: local.forwardFromMsgId,
      forwardFromUserId: local.forwardFromUserId,
      isEdited: im.isEdited ?? local.isEdited,
      status: im.status ?? local.status,
      createdAt: im.createdAt ?? local.createdAt,
      fromUserInfo: local.fromUserInfo,
    );
  }

  /// 己方文本：同会话已有一条「发送成功」且正文一致的行时，忽略本条 IM 回显（避免双行）。
  bool _hasConfirmedOwnTextDuplicateForEcho(
    MessageDTO incoming,
    int currentUserId,
  ) {
    if (incoming.fromUserId != currentUserId) {
      return false;
    }
    final inc = (incoming.content ?? '').trim();
    final incKey = incoming.clientMsgNo?.trim();
    if (inc.isEmpty && (incKey == null || incKey.isEmpty)) {
      return false;
    }
    final tIn = ChatDateFormat.parseToMillis(incoming.createdAt);
    final int? gIn = incoming.groupId;

    if (gIn != null) {
      for (var i = _messages.length - 1;
          i >= 0 && i >= _messages.length - 20;
          i--) {
        final m = _messages[i];
        if (m.fromUserId != currentUserId) {
          continue;
        }
        if (m.groupId != gIn) {
          continue;
        }
        if ((m.msgType ?? 1) != 1) {
          continue;
        }
        if (!_confirmedTextRowDuplicate(incoming, m)) {
          continue;
        }
        if (m.id == null || m.id! <= 0) {
          continue;
        }
        if ((m.status ?? 1) != 1) {
          continue;
        }
        final tM = ChatDateFormat.parseToMillis(m.createdAt);
        if (tIn != null &&
            tM != null &&
            (tIn - tM).abs() > 12000) {
          continue;
        }
        return true;
      }
      return false;
    }

    final peer = incoming.toUserId;
    if (peer == null) {
      return false;
    }
    for (var i = _messages.length - 1;
        i >= 0 && i >= _messages.length - 20;
        i--) {
      final m = _messages[i];
      if (m.fromUserId != currentUserId) {
        continue;
      }
      if (m.toUserId != peer) {
        continue;
      }
      if ((m.msgType ?? 1) != 1) {
        continue;
      }
      if (!_confirmedTextRowDuplicate(incoming, m)) {
        continue;
      }
      if (m.id == null || m.id! <= 0) {
        continue;
      }
      if ((m.status ?? 1) != 1) {
        continue;
      }
      final tM = ChatDateFormat.parseToMillis(m.createdAt);
      if (tIn != null &&
          tM != null &&
          (tIn - tM).abs() > 12000) {
        continue;
      }
      return true;
    }
    return false;
  }

  /// 已 REST/ack 确认的己方消息，在短时间内又被 IM 以「他人消息」或同内容再次插一条的重复。
  bool _isEchoDuplicateOfConfirmedOutgoing(
    MessageDTO incoming,
    int? currentUserId,
  ) {
    if (currentUserId == null) {
      return false;
    }
    // 与当前 viewer 一致的私聊会话行（含己方 outgoing）不得仅靠「同文案 echo」吞掉。
    if (_privateThreadLineMatchesViewerThread(incoming, currentUserId)) {
      return false;
    }
    if (_isAppMediaMsgType(incoming.msgType)) {
      return _isMediaEchoDuplicateOfConfirmedOutgoing(incoming, currentUserId);
    }
    if ((incoming.msgType ?? 1) != 1) {
      return false;
    }
    final inc = (incoming.content ?? '').trim();
    if (inc.isEmpty) {
      return false;
    }

    /// REST 已把乐观项原位换成正式 id 后，IM 再以「己方」推同内容第二条（id 常与服务器不一致），
    /// 必须吞掉，否则会与 [_tryMergeOptimisticOutgoing]（只合 status 0/2）形成双行。
    if (incoming.fromUserId == currentUserId) {
      return _hasConfirmedOwnTextDuplicateForEcho(incoming, currentUserId);
    }

    /// 不可对「对方发来的文本」做「与己方已确认 outgoing 同文案则丢弃」：
    /// 私聊 IM 映射里 [MessageDTO.toUserId] 常为 channel 对方 id，与 outgoing 的 toUserId 重合，
    /// 正常回复（如「好的」）会与历史己方消息撞文案，导致 Android 等依赖 IM 的路径整类丢 incoming。
    /// 误标己方的 IM 回显应优先由 [_tryMergeMisattributedOutgoingEcho] 合并。
    return false;
  }

  /// 媒体：己方已有一条 REST 落库且 status==1 的同类型同 URL（或本地路径相关）行时，
  /// 忽略 IM 再推来的回显（无论 from 是否被标成己方），避免双气泡。
  bool _isMediaEchoDuplicateOfConfirmedOutgoing(
    MessageDTO incoming,
    int currentUserId,
  ) {
    final int? from = incoming.fromUserId;
    if (from != null && from != currentUserId) {
      /// 对方发来的合法媒体勿因 URL/路径与我方历史相同而整段丢弃。
      return false;
    }
    final mt = incoming.msgType ?? 1;
    if (mt < 2 || mt > 4) {
      return false;
    }
    final inc = (incoming.content ?? '').trim();
    if (inc.isEmpty) {
      return false;
    }
    final tIn = ChatDateFormat.parseToMillis(incoming.createdAt);
    final int? gIn = incoming.groupId;

    if (gIn != null) {
      for (var i = _messages.length - 1;
          i >= 0 && i >= _messages.length - 20;
          i--) {
        final m = _messages[i];
        if (m.fromUserId != currentUserId) {
          continue;
        }
        if (m.groupId != gIn) {
          continue;
        }
        if ((m.msgType ?? 1) != mt) {
          continue;
        }
        if (!_mediaPathsRelate(m.content, incoming.content)) {
          continue;
        }
        if (m.id == null || m.id! <= 0) {
          continue;
        }
        if ((m.status ?? 1) != 1) {
          continue;
        }
        final tM = ChatDateFormat.parseToMillis(m.createdAt);
        if (tIn != null &&
            tM != null &&
            (tIn - tM).abs() > 12000) {
          continue;
        }
        return true;
      }
      return false;
    }

    final peer = incoming.toUserId;
    if (peer == null) {
      return false;
    }
    for (var i = _messages.length - 1;
        i >= 0 && i >= _messages.length - 20;
        i--) {
      final m = _messages[i];
      if (m.fromUserId != currentUserId) {
        continue;
      }
      if (m.toUserId != peer) {
        continue;
      }
      if ((m.msgType ?? 1) != mt) {
        continue;
      }
      if (!_mediaPathsRelate(m.content, incoming.content)) {
        continue;
      }
      if (m.id == null || m.id! <= 0) {
        continue;
      }
      if ((m.status ?? 1) != 1) {
        continue;
      }
      final tM = ChatDateFormat.parseToMillis(m.createdAt);
      if (tIn != null &&
          tM != null &&
          (tIn - tM).abs() > 12000) {
        continue;
      }
      return true;
    }
    return false;
  }

  String _debugImSnippet(String? content) {
    final String s = (content ?? '').trim();
    if (s.length <= 48) {
      return s;
    }
    return '${s.substring(0, 48)}…';
  }

  /// 与 [_messageBelongsToConversation] 私聊口径一致：存在 peer [targetId]，
  /// 使 (m, peer, 1, viewer) 归属成立。包含「己方→对方」与「对方→己方」及单边 to/f 为 null 的行。
  bool _privateThreadLineMatchesViewerThread(MessageDTO m, int viewer) {
    if (!_looksLikePrivatePayload(m)) {
      return false;
    }
    final int? f = m.fromUserId;
    final int? t = m.toUserId;

    final int? peer;
    if (f != null && f == viewer && t != null && t != viewer) {
      peer = t;
    } else if (t != null && t == viewer && f != null && f != viewer) {
      peer = f;
    } else if (t == null && f != null && f != viewer) {
      peer = f;
    } else if (f == null && t != null && t != viewer) {
      peer = t;
    } else {
      return false;
    }

    return _messageBelongsToConversation(m, peer, 1, currentUserId: viewer);
  }

  int? _findMessageIndexByClientMsgNo(String? clientMsgNo) {
    final String? k = clientMsgNo?.trim();
    if (k == null || k.isEmpty) {
      return null;
    }
    final int i = _messages.indexWhere((MessageDTO m) => m.clientMsgNo?.trim() == k);
    return i == -1 ? null : i;
  }

  /// IM 与 REST 均非空且相等时视为同一条。
  bool _clientMsgNoBothNonEmptyMatch(MessageDTO a, MessageDTO b) {
    final x = a.clientMsgNo?.trim();
    final y = b.clientMsgNo?.trim();
    if (x == null || x.isEmpty || y == null || y.isEmpty) {
      return false;
    }
    return x == y;
  }

  /// 无稳定 clientMsgNo 时的兜底：同会话、同发送方、同类型、同正文、时间接近。
  bool _softDuplicateForImRest(MessageDTO a, MessageDTO b) {
    if (!_sameConversationForMerge(a, b)) {
      return false;
    }
    if (a.fromUserId == null || b.fromUserId == null) {
      return false;
    }
    if (a.fromUserId != b.fromUserId) {
      return false;
    }
    if ((a.msgType ?? 1) != (b.msgType ?? 1)) {
      return false;
    }
    final String? ca = a.clientMsgNo?.trim();
    final String? cb = b.clientMsgNo?.trim();
    if (ca != null &&
        ca.isNotEmpty &&
        cb != null &&
        cb.isNotEmpty &&
        ca != cb) {
      return false;
    }
    final ac = (a.content ?? '').trim();
    final bc = (b.content ?? '').trim();
    if (ac.isEmpty || ac != bc) {
      return false;
    }
    final int windowMs = 180000;
    final ta = ChatDateFormat.parseToMillis(a.createdAt);
    final tb = ChatDateFormat.parseToMillis(b.createdAt);
    if (ta != null && tb != null) {
      if ((ta - tb).abs() > windowMs) {
        return false;
      }
    }
    return true;
  }

  /// 仅与「非负 id」行做软匹配，避免吞掉发送中乐观行（负 id）误合并。
  int? _findMessageIndexByImRestSoftDuplicate(MessageDTO message) {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.id != null && m.id! < 0) {
        continue;
      }
      if (_softDuplicateForImRest(m, message)) {
        return i;
      }
    }
    return null;
  }

  /// 合并优先级：clientMsgNo → 同 id → 软重复（同文+时间窗）。
  int? _findImRestMergeIndex(MessageDTO message, int? currentUserId) {
    final byNo = _findMessageIndexByClientMsgNo(message.clientMsgNo);
    if (byNo != null) {
      return byNo;
    }
    if (message.id != null) {
      final byId = _findMessageIndexById(message.id);
      if (byId != null) {
        return byId;
      }
    }
    return _findMessageIndexByImRestSoftDuplicate(message);
  }

  /// 合并 IM 行与 REST 行：优先带业务 [clientMsgNo] 的 id；正文/已读等取更完整的一侧。
  MessageDTO _mergeImRestPair(MessageDTO existing, MessageDTO incoming) {
    int? mergedId;
    for (final x in <MessageDTO>[existing, incoming]) {
      final id = x.id;
      if (id != null &&
          id > 0 &&
          (x.clientMsgNo != null && x.clientMsgNo!.trim().isNotEmpty)) {
        mergedId = id;
        break;
      }
    }
    mergedId ??= existing.id ?? incoming.id;
    if (mergedId != null && mergedId <= 0) {
      mergedId = incoming.id ?? existing.id;
    }

    final mergedCm = (existing.clientMsgNo?.trim().isNotEmpty ?? false)
        ? existing.clientMsgNo
        : incoming.clientMsgNo;
    final bool mergedRead =
        (existing.isRead == true) || (incoming.isRead == true);
    final fromInfo = existing.fromUserInfo ?? incoming.fromUserInfo;
    return MessageDTO(
      id: mergedId,
      msgId: existing.msgId ?? incoming.msgId,
      clientMsgNo: mergedCm,
      fromUserId: existing.fromUserId ?? incoming.fromUserId,
      toUserId: existing.toUserId ?? incoming.toUserId,
      groupId: existing.groupId ?? incoming.groupId,
      content: existing.content ?? incoming.content,
      msgType: existing.msgType ?? incoming.msgType,
      subType: existing.subType ?? incoming.subType,
      extra: existing.extra ?? incoming.extra,
      isRead: mergedRead,
      isRecalled: existing.isRecalled ?? incoming.isRecalled,
      isDeleted: existing.isDeleted ?? incoming.isDeleted,
      replyToMsgId: existing.replyToMsgId ?? incoming.replyToMsgId,
      forwardFromMsgId: existing.forwardFromMsgId ?? incoming.forwardFromMsgId,
      forwardFromUserId:
          existing.forwardFromUserId ?? incoming.forwardFromUserId,
      isEdited: existing.isEdited ?? incoming.isEdited,
      status: existing.status ?? incoming.status,
      createdAt: existing.createdAt ?? incoming.createdAt,
      fromUserInfo: fromInfo,
    );
  }

  bool _preservedDupOfServerPage1(
    List<MessageDTO> serverNorm,
    MessageDTO preserved,
    int? viewerUserId,
  ) {
    for (final s in serverNorm) {
      if (_clientMsgNoBothNonEmptyMatch(s, preserved)) {
        return true;
      }
      if (_softDuplicateForImRest(s, preserved)) {
        return true;
      }
    }
    return false;
  }

  MessageDTO? _insertMessage(MessageDTO message, {int? currentUserId}) {
    if (kDebugMode) {
      debugPrint(
        '[im.insert] _insertMessage enter id=${message.id} clientMsgNo=${message.clientMsgNo} '
        'from=${message.fromUserId} to=${message.toUserId} g=${message.groupId} '
        'self=$currentUserId content=${_debugImSnippet(message.content)}',
      );
    }

    final int? self = currentUserId;
    final int? from = message.fromUserId;
    // 仅「明确来自对方」的私聊行提前合并：己方 outgoing 不得进此分支（与日志语义一致）。
    final bool skipEchoForPeerPrivateIncoming = self != null &&
        from != null &&
        from != self &&
        _privateThreadLineMatchesViewerThread(message, self);

    if (skipEchoForPeerPrivateIncoming) {
      if (kDebugMode) {
        debugPrint(
          '[im.insert] branch=confirmed_peer_private_incoming skip echo swallow',
        );
      }
      final int? unifyPeer = _findImRestMergeIndex(message, currentUserId);
      if (unifyPeer != null) {
        if (kDebugMode) {
          debugPrint('[im.insert] im_rest_merge idx=$unifyPeer (peer incoming)');
        }
        _messages[unifyPeer] =
            _mergeImRestPair(_messages[unifyPeer], message);
        return _messages[unifyPeer];
      }
      if (kDebugMode) {
        debugPrint('[im.insert] final append');
      }
      _messages = [..._messages, message];
      return message;
    }

    final int? mergeIndex = _tryMergeOptimisticOutgoing(message, currentUserId);
    if (mergeIndex != null) {
      if (kDebugMode) {
        debugPrint('[im.insert] hit _tryMergeOptimisticOutgoing idx=$mergeIndex');
      }
      _messages[mergeIndex] = message;
      return message;
    }

    final int? misIdx = _tryMergeMisattributedOutgoingEcho(message, currentUserId);
    if (misIdx != null) {
      if (kDebugMode) {
        debugPrint(
          '[im.insert] hit _tryMergeMisattributedOutgoingEcho idx=$misIdx',
        );
      }
      _messages[misIdx] = _mergeImEchoKeepingLocalSender(
        im: message,
        local: _messages[misIdx],
      );
      return _messages[misIdx];
    }

    if (_isEchoDuplicateOfConfirmedOutgoing(message, currentUserId)) {
      if (kDebugMode) {
        debugPrint('[im.insert] hit _isEchoDuplicateOfConfirmedOutgoing (swallowed)');
      }
      return null;
    }

    final int? unifyIdx = _findImRestMergeIndex(message, currentUserId);
    if (unifyIdx != null) {
      if (kDebugMode) {
        debugPrint('[im.insert] im_rest_merge idx=$unifyIdx');
      }
      _messages[unifyIdx] = _mergeImRestPair(_messages[unifyIdx], message);
      return _messages[unifyIdx];
    }

    if (kDebugMode) {
      debugPrint('[im.insert] final append');
    }
    _messages = [..._messages, message];
    return message;
  }

  List<MessageDTO?> _mergeMessages(
    List<MessageDTO> messages, {
    int? currentUserId,
  }) {
    final originalOrder = <MessageDTO, int>{};
    for (var i = 0; i < _messages.length; i++) {
      originalOrder[_messages[i]] = i;
    }

    final previews = <MessageDTO?>[];
    for (final message in messages) {
      previews.add(_insertMessage(message, currentUserId: currentUserId));
    }

    final mergedOrder = <MessageDTO, int>{};
    for (var i = 0; i < _messages.length; i++) {
      mergedOrder[_messages[i]] = i;
    }

    _messages = List<MessageDTO>.from(_messages)
      ..sort((a, b) {
        final c = _compareMessagesForSort(a, b);
        if (c != 0) {
          return c;
        }

        final aIndex = originalOrder[a] ?? mergedOrder[a] ?? 0;
        final bIndex = originalOrder[b] ?? mergedOrder[b] ?? 0;
        return aIndex.compareTo(bIndex);
      });
    return previews;
  }

  bool _updateMessageById(
    int messageId,
    MessageDTO Function(MessageDTO current) updater,
  ) {
    final index = _findMessageIndexById(messageId);
    if (index == null) {
      return false;
    }

    _messages[index] = updater(_messages[index]);
    return true;
  }

  int? _findMessageIndexById(int? messageId) {
    if (messageId == null) {
      return null;
    }

    final index = _messages.indexWhere((message) => message.id == messageId);
    return index == -1 ? null : index;
  }

  void _sortConversationsInternal() {
    _sortConversations();
  }

  int? _findConversationIndex(int targetId, int type) {
    final index = _conversations.indexWhere(
      (conversation) =>
          conversation.targetId == targetId && (conversation.type ?? 1) == type,
    );
    return index == -1 ? null : index;
  }

  void _updateConversationPreviewFromMessage(
    MessageDTO message, {
    int? currentUserId,
    required bool increaseUnread,
  }) {
    final type = _resolveConversationType(message);
    final targetId = _resolveConversationTargetId(
      message,
      currentUserId: currentUserId,
    );
    if (targetId == null) {
      return;
    }

    final index = _findConversationIndex(targetId, type);
    final previewText = _messagePreviewText(message);

    final bool active = _isActiveConversation(targetId, type);
    final bool countThisUnread = increaseUnread && !active;

    if (index == null) {
      _conversations = [
        ..._conversations,
        ConversationDTO(
          targetId: targetId,
          type: type,
          name: _resolveConversationName(
            message,
            currentUserId: currentUserId,
          ),
          avatar: _resolveConversationAvatar(
            message,
            currentUserId: currentUserId,
          ),
          lastMessage: previewText,
          lastMessageTime: message.createdAt,
          unreadCount: countThisUnread ? 1 : 0,
          draft: null,
        ),
      ];
      return;
    }

    final current = _conversations[index];
    var nextUnread = current.unreadCount ?? 0;
    if (countThisUnread) {
      nextUnread += 1;
    }
    if (active &&
        _shouldIncreaseUnread(message, currentUserId: currentUserId)) {
      nextUnread = 0;
    }

    _conversations[index] = ConversationDTO(
      id: current.id,
      userId: current.userId,
      targetId: current.targetId,
      type: current.type,
      name: (current.name?.trim().isNotEmpty == true)
          ? current.name
          : (_resolveConversationName(
              message,
              currentUserId: currentUserId,
            ) ??
              current.name),
      avatar: current.avatar ??
          _resolveConversationAvatar(
            message,
            currentUserId: currentUserId,
          ),
      lastMessage: previewText.isNotEmpty ? previewText : current.lastMessage,
      lastMessageTime: (message.createdAt?.isNotEmpty == true)
          ? message.createdAt
          : current.lastMessageTime,
      unreadCount: nextUnread,
      isTop: current.isTop,
      isMute: current.isMute,
      draft: current.draft,
      isDeleted: current.isDeleted,
    );
  }

  void _setConversationUnread(int targetId, int type, int unreadCount) {
    final index = _findConversationIndex(targetId, type);
    if (index == null) {
      return;
    }

    final current = _conversations[index];
    _conversations[index] = ConversationDTO(
      id: current.id,
      userId: current.userId,
      targetId: current.targetId,
      type: current.type,
      name: current.name,
      avatar: current.avatar,
      lastMessage: current.lastMessage,
      lastMessageTime: current.lastMessageTime,
      unreadCount: unreadCount < 0 ? 0 : unreadCount,
      isTop: current.isTop,
      isMute: current.isMute,
      draft: current.draft,
      isDeleted: current.isDeleted,
    );
  }

  int _resolveConversationType(MessageDTO message) {
    final int? g = message.groupId;
    return (g != null && g != 0) ? 2 : 1;
  }

  int? _resolveConversationTargetId(
    MessageDTO message, {
    int? currentUserId,
  }) {
    final int? g = message.groupId;
    if (g != null && g != 0) {
      return g;
    }

    if (currentUserId != null) {
      if (message.fromUserId == currentUserId) {
        return message.toUserId;
      }
      if (message.toUserId == currentUserId) {
        return message.fromUserId;
      }
    }

    if (message.toUserId == null) {
      return message.fromUserId;
    }
    if (message.fromUserId == null) {
      return message.toUserId;
    }
    return message.toUserId;
  }

  String? _resolveConversationName(
    MessageDTO message, {
    int? currentUserId,
  }) {
    if (_resolveConversationType(message) != 1) {
      return null;
    }

    final isPeerInfo =
        currentUserId != null && message.fromUserId != currentUserId;
    if (isPeerInfo) {
      final UserDTO? peer = message.fromUserInfo;
      if (peer == null) {
        return null;
      }
      return ProfileDisplayTexts.displayName(peer);
    }
    return null;
  }

  String? _resolveConversationAvatar(
    MessageDTO message, {
    int? currentUserId,
  }) {
    if (_resolveConversationType(message) != 1) {
      return null;
    }

    final isPeerInfo =
        currentUserId != null && message.fromUserId != currentUserId;
    if (isPeerInfo) {
      return message.fromUserInfo?.avatar;
    }
    return null;
  }

  bool _shouldIncreaseUnread(
    MessageDTO message, {
    int? currentUserId,
  }) {
    if (currentUserId == null) {
      return false;
    }
    final int ctype = _resolveConversationType(message);
    if (ctype == 1) {
      return message.fromUserId != null &&
          message.fromUserId != currentUserId &&
          message.toUserId == currentUserId;
    }
    if (ctype == 2) {
      final int? g = message.groupId;
      if (g == null || g == 0) {
        return false;
      }
      return message.fromUserId != null &&
          message.fromUserId != currentUserId;
    }
    return false;
  }

  /// [currentUserId] 为会话所属用户（通常为当前登录用户）时，私聊采用双方参与判定，避免仅按单边 peer 误判。
  bool _messageBelongsToConversation(
    MessageDTO message,
    int targetId,
    int type, {
    int? currentUserId,
  }) {
    if (type == 2) {
      return message.groupId == targetId;
    }

    if (!_looksLikePrivatePayload(message)) {
      return false;
    }

    if (currentUserId != null) {
      final int? f = message.fromUserId;
      final int? t = message.toUserId;
      if (f == currentUserId && t == targetId) {
        return true;
      }
      if (f == targetId && t == currentUserId) {
        return true;
      }
      if (t == null && f == targetId) {
        return true;
      }
      if (f == null && t == targetId) {
        return true;
      }
      return false;
    }

    return message.toUserId == targetId || message.fromUserId == targetId;
  }

  bool _looksLikePrivatePayload(MessageDTO message) {
    final int? g = message.groupId;
    return g == null || g == 0;
  }

  void _debugLogRetainPrivate({
    required int type,
    required int targetId,
    required int? currentUserId,
    required int before,
    required int after,
  }) {
    if (!kDebugMode || type != 1) {
      return;
    }
    debugPrint(
      '[im.chat] retain peer=$targetId viewer=$currentUserId msgs $before->$after',
    );
  }

  void _debugLogPrivateHistoryMerged({
    required int peerId,
    required int? viewerUserId,
    required List<MessageDTO> serverSample,
  }) {
    if (!kDebugMode) {
      return;
    }
    int incomingish = 0;
    int outgoingish = 0;
    for (final m in serverSample) {
      final f = m.fromUserId;
      if (viewerUserId != null && f != null && f != viewerUserId) {
        incomingish++;
      } else if (viewerUserId != null && f == viewerUserId) {
        outgoingish++;
      }
    }
    debugPrint(
      '[im.chat] page1 merged peer=$peerId viewer=$viewerUserId '
      'server=${serverSample.length} (srv~in:$incomingish out:$outgoingish)',
    );
    var n = 0;
    for (final m in serverSample) {
      if (n >= 4) {
        break;
      }
      final mine =
          viewerUserId != null && m.fromUserId != null && m.fromUserId == viewerUserId;
      debugPrint(
        '[im.chat]  srv#$n id=${m.id} from=${m.fromUserId} to=${m.toUserId} g=${m.groupId} mine=$mine',
      );
      n++;
    }
  }

  String _messagePreviewText(MessageDTO message) {
    if (message.isRecalled == true) {
      return '此消息已撤回';
    }

    String mediaLine(String label) {
      if (message.status == 2) {
        return '[发送失败] $label';
      }
      if (message.status == 0) {
        return '[发送中] $label';
      }
      return label;
    }

    switch (message.msgType ?? 1) {
      case 2:
        return mediaLine('[图片]');
      case 3:
        return mediaLine('[音频]');
      case 4:
        return mediaLine('[视频]');
      default:
        final text = (message.content ?? '').trim();
        if (text.isEmpty) {
          return '[消息]';
        }
        var line = text;
        if (message.isEdited == true) {
          line = '已编辑 · $line';
        }
        if (message.status == 2) {
          return '[发送失败] $line';
        }
        if (message.status == 0) {
          return '[发送中] $line';
        }
        return line;
    }
  }

  void _sortConversations() {
    int timeMillis(ConversationDTO c) {
      return ChatDateFormat.parseToMillis(c.lastMessageTime) ?? 0;
    }

    _conversations.sort((a, b) {
      final aTop = a.isTop == true ? 1 : 0;
      final bTop = b.isTop == true ? 1 : 0;
      final topCompare = bTop.compareTo(aTop);
      if (topCompare != 0) {
        return topCompare;
      }

      final timeCompare = timeMillis(b).compareTo(timeMillis(a));
      if (timeCompare != 0) {
        return timeCompare;
      }

      final typeCompare = (b.type ?? 0).compareTo(a.type ?? 0);
      if (typeCompare != 0) {
        return typeCompare;
      }
      return (b.targetId ?? 0).compareTo(a.targetId ?? 0);
    });
  }

  Future<bool> sendImageMessage(
    int targetId,
    String filePath, {
    bool isGroup = false,
  }) async {
    return _sendUploadedMessage(
      upload: () => _api.uploadImage(filePath),
      send: (fileUrl) => _api.sendImageMessage(
        targetId,
        fileUrl,
        isGroup: isGroup,
      ),
      uploadError: 'Failed to upload image.',
      sendError: 'Failed to send image.',
    );
  }

  Future<bool> sendVideoMessage(
    int targetId,
    String filePath, {
    bool isGroup = false,
  }) async {
    return _sendUploadedMessage(
      upload: () => _api.uploadVideo(filePath),
      send: (fileUrl) => _api.sendVideoMessage(
        targetId,
        fileUrl,
        '',
        0,
        isGroup: isGroup,
      ),
      uploadError: 'Failed to upload video.',
      sendError: 'Failed to send video.',
    );
  }

  Future<bool> sendAudioMessage(
    int targetId,
    String filePath,
    int duration, {
    bool isGroup = false,
  }) async {
    return _sendUploadedMessage(
      upload: () => _api.uploadAudio(filePath),
      send: (fileUrl) => _api.sendAudioMessage(
        targetId,
        fileUrl,
        duration,
        isGroup: isGroup,
      ),
      uploadError: 'Failed to upload audio.',
      sendError: 'Failed to send audio.',
    );
  }

  Future<void> _runListTask<T>({
    required Future<dynamic> Function() task,
    required void Function(List<T> data) onSuccess,
    required String fallbackError,
  }) async {
    _startLoading();
    try {
      final response = await task();
      if (response.isSuccess && response.data != null) {
        final listData = response.data as List;
        final typedData = listData.map((item) => item as T).toList();
        onSuccess(typedData);
      } else {
        _error = response.message;
      }
    } catch (_) {
      _error = fallbackError;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> _sendMessageTask({
    required Future<dynamic> Function() task,
    required String fallbackError,
  }) async {
    _startLoading();
    try {
      final response = await task();
      if (response.isSuccess && response.data != null) {
        _messages = [..._messages, response.data as MessageDTO];
        await loadConversations();
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = fallbackError;
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> _sendUploadedMessage({
    required Future<dynamic> Function() upload,
    required Future<dynamic> Function(String fileUrl) send,
    required String uploadError,
    required String sendError,
  }) async {
    _startLoading();
    try {
      final uploadResponse = await upload();
      final fileUrl = uploadResponse.data?.fileUrl;
      if (!uploadResponse.isSuccess || fileUrl == null || fileUrl.isEmpty) {
        _error = uploadResponse.message.isNotEmpty
            ? uploadResponse.message
            : uploadError;
        return false;
      }

      final sendResponse = await send(fileUrl);
      if (sendResponse.isSuccess && sendResponse.data != null) {
        _messages = [..._messages, sendResponse.data as MessageDTO];
        await loadConversations();
        return true;
      }

      _error = sendResponse.message;
      return false;
    } catch (_) {
      _error = sendError;
      return false;
    } finally {
      _finishLoading();
    }
  }

  void _startLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _finishLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
