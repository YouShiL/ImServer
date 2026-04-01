import 'package:hailiao_flutter/models/blacklist_dto.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/screens/group_detail_screen.dart';
import 'package:hailiao_flutter/screens/user_detail_screen.dart';

class FakeGroupDetailApi implements GroupDetailApi {
  @override
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) async {
    return ResponseDTO<ReportDTO>(code: 200, message: 'ok', data: null);
  }

  @override
  Future<ResponseDTO<GroupDTO>> getGroupById(int groupId) async {
    return ResponseDTO<GroupDTO>(
      code: 200,
      message: 'ok',
      data: GroupDTO(
        id: groupId,
        groupId: '90001',
        groupName: 'Team Alpha',
        ownerId: 1,
        memberCount: 2,
      ),
    );
  }

  @override
  Future<ResponseDTO<UserDTO>> searchUser(
    String keyword, {
    String type = 'userId',
  }) {
    throw UnimplementedError();
  }
}

class FakeGroupDetailGroupApi implements GroupApi {
  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) async {
    return ResponseDTO<List<GroupMemberDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupMemberDTO>[
        GroupMemberDTO(
          id: 1,
          groupId: groupId,
          userId: 1,
          role: 1,
          userInfo: UserDTO(id: 1, userId: 'u1', nickname: 'Owner'),
        ),
        GroupMemberDTO(
          id: 2,
          groupId: groupId,
          userId: 2,
          role: 3,
          userInfo: UserDTO(id: 2, userId: 'u2', nickname: 'Member'),
        ),
      ],
    );
  }

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(
    int groupId,
  ) async {
    return ResponseDTO<List<GroupJoinRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupJoinRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<List<GroupDTO>>> getMyGroups() {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests() {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const <int>[],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<GroupDTO>> updateGroup(
    int groupId,
    Map<String, dynamic> data,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupMute(int groupId, bool isMute) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupMemberMute(
    int groupId,
    int memberId,
    bool isMute,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupAdmin(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> removeGroupAdmin(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> transferGroupOwnership(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> deleteGroup(int groupId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> requestToJoinGroup(
    int groupId, {
    String? message,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> withdrawGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> addGroupMember(int groupId, int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId) {
    throw UnimplementedError();
  }
}

class FakeGroupFlowApi implements GroupApi {
  @override
  Future<ResponseDTO<List<GroupDTO>>> getMyGroups() async {
    return ResponseDTO<List<GroupDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupDTO>[
        GroupDTO(
          id: 1,
          groupId: '90001',
          groupName: 'Team Alpha',
          ownerId: 1,
          memberCount: 2,
          description: 'Core team',
        ),
      ],
    );
  }

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests() async {
    return ResponseDTO<List<GroupJoinRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupJoinRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) async {
    return ResponseDTO<List<GroupMemberDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupMemberDTO>[
        GroupMemberDTO(
          id: 1,
          groupId: groupId,
          userId: 1,
          role: 1,
          userInfo: UserDTO(id: 1, userId: 'u1', nickname: 'Owner'),
        ),
        GroupMemberDTO(
          id: 2,
          groupId: groupId,
          userId: 2,
          role: 3,
          userInfo: UserDTO(id: 2, userId: 'u2', nickname: 'Member'),
        ),
      ],
    );
  }

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(
    int groupId,
  ) async {
    return ResponseDTO<List<GroupJoinRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupJoinRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const <int>[],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<GroupDTO>> updateGroup(
    int groupId,
    Map<String, dynamic> data,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupMute(int groupId, bool isMute) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupMemberMute(
    int groupId,
    int memberId,
    bool isMute,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupAdmin(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> removeGroupAdmin(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> transferGroupOwnership(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> deleteGroup(int groupId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> requestToJoinGroup(
    int groupId, {
    String? message,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> withdrawGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> addGroupMember(int groupId, int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId) {
    throw UnimplementedError();
  }
}

class FakeNonMemberGroupDetailGroupApi implements GroupApi {
  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) async {
    return ResponseDTO<List<GroupMemberDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupMemberDTO>[
        GroupMemberDTO(
          id: 1,
          groupId: groupId,
          userId: 9,
          role: 1,
          userInfo: UserDTO(id: 9, userId: 'u9', nickname: 'Owner'),
        ),
      ],
    );
  }

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(
    int groupId,
  ) async {
    return ResponseDTO<List<GroupJoinRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupJoinRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<List<GroupDTO>>> getMyGroups() {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests() {
    return Future<ResponseDTO<List<GroupJoinRequestDTO>>>.value(
      ResponseDTO<List<GroupJoinRequestDTO>>(
        code: 200,
        message: 'ok',
        data: <GroupJoinRequestDTO>[],
      ),
    );
  }

  @override
  Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const <int>[],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<GroupDTO>> updateGroup(
    int groupId,
    Map<String, dynamic> data,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupMute(int groupId, bool isMute) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupMemberMute(
    int groupId,
    int memberId,
    bool isMute,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> setGroupAdmin(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> removeGroupAdmin(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> transferGroupOwnership(int groupId, int memberId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> deleteGroup(int groupId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> requestToJoinGroup(
    int groupId, {
    String? message,
  }) async {
    return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
  }

  @override
  Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> withdrawGroupJoinRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> addGroupMember(int groupId, int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId) {
    throw UnimplementedError();
  }
}

class FakeUserDetailApi implements UserDetailApi {
  @override
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) async {
    return ResponseDTO<ReportDTO>(code: 200, message: 'ok', data: null);
  }

  @override
  Future<ResponseDTO<UserDTO>> getUserById(int userId) async {
    return ResponseDTO<UserDTO>(
      code: 200,
      message: 'ok',
      data: UserDTO(
        id: userId,
        userId: 'u$userId',
        nickname: 'Alice',
        signature: 'hello',
        region: 'HK',
        phone: '13800000000',
        showOnlineStatus: true,
        showLastOnline: true,
      ),
    );
  }

  @override
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(
    int userId,
  ) async {
    return ResponseDTO<Map<String, dynamic>>(
      code: 200,
      message: 'ok',
      data: <String, dynamic>{'isOnline': true},
    );
  }
}

class FakeUserDetailFriendApi implements FriendApi {
  @override
  Future<ResponseDTO<String>> acceptFriendRequest(int requestId) {
    throw UnimplementedError();
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
      data: <FriendDTO>[
        FriendDTO(
          id: 1,
          userId: 1,
          friendId: 2,
          remark: 'Work friend',
          friendUserInfo: UserDTO(id: 2, userId: 'u2', nickname: 'Alice'),
        ),
      ],
    );
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getReceivedFriendRequests() async {
    return ResponseDTO<List<FriendRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <FriendRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getSentFriendRequests() async {
    return ResponseDTO<List<FriendRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <FriendRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<String>> rejectFriendRequest(int requestId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<FriendDTO>> updateFriendRemark(
    int friendId,
    String remark,
  ) {
    throw UnimplementedError();
  }
}

class FakeUserDetailBlacklistApi implements BlacklistApi {
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

class FakeBlockedUserDetailBlacklistApi implements BlacklistApi {
  @override
  Future<ResponseDTO<BlacklistDTO>> addToBlacklist(int blockedUserId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<BlacklistDTO>>> getBlacklist() async {
    return ResponseDTO<List<BlacklistDTO>>(
      code: 200,
      message: 'ok',
      data: <BlacklistDTO>[
        BlacklistDTO(
          id: 1,
          userId: 1,
          blockedUserId: 2,
          blockedUserInfo: UserDTO(id: 2, userId: 'u2', nickname: 'Alice'),
        ),
      ],
    );
  }

  @override
  Future<ResponseDTO<String>> removeFromBlacklist(int blockedUserId) {
    return Future<ResponseDTO<String>>.value(
      ResponseDTO<String>(code: 200, message: 'ok', data: 'ok'),
    );
  }
}
