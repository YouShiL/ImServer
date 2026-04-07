import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';

/// 聊天页测试专用：避免真实网络，满足 [ChatScreen] 进入群聊时的 `loadGroups` / `loadGroupMembers`。
///
/// 可选 [presetMyGroups] / [presetMembers] 用于断言顶栏与禁言等规则。
class NoopChatGroupApi implements GroupApi {
  NoopChatGroupApi({
    List<GroupDTO>? presetMyGroups,
    List<GroupMemberDTO>? presetMembers,
  })  : _presetMyGroups = presetMyGroups,
        _presetMembers = presetMembers;

  final List<GroupDTO>? _presetMyGroups;
  final List<GroupMemberDTO>? _presetMembers;

  @override
  Future<ResponseDTO<List<GroupDTO>>> getMyGroups() async {
    return ResponseDTO<List<GroupDTO>>(
      code: 200,
      message: 'ok',
      data: _presetMyGroups != null
          ? List<GroupDTO>.from(_presetMyGroups!)
          : <GroupDTO>[],
    );
  }

  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) async {
    return ResponseDTO<List<GroupMemberDTO>>(
      code: 200,
      message: 'ok',
      data: _presetMembers != null
          ? List<GroupMemberDTO>.from(_presetMembers!)
          : <GroupMemberDTO>[],
    );
  }

  @override
  Future<ResponseDTO<String>> addGroupMember(int groupId, int userId) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const <int>[],
  }) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> deleteGroup(int groupId) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(
    int groupId,
  ) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests() async {
    return ResponseDTO<List<GroupJoinRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupJoinRequestDTO>[],
    );
  }

  @override
  Future<ResponseDTO<String>> removeGroupAdmin(int groupId, int memberId) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> requestToJoinGroup(
    int groupId, {
    String? message,
  }) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> setGroupMemberMute(
    int groupId,
    int memberId,
    bool isMute,
  ) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> setGroupMute(int groupId, bool isMute) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> setGroupAdmin(int groupId, int memberId) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> transferGroupOwnership(
    int groupId,
    int memberId,
  ) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<GroupDTO>> updateGroup(
    int groupId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<ResponseDTO<String>> withdrawGroupJoinRequest(int requestId) =>
      throw UnimplementedError();
}
