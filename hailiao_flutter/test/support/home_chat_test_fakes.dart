import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/blacklist_dto.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/file_upload_result_dto.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';

import 'auth_test_fakes.dart';
import 'screen_test_helpers.dart';

class FakeHomeFriendApi implements FriendApi {
  FakeHomeFriendApi({
    List<FriendDTO>? friends,
    List<FriendRequestDTO>? receivedRequests,
    List<FriendRequestDTO>? sentRequests,
  }) : friends = List<FriendDTO>.from(friends ?? <FriendDTO>[]),
       receivedRequests = List<FriendRequestDTO>.from(
         receivedRequests ?? <FriendRequestDTO>[],
       ),
       sentRequests = List<FriendRequestDTO>.from(
         sentRequests ?? <FriendRequestDTO>[],
       );

  final List<FriendDTO> friends;
  final List<FriendRequestDTO> receivedRequests;
  final List<FriendRequestDTO> sentRequests;

  @override
  Future<ResponseDTO<String>> acceptFriendRequest(int requestId) async {
    receivedRequests.removeWhere((request) => request.id == requestId);
    return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
  }

  @override
  Future<ResponseDTO<String>> addFriend(
    int friendId,
    String remark, {
    String? message,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> deleteFriend(int friendId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<FriendDTO>>> getFriends() async {
    return ResponseDTO<List<FriendDTO>>(
      code: 200,
      message: 'ok',
      data: friends,
    );
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getReceivedFriendRequests() async {
    return ResponseDTO<List<FriendRequestDTO>>(
      code: 200,
      message: 'ok',
      data: receivedRequests,
    );
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getSentFriendRequests() async {
    return ResponseDTO<List<FriendRequestDTO>>(
      code: 200,
      message: 'ok',
      data: sentRequests,
    );
  }

  @override
  Future<ResponseDTO<String>> rejectFriendRequest(int requestId) async {
    receivedRequests.removeWhere((request) => request.id == requestId);
    return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
  }

  @override
  Future<ResponseDTO<FriendDTO>> updateFriendRemark(int friendId, String remark) {
    throw UnimplementedError();
  }
}

class FakeHomeMessageApi implements MessageApi {
  FakeHomeMessageApi({
    List<ConversationDTO>? conversations,
    List<MessageDTO>? privateMessages,
    List<MessageDTO>? groupMessages,
  }) : conversations = List<ConversationDTO>.from(
         conversations ?? <ConversationDTO>[],
       ),
       privateMessages = privateMessages ?? <MessageDTO>[],
       groupMessages = groupMessages;

  final List<ConversationDTO> conversations;
  final List<MessageDTO> privateMessages;
  final List<MessageDTO>? groupMessages;

  /// 若为空则 [replyMessage] 仍抛出 [UnimplementedError]（与历史行为一致）。
  Future<ResponseDTO<MessageDTO>> Function({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType,
  })? replyMessageHandler;

  @override
  Future<ResponseDTO<List<ConversationDTO>>> getConversations() async {
    return ResponseDTO<List<ConversationDTO>>(
      code: 200,
      message: 'ok',
      data: conversations,
    );
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> getPrivateMessages(
    int toUserId,
    int page,
    int size,
  ) async {
    return ResponseDTO<List<MessageDTO>>(
      code: 200,
      message: 'ok',
      data: privateMessages,
    );
  }

  @override
  Future<ResponseDTO<String>> markAsRead(int fromUserId) async {
    return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
  }

  @override
  Future<ResponseDTO<String>> deleteConversation(
    int conversationId, {
    required int type,
  }) {
    conversations.removeWhere(
      (conversation) => conversation.targetId == conversationId,
    );
    return Future<ResponseDTO<String>>.value(
      ResponseDTO<String>(code: 200, message: 'ok', data: 'ok'),
    );
  }

  @override
  Future<ResponseDTO<MessageDTO>> editMessage(int messageId, String newContent) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<MessageDTO>> forwardMessage({
    required int originalMsgId,
    int? toUserId,
    int? groupId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> getGroupMessages(
    int groupId,
    int page,
    int size,
  ) async {
    return ResponseDTO<List<MessageDTO>>(
      code: 200,
      message: 'ok',
      data: groupMessages ?? <MessageDTO>[],
    );
  }

  @override
  Future<ResponseDTO<String>> recallMessage(int messageId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<MessageDTO>> replyMessage({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType = 1,
  }) {
    final h = replyMessageHandler;
    if (h == null) {
      throw UnimplementedError();
    }
    return h(
      replyToMsgId: replyToMsgId,
      toUserId: toUserId,
      groupId: groupId,
      content: content,
      msgType: msgType,
    );
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendAudioMessage(
    int targetId,
    String audioUrl,
    int duration, {
    bool isGroup = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendGroupMessage(
    int groupId,
    String content,
    int msgType, {
    String? clientMsgNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendImageMessage(
    int targetId,
    String imageUrl, {
    bool isGroup = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendPrivateMessage(
    int toUserId,
    String content,
    int msgType, {
    String? clientMsgNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendVideoMessage(
    int targetId,
    String videoUrl,
    String coverUrl,
    int duration, {
    bool isGroup = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadAudio(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadImage(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadVideo(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<ConversationDTO>> updateConversation(
    int conversationId,
    Map<String, dynamic> data,
  ) {
    final index = conversations.indexWhere(
      (conversation) => conversation.targetId == conversationId,
    );
    if (index == -1) {
      return Future<ResponseDTO<ConversationDTO>>.value(
        ResponseDTO<ConversationDTO>(
          code: 404,
          message: 'not found',
          data: null,
        ),
      );
    }

    final current = conversations[index];
    final updated = ConversationDTO(
      id: current.id,
      userId: current.userId,
      targetId: current.targetId,
      type: current.type,
      name: current.name,
      avatar: current.avatar,
      lastMessage: current.lastMessage,
      lastMessageTime: current.lastMessageTime,
      unreadCount: current.unreadCount,
      isTop: data['isTop'] as bool? ?? current.isTop,
      isMute: data['isMute'] as bool? ?? current.isMute,
      draft: current.draft,
      isDeleted: current.isDeleted,
    );
    conversations[index] = updated;
    return Future<ResponseDTO<ConversationDTO>>.value(
      ResponseDTO<ConversationDTO>(
        code: 200,
        message: 'ok',
        data: updated,
      ),
    );
  }
}

class FakeChatBlacklistApi implements BlacklistApi {
  @override
  Future<ResponseDTO<BlacklistDTO>> addToBlacklist(int blockedUserId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<BlacklistDTO>>> getBlacklist() async {
    return ResponseDTO<List<BlacklistDTO>>(
      code: 200,
      message: 'ok',
      data: <BlacklistDTO>[],
    );
  }

  @override
  Future<ResponseDTO<String>> removeFromBlacklist(int blockedUserId) {
    throw UnimplementedError();
  }
}

/// 指定 [blockedUserIds]，供聊天页拉黑态与 [BlacklistProvider.isBlocked] 断言。
class FakeChatBlacklistApiWithBlocked implements BlacklistApi {
  FakeChatBlacklistApiWithBlocked(this.blockedUserIds);

  final Set<int> blockedUserIds;

  @override
  Future<ResponseDTO<BlacklistDTO>> addToBlacklist(int blockedUserId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<BlacklistDTO>>> getBlacklist() async {
    return ResponseDTO<List<BlacklistDTO>>(
      code: 200,
      message: 'ok',
      data: blockedUserIds
          .map(
            (int id) => BlacklistDTO(blockedUserId: id),
          )
          .toList(),
    );
  }

  @override
  Future<ResponseDTO<String>> removeFromBlacklist(int blockedUserId) {
    throw UnimplementedError();
  }
}

class FakeChatScreenApi implements ChatScreenApi {
  @override
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId) async {
    return ResponseDTO<Map<String, dynamic>>(
      code: 200,
      message: 'ok',
      data: <String, dynamic>{'isOnline': true},
    );
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> searchGroupMessages(
    int groupId,
    String keyword, {
    int page = 1,
    int size = 50,
  }) async {
    return ResponseDTO<List<MessageDTO>>(
      code: 200,
      message: 'ok',
      data: <MessageDTO>[],
    );
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> searchMessages(
    String keyword, {
    int page = 1,
    int size = 50,
  }) async {
    return ResponseDTO<List<MessageDTO>>(
      code: 200,
      message: 'ok',
      data: <MessageDTO>[],
    );
  }
}

Map<String, Widget Function(BuildContext)> buildHomeRoutes({
  bool includeUserDetail = false,
}) {
  final List<String> routes = <String>[
    '/security',
    '/report-list',
    '/content-audit-list',
    '/groups',
    '/login',
  ];
  if (includeUserDetail) {
    routes.add('/user-detail');
  }
  return buildTextRoutes(routes);
}

AuthProvider buildHomeAuthProvider({
  AuthApi? api,
  UserDTO? user,
}) {
  return buildSignedInAuthProvider(
    api: api,
    user: user ??
        UserDTO(
          id: 1,
          userId: 'u1',
          nickname: 'Owner',
          phone: '13800000000',
        ),
  );
}

MessageProvider buildChatMessageProvider({
  String title = 'Alice',
  String lastMessage = 'Hello there',
  String lastMessageTime = '2026-03-31T12:00:00',
  int targetId = 2,
  int type = 1,
  List<MessageDTO>? privateMessages,
  List<MessageDTO>? groupMessages,
  Future<ResponseDTO<MessageDTO>> Function({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType,
  })? replyMessageHandler,
}) {
  final List<MessageDTO> private = privateMessages ??
      (type == 1
          ? <MessageDTO>[buildPrivateMessage()]
          : <MessageDTO>[]);
  final api = FakeHomeMessageApi(
    conversations: <ConversationDTO>[
      buildConversation(
        targetId: targetId,
        type: type,
        name: title,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
      ),
    ],
    privateMessages: private,
    groupMessages: groupMessages,
  )..replyMessageHandler = replyMessageHandler;
  return MessageProvider(api: api);
}

BlacklistProvider buildChatBlacklistProviderWithBlocked(Set<int> blockedUserIds) {
  return BlacklistProvider(api: FakeChatBlacklistApiWithBlocked(blockedUserIds));
}

BlacklistProvider buildChatBlacklistProvider() {
  return BlacklistProvider(api: FakeChatBlacklistApi());
}

ConversationDTO buildConversation({
  required int targetId,
  required int type,
  String? name,
  String? avatar,
  String? lastMessage,
  String? lastMessageTime,
  int unreadCount = 0,
  bool isTop = false,
  bool isMute = false,
  String? draft,
}) {
  return ConversationDTO(
    id: targetId,
    userId: 1,
    targetId: targetId,
    type: type,
    name: name,
    avatar: avatar,
    lastMessage: lastMessage,
    lastMessageTime: lastMessageTime,
    unreadCount: unreadCount,
    isTop: isTop,
    isMute: isMute,
    draft: draft,
  );
}

MessageDTO buildPrivateMessage({
  int id = 10,
  int fromUserId = 2,
  int toUserId = 1,
  String content = 'Hello there',
  int msgType = 1,
  String createdAt = '2026-03-31 12:00:00',
  bool? isRead,
  bool? isRecalled,
  bool? isEdited,
  int? status,
  int? forwardFromMsgId,
  int? replyToMsgId,
}) {
  return MessageDTO(
    id: id,
    fromUserId: fromUserId,
    toUserId: toUserId,
    content: content,
    msgType: msgType,
    createdAt: createdAt,
    isRead: isRead,
    isRecalled: isRecalled,
    isEdited: isEdited,
    status: status,
    forwardFromMsgId: forwardFromMsgId,
    replyToMsgId: replyToMsgId,
  );
}

FriendDTO buildFriend({
  int id = 1,
  int userId = 1,
  int friendId = 2,
  String remark = 'Alice remark',
  UserDTO? friendUserInfo,
}) {
  return FriendDTO(
    id: id,
    userId: userId,
    friendId: friendId,
    remark: remark,
    friendUserInfo:
        friendUserInfo ?? UserDTO(id: friendId, userId: 'u$friendId', nickname: 'Alice'),
  );
}

FriendRequestDTO buildFriendRequest({
  int id = 1,
  int fromUserId = 3,
  int toUserId = 1,
  String message = 'Need approval',
  UserDTO? fromUserInfo,
}) {
  return FriendRequestDTO(
    id: id,
    fromUserId: fromUserId,
    toUserId: toUserId,
    message: message,
    fromUserInfo:
        fromUserInfo ?? UserDTO(id: fromUserId, userId: 'u$fromUserId', nickname: 'Bob'),
  );
}
