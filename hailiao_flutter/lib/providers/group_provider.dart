import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';

abstract class GroupApi {
  Future<ResponseDTO<List<GroupDTO>>> getMyGroups();
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests();
  Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds,
  });
  Future<ResponseDTO<GroupDTO>> updateGroup(int groupId, Map<String, dynamic> data);
  Future<ResponseDTO<String>> setGroupMute(int groupId, bool isMute);
  Future<ResponseDTO<String>> setGroupMemberMute(int groupId, int memberId, bool isMute);
  Future<ResponseDTO<String>> setGroupAdmin(int groupId, int memberId);
  Future<ResponseDTO<String>> removeGroupAdmin(int groupId, int memberId);
  Future<ResponseDTO<String>> transferGroupOwnership(int groupId, int memberId);
  Future<ResponseDTO<String>> deleteGroup(int groupId);
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId);
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(int groupId);
  Future<ResponseDTO<String>> requestToJoinGroup(int groupId, {String? message});
  Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId);
  Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId);
  Future<ResponseDTO<String>> withdrawGroupJoinRequest(int requestId);
  Future<ResponseDTO<String>> addGroupMember(int groupId, int userId);
  Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId);
}

class ApiGroupApi implements GroupApi {
  @override
  Future<ResponseDTO<List<GroupDTO>>> getMyGroups() => ApiService.getMyGroups();

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests() =>
      ApiService.getMyGroupJoinRequests();

  @override
  Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const [],
  }) => ApiService.createGroup(groupName, description, memberIds: memberIds);

  @override
  Future<ResponseDTO<GroupDTO>> updateGroup(int groupId, Map<String, dynamic> data) =>
      ApiService.updateGroup(groupId, data);

  @override
  Future<ResponseDTO<String>> setGroupMute(int groupId, bool isMute) =>
      ApiService.setGroupMute(groupId, isMute);

  @override
  Future<ResponseDTO<String>> setGroupMemberMute(int groupId, int memberId, bool isMute) =>
      ApiService.setGroupMemberMute(groupId, memberId, isMute);

  @override
  Future<ResponseDTO<String>> setGroupAdmin(int groupId, int memberId) =>
      ApiService.setGroupAdmin(groupId, memberId);

  @override
  Future<ResponseDTO<String>> removeGroupAdmin(int groupId, int memberId) =>
      ApiService.removeGroupAdmin(groupId, memberId);

  @override
  Future<ResponseDTO<String>> transferGroupOwnership(int groupId, int memberId) =>
      ApiService.transferGroupOwnership(groupId, memberId);

  @override
  Future<ResponseDTO<String>> deleteGroup(int groupId) => ApiService.deleteGroup(groupId);

  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) =>
      ApiService.getGroupMembers(groupId);

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(int groupId) =>
      ApiService.getGroupJoinRequests(groupId);

  @override
  Future<ResponseDTO<String>> requestToJoinGroup(int groupId, {String? message}) =>
      ApiService.requestToJoinGroup(groupId, message: message);

  @override
  Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId) =>
      ApiService.approveGroupJoinRequest(requestId);

  @override
  Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId) =>
      ApiService.rejectGroupJoinRequest(requestId);

  @override
  Future<ResponseDTO<String>> withdrawGroupJoinRequest(int requestId) =>
      ApiService.withdrawGroupJoinRequest(requestId);

  @override
  Future<ResponseDTO<String>> addGroupMember(int groupId, int userId) =>
      ApiService.addGroupMember(groupId, userId);

  @override
  Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId) =>
      ApiService.removeGroupMember(groupId, userId);
}

class GroupProvider extends ChangeNotifier {
  GroupProvider({GroupApi? api}) : _api = api ?? ApiGroupApi();

  final GroupApi _api;
  List<GroupDTO> _groups = [];
  List<GroupMemberDTO> _groupMembers = [];
  List<GroupJoinRequestDTO> _joinRequests = [];
  List<GroupJoinRequestDTO> _myJoinRequests = [];
  bool _isLoading = false;
  String? _error;

