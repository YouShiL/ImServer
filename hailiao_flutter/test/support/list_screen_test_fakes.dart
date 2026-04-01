import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/content_audit_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/report_provider.dart';

typedef ReportsHandler = Future<ResponseDTO<List<ReportDTO>>> Function();
typedef AuditsHandler = Future<ResponseDTO<List<ContentAuditDTO>>> Function();
typedef GroupsHandler = Future<ResponseDTO<List<GroupDTO>>> Function();
typedef GroupRequestsHandler =
    Future<ResponseDTO<List<GroupJoinRequestDTO>>> Function();

class FakeReportListApi implements ReportApi {
  FakeReportListApi({required this.reportsHandler});

  final ReportsHandler reportsHandler;

  @override
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<ReportDTO>>> getMyReports() {
    return reportsHandler.call();
  }
}

class FakeContentAuditListApi implements ContentAuditApi {
  FakeContentAuditListApi({required this.auditsHandler});

  final AuditsHandler auditsHandler;

  @override
  Future<ResponseDTO<List<ContentAuditDTO>>> getMyContentAudits() {
    return auditsHandler.call();
  }
}

class FakeGroupListApi implements GroupApi {
  FakeGroupListApi({
    required this.groupsHandler,
    required this.joinRequestsHandler,
  }) : _joinRequests = <GroupJoinRequestDTO>[],
       _groups = <GroupDTO>[];

  final GroupsHandler groupsHandler;
  final GroupRequestsHandler joinRequestsHandler;
  final List<GroupJoinRequestDTO> _joinRequests;
  final List<GroupDTO> _groups;

  @override
  Future<ResponseDTO<List<GroupDTO>>> getMyGroups() {
    if (_groups.isEmpty) {
      return groupsHandler.call().then((ResponseDTO<List<GroupDTO>> response) {
        _groups
          ..clear()
          ..addAll(response.data ?? const <GroupDTO>[]);
        return ResponseDTO<List<GroupDTO>>(
          code: response.code,
          message: response.message,
          data: List<GroupDTO>.from(_groups),
        );
      });
    }

    return Future<ResponseDTO<List<GroupDTO>>>.value(
      ResponseDTO<List<GroupDTO>>(
        code: 200,
        message: 'ok',
        data: List<GroupDTO>.from(_groups),
      ),
    );
  }

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests() {
    if (_joinRequests.isEmpty) {
      return joinRequestsHandler.call().then((ResponseDTO<List<GroupJoinRequestDTO>> response) {
        _joinRequests
          ..clear()
          ..addAll(response.data ?? const <GroupJoinRequestDTO>[]);
        return ResponseDTO<List<GroupJoinRequestDTO>>(
          code: response.code,
          message: response.message,
          data: List<GroupJoinRequestDTO>.from(_joinRequests),
        );
      });
    }

    return Future<ResponseDTO<List<GroupJoinRequestDTO>>>.value(
      ResponseDTO<List<GroupJoinRequestDTO>>(
        code: 200,
        message: 'ok',
        data: List<GroupJoinRequestDTO>.from(_joinRequests),
      ),
    );
  }

  @override
  Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const [],
  }) {
    final int nextId = _groups.isEmpty
        ? 1
        : _groups
                  .map((GroupDTO group) => group.id ?? 0)
                  .fold<int>(0, (int maxId, int id) => id > maxId ? id : maxId) +
              1;
    final GroupDTO group = GroupDTO(
      id: nextId,
      groupId: '${90000 + nextId}',
      groupName: groupName,
      description: description,
      memberCount: 1,
    );
    _groups.add(group);
    return Future<ResponseDTO<GroupDTO>>.value(
      ResponseDTO<GroupDTO>(code: 200, message: 'ok', data: group),
    );
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
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(int groupId) {
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
    final index = _joinRequests.indexWhere((GroupJoinRequestDTO request) => request.id == requestId);
    if (index == -1) {
      return Future<ResponseDTO<String>>.value(
        ResponseDTO<String>(code: 404, message: 'not found', data: null),
      );
    }

    final GroupJoinRequestDTO current = _joinRequests[index];
    _joinRequests[index] = GroupJoinRequestDTO(
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

    return Future<ResponseDTO<String>>.value(
      ResponseDTO<String>(code: 200, message: 'ok', data: 'withdrawn'),
    );
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

ReportProvider buildReportProvider(List<ReportDTO> reports) {
  return ReportProvider(
    api: FakeReportListApi(
      reportsHandler: () async =>
          ResponseDTO<List<ReportDTO>>(code: 200, message: 'ok', data: reports),
    ),
  );
}

ContentAuditProvider buildContentAuditProvider(List<ContentAuditDTO> audits) {
  return ContentAuditProvider(
    api: FakeContentAuditListApi(
      auditsHandler: () async => ResponseDTO<List<ContentAuditDTO>>(
        code: 200,
        message: 'ok',
        data: audits,
      ),
    ),
  );
}

GroupProvider buildGroupListProvider({
  List<GroupDTO> groups = const <GroupDTO>[],
  List<GroupJoinRequestDTO> requests = const <GroupJoinRequestDTO>[],
}) {
  return GroupProvider(
    api: FakeGroupListApi(
      groupsHandler: () async =>
          ResponseDTO<List<GroupDTO>>(code: 200, message: 'ok', data: groups),
      joinRequestsHandler: () async => ResponseDTO<List<GroupJoinRequestDTO>>(
        code: 200,
        message: 'ok',
        data: requests,
      ),
    ),
  );
}

GroupJoinRequestDTO buildJoinRequest({
  int id = 1,
  int groupId = 1,
  int userId = 10,
  int status = 0,
  String? message,
  GroupDTO? groupInfo,
}) {
  return GroupJoinRequestDTO(
    id: id,
    groupId: groupId,
    userId: userId,
    message: message,
    status: status,
    groupInfo: groupInfo,
  );
}

GroupDTO buildGroup({
  int id = 1,
  String groupId = '90001',
  String groupName = 'Team Alpha',
  int? memberCount = 5,
}) {
  return GroupDTO(
    id: id,
    groupId: groupId,
    groupName: groupName,
    memberCount: memberCount,
  );
}
