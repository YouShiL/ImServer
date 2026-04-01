import 'package:hailiao_flutter/models/blacklist_dto.dart';
import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/file_upload_result_dto.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/content_audit_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/providers/report_provider.dart';

class FakeBlacklistApi implements BlacklistApi {
  FakeBlacklistApi({
    this.getBlacklistHandler,
    this.addToBlacklistHandler,
    this.removeFromBlacklistHandler,
  });

  Future<ResponseDTO<List<BlacklistDTO>>> Function()? getBlacklistHandler;
  Future<ResponseDTO<BlacklistDTO>> Function(int blockedUserId)?
      addToBlacklistHandler;
  Future<ResponseDTO<String>> Function(int blockedUserId)?
      removeFromBlacklistHandler;

  @override
  Future<ResponseDTO<List<BlacklistDTO>>> getBlacklist() {
    return getBlacklistHandler!.call();
  }

  @override
  Future<ResponseDTO<BlacklistDTO>> addToBlacklist(int blockedUserId) {
    return addToBlacklistHandler!.call(blockedUserId);
  }

  @override
  Future<ResponseDTO<String>> removeFromBlacklist(int blockedUserId) {
    return removeFromBlacklistHandler!.call(blockedUserId);
  }
}

class FakeFriendApi implements FriendApi {
  FakeFriendApi({
    this.getFriendsHandler,
    this.getReceivedHandler,
    this.getSentHandler,
    this.addFriendHandler,
    this.acceptRequestHandler,
    this.rejectRequestHandler,
    this.deleteFriendHandler,
    this.updateRemarkHandler,
  });

  Future<ResponseDTO<List<FriendDTO>>> Function()? getFriendsHandler;
  Future<ResponseDTO<List<FriendRequestDTO>>> Function()? getReceivedHandler;
  Future<ResponseDTO<List<FriendRequestDTO>>> Function()? getSentHandler;
  Future<ResponseDTO<String>> Function(
    int friendId,
    String remark, {
    String? message,
  })? addFriendHandler;
  Future<ResponseDTO<String>> Function(int requestId)? acceptRequestHandler;
  Future<ResponseDTO<String>> Function(int requestId)? rejectRequestHandler;
  Future<ResponseDTO<String>> Function(int friendId)? deleteFriendHandler;
  Future<ResponseDTO<FriendDTO>> Function(int friendId, String remark)?
      updateRemarkHandler;

  @override
  Future<ResponseDTO<List<FriendDTO>>> getFriends() {
    return getFriendsHandler!.call();
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getReceivedFriendRequests() {
    return getReceivedHandler!.call();
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getSentFriendRequests() {
    return getSentHandler!.call();
  }

  @override
  Future<ResponseDTO<String>> addFriend(
    int friendId,
    String remark, {
    String? message,
  }) {
    return addFriendHandler!.call(friendId, remark, message: message);
  }

  @override
  Future<ResponseDTO<String>> acceptFriendRequest(int requestId) {
    return acceptRequestHandler!.call(requestId);
  }

  @override
  Future<ResponseDTO<String>> rejectFriendRequest(int requestId) {
    return rejectRequestHandler!.call(requestId);
  }

  @override
  Future<ResponseDTO<String>> deleteFriend(int friendId) {
    return deleteFriendHandler!.call(friendId);
  }

  @override
  Future<ResponseDTO<FriendDTO>> updateFriendRemark(int friendId, String remark) {
    return updateRemarkHandler!.call(friendId, remark);
  }
}

class FakeGroupApi implements GroupApi {
  Future<ResponseDTO<List<GroupDTO>>> Function()? getMyGroupsHandler;
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> Function()?
      getMyJoinRequestsHandler;
  Future<ResponseDTO<GroupDTO>> Function(
    String groupName,
    String description, {
    List<int> memberIds,
  })? createGroupHandler;
  Future<ResponseDTO<GroupDTO>> Function(int groupId, Map<String, dynamic> data)?
      updateGroupHandler;
  Future<ResponseDTO<String>> Function(int groupId, bool isMute)?
      setGroupMuteHandler;
  Future<ResponseDTO<String>> Function(int groupId, int memberId, bool isMute)?
      setGroupMemberMuteHandler;
  Future<ResponseDTO<String>> Function(int groupId, int memberId)?
      setGroupAdminHandler;
  Future<ResponseDTO<String>> Function(int groupId, int memberId)?
      removeGroupAdminHandler;
  Future<ResponseDTO<String>> Function(int groupId, int memberId)?
      transferOwnershipHandler;
  Future<ResponseDTO<String>> Function(int groupId)? deleteGroupHandler;
  Future<ResponseDTO<List<GroupMemberDTO>>> Function(int groupId)?
      getGroupMembersHandler;
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> Function(int groupId)?
      getGroupJoinRequestsHandler;
  Future<ResponseDTO<String>> Function(int groupId, {String? message})?
      requestToJoinGroupHandler;
  Future<ResponseDTO<String>> Function(int requestId)? approveJoinRequestHandler;
  Future<ResponseDTO<String>> Function(int requestId)? rejectJoinRequestHandler;
  Future<ResponseDTO<String>> Function(int requestId)? withdrawJoinRequestHandler;
  Future<ResponseDTO<String>> Function(int groupId, int userId)?
      addGroupMemberHandler;
  Future<ResponseDTO<String>> Function(int groupId, int userId)?
      removeGroupMemberHandler;

  @override
  Future<ResponseDTO<List<GroupDTO>>> getMyGroups() => getMyGroupsHandler!.call();

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests() =>
      getMyJoinRequestsHandler!.call();

  @override
  Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const [],
  }) => createGroupHandler!.call(groupName, description, memberIds: memberIds);