  List<GroupDTO> get groups => _groups;
  List<GroupMemberDTO> get groupMembers => _groupMembers;
  List<GroupJoinRequestDTO> get joinRequests => _joinRequests;
  List<GroupJoinRequestDTO> get myJoinRequests => _myJoinRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGroups() async {
    _startLoading();
    try {
      final response = await _api.getMyGroups();
      if (response.isSuccess && response.data != null) {
        _groups = response.data!;
      } else {
        _error = response.message;
      }
    } catch (_) {
      _error = '加载群组列表失败，请稍后重试。';
    } finally {
      _finishLoading();
    }
  }

  Future<void> loadMyJoinRequests() async {
    _startLoading();
    try {
      final response = await _api.getMyGroupJoinRequests();
      if (response.isSuccess && response.data != null) {
        _myJoinRequests = response.data!;
      } else {
        _error = response.message;
      }
    } catch (_) {
      _error = '加载我的入群申请失败。';
    } finally {
      _finishLoading();
    }
  }

  Future<bool> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const [],
  }) async {
    _startLoading();
    try {
      final response = await _api.createGroup(
        groupName,
        description,
        memberIds: memberIds,
      );
      if (response.isSuccess && response.data != null) {
        _groups = [..._groups, response.data!];
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '创建群组失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> updateGroup(int groupId, Map<String, dynamic> data) async {
    _startLoading();
    try {
      final response = await _api.updateGroup(groupId, data);
      if (response.isSuccess && response.data != null) {
        final index = _groups.indexWhere((group) => group.id == groupId);
        if (index != -1) {
          _groups[index] = response.data!;
        }
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '更新群资料失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> setGroupMute(int groupId, bool isMute) async {
    _startLoading();
    try {
      final response = await _api.setGroupMute(groupId, isMute);
      if (!response.isSuccess) {
        _error = response.message;
        return false;
      }

      final index = _groups.indexWhere((group) => group.id == groupId);
      if (index != -1) {
        final current = _groups[index];
        _groups[index] = GroupDTO(
          id: current.id,
          groupId: current.groupId,
          groupName: current.groupName,
          description: current.description,
          notice: current.notice,
          avatar: current.avatar,
          ownerId: current.ownerId,
          groupType: current.groupType,
          memberCount: current.memberCount,
          maxMembers: current.maxMembers,
          needVerify: current.needVerify,
          allowMemberInvite: current.allowMemberInvite,
          joinType: current.joinType,
          isMute: isMute,
          status: current.status,
          createdAt: current.createdAt,
          updatedAt: current.updatedAt,
        );
      }
      return true;
    } catch (_) {
      _error = '更新群静音设置失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> setMemberMute(int groupId, int memberId, bool isMute) async {
    _startLoading();
    try {
      final response = await _api.setGroupMemberMute(groupId, memberId, isMute);
      if (!response.isSuccess) {
        _error = response.message;
        return false;
      }

      final index = _groupMembers.indexWhere((member) => member.userId == memberId);
      if (index != -1) {
        final current = _groupMembers[index];
        _groupMembers[index] = GroupMemberDTO(
          id: current.id,
          groupId: current.groupId,
          userId: current.userId,
          nickname: current.nickname,
          role: current.role,
          isMute: isMute,
          joinedAt: current.joinedAt,
          userInfo: current.userInfo,
        );
      }
      return true;
    } catch (_) {
      _error = '更新成员静音设置失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> setMemberAdmin(int groupId, int memberId, bool isAdmin) async {
    _startLoading();
    try {
      final response = isAdmin
          ? await _api.setGroupAdmin(groupId, memberId)
          : await _api.removeGroupAdmin(groupId, memberId);
      if (!response.isSuccess) {
        _error = response.message;
        return false;
      }

      final index = _groupMembers.indexWhere((member) => member.userId == memberId);
      if (index != -1) {
        final current = _groupMembers[index];
        _groupMembers[index] = GroupMemberDTO(
          id: current.id,
          groupId: current.groupId,
          userId: current.userId,
          nickname: current.nickname,
          role: isAdmin ? 2 : 3,
          isMute: current.isMute,
          joinedAt: current.joinedAt,
          userInfo: current.userInfo,
        );
      }
      return true;
    } catch (_) {
      _error = isAdmin
          ? '设置管理员失败。'
          : '取消管理员失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> transferOwnership(int groupId, int memberId) async {
    _startLoading();
    try {
      final response = await _api.transferGroupOwnership(groupId, memberId);
      if (!response.isSuccess) {
        _error = response.message;
        return false;
      }
      return true;
    } catch (_) {
      _error = '转让群主失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> quitGroup(int groupId) async {
    _startLoading();
    try {
      final response = await _api.deleteGroup(groupId);
      if (response.isSuccess) {
        _groups = _groups.where((group) => group.id != groupId).toList();
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '退出群组失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<void> loadGroupMembers(int groupId) async {
    _startLoading();
    try {
      final response = await _api.getGroupMembers(groupId);
      if (response.isSuccess && response.data != null) {
        _groupMembers = response.data!;
      } else {
        _error = response.message;
      }
    } catch (_) {
      _error = '加载群成员失败。';
    } finally {
      _finishLoading();
    }
  }

  Future<void> loadJoinRequests(int groupId) async {
    _startLoading();
    try {
      final response = await _api.getGroupJoinRequests(groupId);
      if (response.isSuccess && response.data != null) {
        _joinRequests = response.data!;
      } else {
        _error = response.message;
      }
    } catch (_) {
      _error = '加载入群申请失败。';
    } finally {
      _finishLoading();
    }
  }

  Future<bool> requestToJoinGroup(int groupId, {String? message}) async {
    _startLoading();
    try {
      final response = await _api.requestToJoinGroup(
        groupId,
        message: message,
      );
      if (response.isSuccess) {
        await loadMyJoinRequests();
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '提交入群申请失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> reviewJoinRequest(int requestId, {required bool approve}) async {
    _startLoading();
    try {
      final response = approve
          ? await _api.approveGroupJoinRequest(requestId)
          : await _api.rejectGroupJoinRequest(requestId);
      if (response.isSuccess) {
        _joinRequests = _joinRequests
            .where((request) => request.id != requestId)
            .toList();
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = approve
          ? '同意入群申请失败。'
          : '拒绝入群申请失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> withdrawJoinRequest(int requestId) async {
    _startLoading();
    try {
      final response = await _api.withdrawGroupJoinRequest(requestId);
      if (response.isSuccess) {
        final index = _myJoinRequests.indexWhere((request) => request.id == requestId);
        if (index != -1) {
          final current = _myJoinRequests[index];
          _myJoinRequests[index] = GroupJoinRequestDTO(
            id: current.id,
            groupId: current.groupId,
            userId: current.userId,
            message: current.message,
            status: 3,
            handledBy: current.handledBy,
            handledAt: current.handledAt,
            createdAt: current.createdAt,
            userInfo: current.userInfo,
            groupInfo: current.groupInfo,
          );
        }
        notifyListeners();
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '撤回入群申请失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> addGroupMember(int groupId, int userId) async {
    _startLoading();
    try {
      final response = await _api.addGroupMember(groupId, userId);
      if (response.isSuccess) {
        await loadGroupMembers(groupId);
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '添加群成员失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> removeGroupMember(int groupId, int userId) async {
    _startLoading();
    try {
      final response = await _api.removeGroupMember(groupId, userId);
      if (response.isSuccess) {
        _groupMembers = _groupMembers
            .where((member) => member.userId != userId)
            .toList();
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '移除群成员失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  GroupDTO? findGroupById(int groupId) {
    for (final group in _groups) {
      if (group.id == groupId) {
        return group;
      }
    }
    return null;
  }

  void clearJoinRequests() {
    _joinRequests = [];
    notifyListeners();
  }

  void clearMyJoinRequests() {
    _myJoinRequests = [];
    notifyListeners();
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
