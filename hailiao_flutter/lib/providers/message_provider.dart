import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/file_upload_result_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/theme/chat_date_format.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';

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
    int msgType,
  );
  Future<ResponseDTO<MessageDTO>> sendGroupMessage(
    int groupId,
    String content,
    int msgType,
  );
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
    int msgType,
  ) {
    return ApiService.sendPrivateMessage(toUserId, content, msgType);
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendGroupMessage(
    int groupId,
    String content,
    int msgType,
  ) {
    return ApiService.sendGroupMessage(groupId, content, msgType);
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

  List<ConversationDTO> get conversations => _conversations;
  List<MessageDTO> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Monotonic negative ids for local optimistic rows (not persisted).
  int _optimisticLocalIdSeq = 0;

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
      final reused = MessageDTO(
        id: current.id,
        msgId: current.msgId,
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
        status: 0,
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
      msgType: 1,
      replyToMsgId: replyToMsgId,
      status: 0,
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
        status: 0,
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
      status: 0,
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
        status: 2,
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
    if (m.status != 2) {
      return null;
    }
    if (!_messageBelongsToConversation(m, targetId, type)) {
      return null;
    }
    final text = (m.content ?? '').trim();
    if (text.isEmpty) {
      return null;
    }

    _messages[idx] = MessageDTO(
      id: m.id,
      msgId: m.msgId,
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
      status: 0,
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
    if (m.status != 2) {
      return null;
    }
    if (!_messageBelongsToConversation(m, targetId, type)) {
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
      status: 0,
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
    final preview = _insertMessage(message, currentUserId: currentUserId);
    if (preview == null) {
      return;
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
      return MessageDTO(
        id: nextId,
        msgId: current.msgId,
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
        if (status == 1 &&
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

    MessageDTO? latestMessage;
    for (final message in _messages.reversed) {
      if (_messageBelongsToConversation(message, targetId, type)) {
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

  Future<void> loadPrivateMessages(int toUserId, int page, int size) async {
    await _runListTask<MessageDTO>(
      task: () => _api.getPrivateMessages(toUserId, page, size),
      onSuccess: (data) {
        if (page == 1) {
          _messages = _mergeHistoryPage1WithPreservedLocals(
            data,
            conversationTargetId: toUserId,
            conversationType: 1,
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

  void _applySentMessage(
    MessageDTO merged, {
    int? optimisticLocalId,
  }) {
    if (optimisticLocalId != null && optimisticLocalId != 0) {
      final replaced =
          _updateMessageById(optimisticLocalId, (_) => merged);
      if (!replaced) {
        _messages = [..._messages, merged];
      }
    } else {
      _messages = [..._messages, merged];
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
      final response = await _api.sendPrivateMessage(toUserId, content, msgType);
      if (response.isSuccess && response.data != null) {
        final merged = _normalizeServerMessage(response.data as MessageDTO);
        _applySentMessage(merged, optimisticLocalId: optimisticLocalId);
        await loadConversations();
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
      final response =
          await _api.sendGroupMessage(groupId, content, msgType);
      if (response.isSuccess && response.data != null) {
        final merged = _normalizeServerMessage(response.data as MessageDTO);
        _applySentMessage(merged, optimisticLocalId: optimisticLocalId);
        await loadConversations();
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
        final merged = mergeReplyResult(response.data as MessageDTO);
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

  Future<bool> markAsRead(int fromUserId) async {
    try {
      final response = await _api.markAsRead(fromUserId);
      if (response.isSuccess) {
        _setConversationUnread(fromUserId, 1, 0);
        _sortConversationsInternal();
        notifyListeners();
      }
      return response.isSuccess;
    } catch (_) {
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

  /// 进入聊天页时调用：去掉其他会话的缓存行，仅保留本会话未同步到服务端的本地行（负 [MessageDTO.id]），
  /// 避免退出再进或切换会话后发送失败/发送中的气泡消失。
  void retainEphemeralMessagesForChat(int targetId, int type) {
    _messages = _messages
        .where(
          (m) =>
              m.id != null &&
              m.id! < 0 &&
              _messageBelongsToConversation(m, targetId, type),
        )
        .toList();
    notifyListeners();
  }

  /// 与远端第 1 页历史合并仍保留在内存中的本地行（发送中、发送失败）。
  /// 接口分页多为「最新在前」，此处统一为升序：旧消息在上、最新在下。
  List<MessageDTO> _mergeHistoryPage1WithPreservedLocals(
    List<MessageDTO> serverPage, {
    required int conversationTargetId,
    required int conversationType,
  }) {
    final preserved = _messages
        .where(
          (m) =>
              m.id != null &&
              m.id! < 0 &&
              _messageBelongsToConversation(
                m,
                conversationTargetId,
                conversationType,
              ),
        )
        .toList();

    final serverNorm = serverPage.map(_normalizeServerMessage).toList();
    final combined = [...serverNorm, ...preserved];
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
    if (incomingContent.isEmpty) {
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
        if ((m.content ?? '').trim() != incomingContent) {
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
      if (m.status != 2) {
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
      if (m.status != 2) {
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
        if ((m.content ?? '').trim() != inc) {
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
      if ((m.content ?? '').trim() != inc) {
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
        if ((m.msgType ?? 1) != 1) {
          continue;
        }
        if ((m.content ?? '').trim() != inc) {
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
      if ((m.content ?? '').trim() != inc) {
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
        if ((m.content ?? '').trim() != inc) {
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
      if ((m.content ?? '').trim() != inc) {
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

  /// 媒体：己方已有一条 REST 落库且 status==1 的同类型同 URL（或本地路径相关）行时，
  /// 忽略 IM 再推来的回显（无论 from 是否被标成己方），避免双气泡。
  bool _isMediaEchoDuplicateOfConfirmedOutgoing(
    MessageDTO incoming,
    int currentUserId,
  ) {
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

  MessageDTO? _insertMessage(MessageDTO message, {int? currentUserId}) {
    final mergeIndex = _tryMergeOptimisticOutgoing(message, currentUserId);
    if (mergeIndex != null) {
      _messages[mergeIndex] = message;
      return message;
    }

    final misIdx = _tryMergeMisattributedOutgoingEcho(message, currentUserId);
    if (misIdx != null) {
      _messages[misIdx] = _mergeImEchoKeepingLocalSender(
        im: message,
        local: _messages[misIdx],
      );
      return _messages[misIdx];
    }

    if (_isEchoDuplicateOfConfirmedOutgoing(message, currentUserId)) {
      return null;
    }

    final existingIndex = _findMessageIndexById(message.id);
    if (existingIndex != null) {
      _messages[existingIndex] = message;
      return message;
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
          unreadCount: increaseUnread ? 1 : 0,
          draft: null,
        ),
      ];
      return;
    }

    final current = _conversations[index];
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
      unreadCount: current.unreadCount,
      isTop: current.isTop,
      isMute: current.isMute,
      draft: current.draft,
      isDeleted: current.isDeleted,
    );

    if (increaseUnread) {
      _incrementConversationUnread(targetId, type);
    }
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

  void _incrementConversationUnread(
    int targetId,
    int type, {
    int delta = 1,
  }) {
    final index = _findConversationIndex(targetId, type);
    if (index == null) {
      return;
    }

    final current = _conversations[index];
    _setConversationUnread(
      targetId,
      type,
      (current.unreadCount ?? 0) + delta,
    );
  }

  int _resolveConversationType(MessageDTO message) {
    return message.groupId != null ? 2 : 1;
  }

  int? _resolveConversationTargetId(
    MessageDTO message, {
    int? currentUserId,
  }) {
    if (message.groupId != null) {
      return message.groupId;
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
    if (_resolveConversationType(message) != 1) {
      return false;
    }
    if (currentUserId == null) {
      return false;
    }
    return message.fromUserId != null &&
        message.fromUserId != currentUserId &&
        message.toUserId == currentUserId;
  }

  bool _messageBelongsToConversation(MessageDTO message, int targetId, int type) {
    if (type == 2) {
      return message.groupId == targetId;
    }

    return message.groupId == null &&
        (message.toUserId == targetId || message.fromUserId == targetId);
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
    _conversations.sort((a, b) {
      final aTop = a.isTop == true ? 1 : 0;
      final bTop = b.isTop == true ? 1 : 0;
      final topCompare = bTop.compareTo(aTop);
      if (topCompare != 0) {
        return topCompare;
      }

      final aHasDraft = ((_drafts[_draftKey(a.targetId, a.type)] ?? a.draft ?? '')
              .trim()
              .isNotEmpty)
          ? 1
          : 0;
      final bHasDraft = ((_drafts[_draftKey(b.targetId, b.type)] ?? b.draft ?? '')
              .trim()
              .isNotEmpty)
          ? 1
          : 0;
      final draftCompare = bHasDraft.compareTo(aHasDraft);
      if (draftCompare != 0) {
        return draftCompare;
      }

      final aUnread = a.unreadCount ?? 0;
      final bUnread = b.unreadCount ?? 0;
      final unreadCompare = bUnread.compareTo(aUnread);
      if (unreadCompare != 0) {
        return unreadCompare;
      }

      return (b.lastMessageTime ?? '').compareTo(a.lastMessageTime ?? '');
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