  @override
  Future<ResponseDTO<GroupDTO>> updateGroup(int groupId, Map<String, dynamic> data) =>
      updateGroupHandler!.call(groupId, data);

  @override
  Future<ResponseDTO<String>> setGroupMute(int groupId, bool isMute) =>
      setGroupMuteHandler!.call(groupId, isMute);

  @override
  Future<ResponseDTO<String>> setGroupMemberMute(int groupId, int memberId, bool isMute) =>
      setGroupMemberMuteHandler!.call(groupId, memberId, isMute);

  @override
  Future<ResponseDTO<String>> setGroupAdmin(int groupId, int memberId) =>
      setGroupAdminHandler!.call(groupId, memberId);

  @override
  Future<ResponseDTO<String>> removeGroupAdmin(int groupId, int memberId) =>
      removeGroupAdminHandler!.call(groupId, memberId);

  @override
  Future<ResponseDTO<String>> transferGroupOwnership(int groupId, int memberId) =>
      transferOwnershipHandler!.call(groupId, memberId);

  @override
  Future<ResponseDTO<String>> deleteGroup(int groupId) => deleteGroupHandler!.call(groupId);

  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) =>
      getGroupMembersHandler!.call(groupId);

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(int groupId) =>
      getGroupJoinRequestsHandler!.call(groupId);

  @override
  Future<ResponseDTO<String>> requestToJoinGroup(int groupId, {String? message}) =>
      requestToJoinGroupHandler!.call(groupId, message: message);

  @override
  Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId) =>
      approveJoinRequestHandler!.call(requestId);

  @override
  Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId) =>
      rejectJoinRequestHandler!.call(requestId);

  @override
  Future<ResponseDTO<String>> withdrawGroupJoinRequest(int requestId) =>
      withdrawJoinRequestHandler!.call(requestId);

  @override
  Future<ResponseDTO<String>> addGroupMember(int groupId, int userId) =>
      addGroupMemberHandler!.call(groupId, userId);

  @override
  Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId) =>
      removeGroupMemberHandler!.call(groupId, userId);
}

class FakeReportApi implements ReportApi {
  Future<ResponseDTO<ReportDTO>> Function(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  })? createReportHandler;
  Future<ResponseDTO<List<ReportDTO>>> Function()? getMyReportsHandler;

  @override
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) {
    return createReportHandler!(
      targetId,
      targetType,
      reason,
      evidence: evidence,
    );
  }

  @override
  Future<ResponseDTO<List<ReportDTO>>> getMyReports() {
    return getMyReportsHandler!.call();
  }
}

class FakeContentAuditApi implements ContentAuditApi {
  Future<ResponseDTO<List<ContentAuditDTO>>> Function()?
      getMyContentAuditsHandler;

  @override
  Future<ResponseDTO<List<ContentAuditDTO>>> getMyContentAudits() {
    return getMyContentAuditsHandler!.call();
  }
}

