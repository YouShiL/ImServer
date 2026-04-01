import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/file_upload_result_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';

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

  String _draftKey(int? targetId, int? type) => '${type ?? 0}-${targetId ?? 0}';

  String? getDraft(int? targetId, int? type) {
    return _drafts[_draftKey(targetId, type)];
  }

  void setDraft(int? targetId, int? type, String value) {
    final key = _draftKey(targetId, type);
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _drafts.remove(key);
    } else {
      _drafts[key] = value;
    }
    _sortConversations();
    notifyListeners();
  }

  void clearDraft(int? targetId, int? type) {
    _drafts.remove(_draftKey(targetId, type));
    _sortConversations();
    notifyListeners();
  }

  Future<void> loadConversations() async {
    await _runListTask<ConversationDTO>(
      task: _api.getConversations,
      onSuccess: (data) {
        _conversations = data;
        _sortConversations();
      },
      fallbackError: '加载会话列表失败，请稍后重试。',
    );
  }

  Future<void> loadPrivateMessages(int toUserId, int page, int size) async {
    await _runListTask<MessageDTO>(
      task: () => _api.getPrivateMessages(toUserId, page, size),
      onSuccess: (data) {
        if (page == 1) {
          _messages = data;
        } else {
          _messages = [..._messages, ...data];
        }
      },
      fallbackError: '加载消息失败，请稍后重试。',
    );
  }

  Future<void> loadGroupMessages(int groupId, int page, int size) async {
    await _runListTask<MessageDTO>(
      task: () => _api.getGroupMessages(groupId, page, size),
      onSuccess: (data) {
        if (page == 1) {
          _messages = data;
        } else {
          _messages = [..._messages, ...data];
        }
      },
      fallbackError: '加载消息失败，请稍后重试。',
    );
  }

  Future<bool> sendPrivateMessage(
    int toUserId,
    String content,
    int msgType,
  ) async {
    return _sendMessageTask(
      task: () => _api.sendPrivateMessage(toUserId, content, msgType),
      fallbackError: '发送消息失败，请稍后重试。',
    );
  }

  Future<bool> sendGroupMessage(
    int groupId,
    String content,
    int msgType,
  ) async {
    return _sendMessageTask(
      task: () => _api.sendGroupMessage(groupId, content, msgType),
      fallbackError: '发送消息失败，请稍后重试。',
    );
  }

  Future<bool> recallMessage(int messageId) async {
    _startLoading();
    try {
      final response = await _api.recallMessage(messageId);
      if (!response.isSuccess) {
        _error = response.message;
        return false;
      }

      final index = _messages.indexWhere((message) => message.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRecalled: true);
      }
      await loadConversations();
      return true;
    } catch (_) {
      _error = '撤回消息失败，请稍后重试。';
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
  }) async {
    return _sendMessageTask(
      task: () => _api.replyMessage(
        replyToMsgId: replyToMsgId,
        toUserId: toUserId,
        groupId: groupId,
        content: content,
        msgType: msgType,
      ),
      fallbackError: '发送回复失败。',
    );
  }

  Future<bool> editMessage(int messageId, String newContent) async {
    _startLoading();
    try {
      final response = await _api.editMessage(messageId, newContent);
      if (!response.isSuccess || response.data == null) {
        _error = response.message;
        return false;
      }

      final index = _messages.indexWhere((message) => message.id == messageId);
      if (index != -1) {
        _messages[index] = response.data as MessageDTO;
      }
      await loadConversations();
      return true;
    } catch (_) {
      _error = '编辑消息失败。';
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
      _error = '转发消息失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> markAsRead(int fromUserId) async {
    try {
      final response = await _api.markAsRead(fromUserId);
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
      _error = '更新会话设置失败。';
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
      _error = '删除会话失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
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
      uploadError: '上传图片失败。',
      sendError: '发送图片失败。',
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
      uploadError: '上传视频失败。',
      sendError: '发送视频失败。',
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
      uploadError: '上传音频失败。',
      sendError: '发送音频失败。',
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