class FakeMessageApi implements MessageApi {
  Future<ResponseDTO<List<ConversationDTO>>> Function()? getConversationsHandler;
  Future<ResponseDTO<List<MessageDTO>>> Function(int toUserId, int page, int size)?
      getPrivateMessagesHandler;
  Future<ResponseDTO<List<MessageDTO>>> Function(int groupId, int page, int size)?
      getGroupMessagesHandler;
  Future<ResponseDTO<MessageDTO>> Function(int toUserId, String content, int msgType)?
      sendPrivateMessageHandler;
  Future<ResponseDTO<MessageDTO>> Function(int groupId, String content, int msgType)?
      sendGroupMessageHandler;
  Future<ResponseDTO<String>> Function(int messageId)? recallMessageHandler;
  Future<ResponseDTO<MessageDTO>> Function({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType,
  })? replyMessageHandler;
  Future<ResponseDTO<MessageDTO>> Function(int messageId, String newContent)?
      editMessageHandler;
  Future<ResponseDTO<MessageDTO>> Function({
    required int originalMsgId,
    int? toUserId,
    int? groupId,
  })? forwardMessageHandler;
  Future<ResponseDTO<String>> Function(int fromUserId)? markAsReadHandler;
  Future<ResponseDTO<ConversationDTO>> Function(
    int conversationId,
    Map<String, dynamic> data,
  )? updateConversationHandler;
  Future<ResponseDTO<String>> Function(int conversationId, {required int type})?
      deleteConversationHandler;
  Future<ResponseDTO<FileUploadResultDTO>> Function(String filePath)?
      uploadImageHandler;
  Future<ResponseDTO<FileUploadResultDTO>> Function(String filePath)?
      uploadVideoHandler;
  Future<ResponseDTO<FileUploadResultDTO>> Function(String filePath)?
      uploadAudioHandler;
  Future<ResponseDTO<MessageDTO>> Function(
    int targetId,
    String imageUrl, {
    bool isGroup,
  })? sendImageMessageHandler;
  Future<ResponseDTO<MessageDTO>> Function(
    int targetId,
    String videoUrl,
    String coverUrl,
    int duration, {
    bool isGroup,
  })? sendVideoMessageHandler;
  Future<ResponseDTO<MessageDTO>> Function(
    int targetId,
    String audioUrl,
    int duration, {
    bool isGroup,
  })? sendAudioMessageHandler;

  @override
  Future<ResponseDTO<List<ConversationDTO>>> getConversations() {
    return getConversationsHandler!.call();
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> getPrivateMessages(
    int toUserId,
    int page,
    int size,
  ) {
    return getPrivateMessagesHandler!.call(toUserId, page, size);
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> getGroupMessages(
    int groupId,
    int page,
    int size,
  ) {
    return getGroupMessagesHandler!.call(groupId, page, size);
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendPrivateMessage(
    int toUserId,
    String content,
    int msgType,
  ) {
    return sendPrivateMessageHandler!.call(toUserId, content, msgType);
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendGroupMessage(
    int groupId,
    String content,
    int msgType,
  ) {
    return sendGroupMessageHandler!.call(groupId, content, msgType);
  }

  @override
  Future<ResponseDTO<String>> recallMessage(int messageId) {
    return recallMessageHandler!.call(messageId);
  }

  @override
  Future<ResponseDTO<MessageDTO>> replyMessage({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType = 1,
  }) {
    return replyMessageHandler!.call(
      replyToMsgId: replyToMsgId,
      toUserId: toUserId,
      groupId: groupId,
      content: content,
      msgType: msgType,
    );
  }

  @override
  Future<ResponseDTO<MessageDTO>> editMessage(int messageId, String newContent) {
    return editMessageHandler!.call(messageId, newContent);
  }

  @override
  Future<ResponseDTO<MessageDTO>> forwardMessage({
    required int originalMsgId,
    int? toUserId,
    int? groupId,
  }) {
    return forwardMessageHandler!.call(
      originalMsgId: originalMsgId,
      toUserId: toUserId,
      groupId: groupId,
    );
  }

  @override
  Future<ResponseDTO<String>> markAsRead(int fromUserId) {
    return markAsReadHandler!.call(fromUserId);
  }

  @override
  Future<ResponseDTO<ConversationDTO>> updateConversation(
    int conversationId,
    Map<String, dynamic> data,
  ) {
    return updateConversationHandler!.call(conversationId, data);
  }

  @override
  Future<ResponseDTO<String>> deleteConversation(
    int conversationId, {
    required int type,
  }) {
    return deleteConversationHandler!.call(conversationId, type: type);
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadImage(String filePath) {
    return uploadImageHandler!.call(filePath);
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadVideo(String filePath) {
    return uploadVideoHandler!.call(filePath);
  }

  @override
  Future<ResponseDTO<FileUploadResultDTO>> uploadAudio(String filePath) {
    return uploadAudioHandler!.call(filePath);
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendImageMessage(
    int targetId,
    String imageUrl, {
    bool isGroup = false,
  }) {
    return sendImageMessageHandler!.call(targetId, imageUrl, isGroup: isGroup);
  }

  @override
  Future<ResponseDTO<MessageDTO>> sendVideoMessage(
    int targetId,
    String videoUrl,
    String coverUrl,
    int duration, {
    bool isGroup = false,
  }) {
    return sendVideoMessageHandler!.call(
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
    return sendAudioMessageHandler!.call(
      targetId,
      audioUrl,
      duration,
      isGroup: isGroup,
    );
  }
}

ConversationDTO buildConversation({
  required int targetId,
  required int type,
  String? name,
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
    lastMessageTime: lastMessageTime,
    unreadCount: unreadCount,
    isTop: isTop,
    isMute: isMute,
    draft: draft,
  );
}
