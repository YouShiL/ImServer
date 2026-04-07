import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hailiao_flutter/config/app_config.dart';
import 'package:hailiao_flutter/models/auth_response_dto.dart';
import 'package:hailiao_flutter/models/blacklist_dto.dart';
import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/file_upload_result_dto.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/login_request_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/register_request_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';

class ApiService {
  /// 由 [AppConfig.apiBaseUrl] 提供（`APP_ENV` / `API_BASE_URL`），勿在此硬编码。
  static String get baseUrl => AppConfig.apiBaseUrl;

  static String? _token;
  static Future<void> Function()? _unauthorizedHandler;

  static void setToken(String token) {
    _token = token.isEmpty ? null : token;
  }

  static String? getToken() {
    return _token;
  }

  static void setUnauthorizedHandler(Future<void> Function()? handler) {
    _unauthorizedHandler = handler;
  }

  static Future<void> _handleUnauthorizedResponse(String endpoint) async {
    final isAuthEndpoint = endpoint.startsWith('/auth/login') ||
        endpoint.startsWith('/auth/register') ||
        endpoint.startsWith('/auth/logout');
    if (_token != null && !isAuthEndpoint && _unauthorizedHandler != null) {
      await _unauthorizedHandler!();
    }
  }

  static Future<http.Response> _request(String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    final requestHeaders = {...defaultHeaders, ...?headers};

    http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(
          url,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(
          url,
          headers: requestHeaders,
        );
        break;
      default:
        response = await http.get(
          url,
          headers: requestHeaders,
        );
    }

    if (response.statusCode == 401) {
      await _handleUnauthorizedResponse(endpoint);
    }

    return response;
  }

  // 认证相关API
  static Future<ResponseDTO<AuthResponseDTO>> login(LoginRequestDTO request) async {
    final response = await _request('/auth/login', method: 'POST', body: request.toJson());
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => AuthResponseDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<AuthResponseDTO>> register(RegisterRequestDTO request) async {
    final response = await _request('/auth/register', method: 'POST', body: request.toJson());
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => AuthResponseDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<String>> logout() async {
    final response = await _request('/auth/logout', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<List<UserSessionDTO>>> getUserSessions() async {
    final response = await _request('/auth/sessions');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List)
          .map((item) => UserSessionDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<ResponseDTO<String>> revokeUserSession(String sessionId) async {
    final response = await _request('/auth/session/$sessionId', method: 'DELETE');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> terminateOtherSessions() async {
    final response = await _request('/auth/session/terminate-others', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  // 用户相关API
  static Future<ResponseDTO<UserDTO>> getUserInfo() async {
    final response = await _request('/user/profile');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => UserDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<UserDTO>> updateUserInfo(Map<String, dynamic> data) async {
    final response = await _request('/user/profile', method: 'PUT', body: data);
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => UserDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<UserDTO>> searchUser(String keyword, {String type = 'userId'}) async {
    final response = await _request('/user/search', method: 'POST', body: {
      'keyword': keyword,
      'type': type,
    });
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => UserDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<UserDTO>> getUserById(int userId) async {
    final response = await _request('/user/$userId');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => UserDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId) async {
    final response = await _request('/online/status/$userId');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  // 消息相关API
  static Future<ResponseDTO<MessageDTO>> sendPrivateMessage(int toUserId, String content, int msgType) async {
    final response = await _request('/message/send/private', method: 'POST', body: {
      'toUserId': toUserId,
      'content': content,
      'msgType': msgType,
    });
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => MessageDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<MessageDTO>> sendGroupMessage(int groupId, String content, int msgType) async {
    final response = await _request('/message/send/group', method: 'POST', body: {
      'groupId': groupId,
      'content': content,
      'msgType': msgType,
    });
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => MessageDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<MessageDTO>> replyMessage({
    required int replyToMsgId,
    int? toUserId,
    int? groupId,
    required String content,
    int msgType = 1,
    String? extra,
  }) async {
    final query = <String>[
      'replyToMsgId=$replyToMsgId',
      if (toUserId != null) 'toUserId=$toUserId',
      if (groupId != null) 'groupId=$groupId',
      'content=${Uri.encodeQueryComponent(content)}',
      'msgType=$msgType',
      if (extra != null) 'extra=${Uri.encodeQueryComponent(extra)}',
    ].join('&');
    final response = await _request('/message/ext/reply?$query', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => MessageDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<MessageDTO>> editMessage(int messageId, String newContent) async {
    final response = await _request(
      '/message/ext/$messageId/edit?newContent=${Uri.encodeQueryComponent(newContent)}',
      method: 'PUT',
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => MessageDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<MessageDTO>> forwardMessage({
    required int originalMsgId,
    int? toUserId,
    int? groupId,
  }) async {
    final query = <String>[
      'originalMsgId=$originalMsgId',
      if (toUserId != null) 'toUserId=$toUserId',
      if (groupId != null) 'groupId=$groupId',
    ].join('&');
    final response = await _request('/message/ext/forward?$query', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => MessageDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<String>> recallMessage(int messageId) async {
    final response = await _request('/message/$messageId/recall', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<List<MessageDTO>>> getPrivateMessages(int toUserId, int page, int size) async {
    final backendPage = page > 0 ? page - 1 : 0;
    final response = await _request('/message/private/$toUserId?page=$backendPage&size=$size');
    final json = jsonDecode(response.body);
    final normalizedJson = Map<String, dynamic>.from(json);
    normalizedJson['data'] = (json['data']?['content'] ?? []) as List<dynamic>;
    return ResponseDTO.fromJson(
      normalizedJson,
      (data) => (data as List).map((item) => MessageDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<List<MessageDTO>>> getGroupMessages(int groupId, int page, int size) async {
    final backendPage = page > 0 ? page - 1 : 0;
    final response = await _request('/message/group/$groupId?page=$backendPage&size=$size');
    final json = jsonDecode(response.body);
    final normalizedJson = Map<String, dynamic>.from(json);
    normalizedJson['data'] = (json['data']?['content'] ?? []) as List<dynamic>;
    return ResponseDTO.fromJson(
      normalizedJson,
      (data) => (data as List).map((item) => MessageDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<List<MessageDTO>>> searchMessages(
    String keyword, {
    int page = 1,
    int size = 20,
  }) async {
    final backendPage = page > 0 ? page - 1 : 0;
    final response = await _request(
      '/message/ext/search?keyword=${Uri.encodeQueryComponent(keyword)}&page=$backendPage&size=$size',
    );
    final json = jsonDecode(response.body);
    final normalizedJson = Map<String, dynamic>.from(json);
    normalizedJson['data'] = (json['data']?['content'] ?? []) as List<dynamic>;
    return ResponseDTO.fromJson(
      normalizedJson,
      (data) => (data as List).map((item) => MessageDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<List<MessageDTO>>> searchGroupMessages(
    int groupId,
    String keyword, {
    int page = 1,
    int size = 20,
  }) async {
    final backendPage = page > 0 ? page - 1 : 0;
    final response = await _request(
      '/message/ext/group/$groupId/search?keyword=${Uri.encodeQueryComponent(keyword)}&page=$backendPage&size=$size',
    );
    final json = jsonDecode(response.body);
    final normalizedJson = Map<String, dynamic>.from(json);
    normalizedJson['data'] = (json['data']?['content'] ?? []) as List<dynamic>;
    return ResponseDTO.fromJson(
      normalizedJson,
      (data) => (data as List).map((item) => MessageDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<List<MessageDTO>>> getUnreadMessages(int fromUserId) async {
    final response = await _request('/message/unread/$fromUserId');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List).map((item) => MessageDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<String>> markAsRead(int fromUserId) async {
    final response = await _request('/message/read/$fromUserId', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<int>> getUnreadCount(int fromUserId) async {
    final response = await _request('/message/unread-count/$fromUserId');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as int,
    );
  }

  // 会话相关API
  static Future<ResponseDTO<List<ConversationDTO>>> getConversations() async {
    final response = await _request('/conversation/list');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List).map((item) => ConversationDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<ConversationDTO>> updateConversation(int conversationId, Map<String, dynamic> data) async {
    final type = data['type'];
    if (type == null) {
      throw ArgumentError('type is required when updating a conversation');
    }

    if (data.containsKey('isTop')) {
      final response = await _request('/conversation/$conversationId/top', method: 'POST', body: {
        'type': type,
        'isTop': data['isTop'],
      });
      final json = jsonDecode(response.body);
      final normalizedJson = Map<String, dynamic>.from(json);
      normalizedJson['data'] = {
        'id': conversationId,
        'type': type,
        'isTop': data['isTop'],
      };
      return ResponseDTO.fromJson(
        normalizedJson,
        (payload) => ConversationDTO.fromJson(payload as Map<String, dynamic>),
      );
    }

    if (data.containsKey('isMute')) {
      final response = await _request('/conversation/$conversationId/mute', method: 'POST', body: {
        'type': type,
        'isMute': data['isMute'],
      });
      final json = jsonDecode(response.body);
      final normalizedJson = Map<String, dynamic>.from(json);
      normalizedJson['data'] = {
        'id': conversationId,
        'type': type,
        'isMute': data['isMute'],
      };
      return ResponseDTO.fromJson(
        normalizedJson,
        (payload) => ConversationDTO.fromJson(payload as Map<String, dynamic>),
      );
    }

    throw UnsupportedError('Only isTop and isMute updates are supported');
  }

  static Future<ResponseDTO<String>> deleteConversation(int conversationId, {required int type}) async {
    final response = await _request('/conversation/$conversationId?type=$type', method: 'DELETE');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  // 好友相关API
  static Future<ResponseDTO<List<FriendDTO>>> getFriends() async {
    final response = await _request('/friend/list');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List).map((item) => FriendDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<String>> addFriend(int friendId, String remark, {String? message}) async {
    final response = await _request('/friend/add', method: 'POST', body: {
      'friendId': friendId,
      'remark': remark,
      'message': message,
    });
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<List<FriendRequestDTO>>> getReceivedFriendRequests() async {
    final response = await _request('/friend/request/received');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List)
          .map((item) => FriendRequestDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<ResponseDTO<List<FriendRequestDTO>>> getSentFriendRequests() async {
    final response = await _request('/friend/request/sent');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List)
          .map((item) => FriendRequestDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<ResponseDTO<String>> acceptFriendRequest(int requestId) async {
    final response = await _request('/friend/request/$requestId/accept', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> rejectFriendRequest(int requestId) async {
    final response = await _request('/friend/request/$requestId/reject', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> deleteFriend(int friendId) async {
    final response = await _request('/friend/$friendId', method: 'DELETE');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) async {
    final response = await _request('/report', method: 'POST', body: {
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'evidence': evidence,
    });
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => ReportDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<List<ReportDTO>>> getMyReports() async {
    final response = await _request('/report/mine');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List)
          .map((item) => ReportDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<ResponseDTO<List<ContentAuditDTO>>> getMyContentAudits() async {
    final response = await _request('/content-audit/mine');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List)
          .map((item) => ContentAuditDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<ResponseDTO<FriendDTO>> updateFriendRemark(int friendId, String remark) async {
    final response = await _request('/friend/$friendId/remark', method: 'PUT', body: {
      'remark': remark,
    });
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => FriendDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // 群组相关API
  static Future<ResponseDTO<GroupDTO>> createGroup(
    String groupName,
    String description, {
    List<int> memberIds = const [],
  }) async {
    final response = await _request('/group/create', method: 'POST', body: {
      'groupName': groupName,
      'description': description,
      'memberIds': memberIds,
    });
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => GroupDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<GroupDTO>> getGroupById(int groupId) async {
    final response = await _request('/group/$groupId');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => GroupDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<GroupDTO>> getGroupByBusinessId(String groupId) async {
    final response = await _request('/group/by-groupid/$groupId');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => GroupDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<List<GroupDTO>>> getMyGroups() async {
    final response = await _request('/group/my-groups');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List).map((item) => GroupDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<GroupDTO>> updateGroup(int groupId, Map<String, dynamic> data) async {
    final response = await _request('/group/$groupId', method: 'PUT', body: data);
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => GroupDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<String>> setGroupMute(int groupId, bool isMute) async {
    final response = await _request(
      '/group/$groupId/mute-all?mute=$isMute',
      method: 'POST',
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> setGroupMemberMute(
    int groupId,
    int memberId,
    bool isMute,
  ) async {
    final response = await _request(
      '/group/$groupId/member/$memberId/mute',
      method: 'POST',
      body: {'isMute': isMute},
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> setGroupAdmin(
    int groupId,
    int targetUserId,
  ) async {
    final response = await _request(
      '/group/$groupId/admin/$targetUserId',
      method: 'POST',
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> removeGroupAdmin(
    int groupId,
    int targetUserId,
  ) async {
    final response = await _request(
      '/group/$groupId/admin/$targetUserId',
      method: 'DELETE',
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> transferGroupOwnership(
    int groupId,
    int targetUserId,
  ) async {
    final response = await _request(
      '/group/$groupId/transfer/$targetUserId',
      method: 'POST',
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> deleteGroup(int groupId) async {
    final response = await _request('/group/$groupId/quit', method: 'POST');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) async {
    final response = await _request('/group/$groupId/members');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List).map((item) => GroupMemberDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<String>> addGroupMember(int groupId, int userId) async {
    final response = await _request('/group/$groupId/member', method: 'POST', body: {
      'memberId': userId,
      'role': 3,
    });
    final json = jsonDecode(response.body);
    final normalizedJson = Map<String, dynamic>.from(json);
    normalizedJson['data'] = json['message'];
    return ResponseDTO.fromJson(
      normalizedJson,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId) async {
    final response = await _request('/group/$groupId/member/$userId', method: 'DELETE');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> requestToJoinGroup(
    int groupId, {
    String? message,
  }) async {
    final response = await _request(
      '/group/$groupId/join',
      method: 'POST',
      body: {
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(
    int groupId,
  ) async {
    final response = await _request('/group/$groupId/join-requests');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List)
          .map((item) => GroupJoinRequestDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<ResponseDTO<List<GroupJoinRequestDTO>>> getMyGroupJoinRequests() async {
    final response = await _request('/group/join-requests/mine');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List)
          .map((item) => GroupJoinRequestDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId) async {
    final response = await _request(
      '/group/join-request/$requestId/approve',
      method: 'POST',
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId) async {
    final response = await _request(
      '/group/join-request/$requestId/reject',
      method: 'POST',
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  static Future<ResponseDTO<String>> withdrawGroupJoinRequest(int requestId) async {
    final response = await _request(
      '/group/join-request/$requestId',
      method: 'DELETE',
    );
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  // 黑名单相关API
  static Future<ResponseDTO<List<BlacklistDTO>>> getBlacklist() async {
    final response = await _request('/blacklist/list');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => (data as List).map((item) => BlacklistDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<ResponseDTO<BlacklistDTO>> addToBlacklist(int blockedUserId) async {
    final response = await _request('/blacklist/add', method: 'POST', body: {
      'blockedUserId': blockedUserId,
    });
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => BlacklistDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<String>> removeFromBlacklist(int blockedUserId) async {
    final response = await _request('/blacklist/$blockedUserId', method: 'DELETE');
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => data as String,
    );
  }

  // 文件上传相关API
  static Future<ResponseDTO<FileUploadResultDTO>> uploadImage(String filePath) async {
    return await _uploadFile('/upload/image', filePath);
  }

  /// 与 [uploadImage] 同一服务端点，用于 Web 或仅有字节时的上传（如头像选择）。
  static Future<ResponseDTO<FileUploadResultDTO>> uploadImageBytes(
    List<int> bytes, {
    String filename = 'image.jpg',
  }) async {
    final url = Uri.parse('$baseUrl/upload/image');
    final request = http.MultipartRequest('POST', url);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    final safeName = filename.trim().isEmpty ? 'image.jpg' : filename.trim();
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: safeName),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    // 上传失败可能返回 401（配置/权限/网关等与登录态不同步），勿在此处触发全局下线；
    // 真实会话失效仍由 JSON API 经 [_request] 统一处理。
    final json = jsonDecode(response.body);
    return ResponseDTO.fromJson(
      json,
      (data) => FileUploadResultDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ResponseDTO<FileUploadResultDTO>> uploadVideo(String filePath) async {
    return await _uploadFile('/upload/video', filePath);
  }

  static Future<ResponseDTO<FileUploadResultDTO>> uploadAudio(String filePath) async {
    return await _uploadFile('/upload/audio', filePath);
  }

  static Future<ResponseDTO<FileUploadResultDTO>> _uploadFile(String endpoint, String filePath) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    // 与 [uploadImageBytes] 相同： multipart 401 按业务失败解析，不当作全局未授权。
    final json = jsonDecode(response.body);

    return ResponseDTO.fromJson(
      json,
      (data) => FileUploadResultDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // 发送多媒体消息
  static Future<ResponseDTO<MessageDTO>> sendImageMessage(int targetId, String imageUrl, {bool isGroup = false}) async {
    if (isGroup) {
      return await sendGroupMessage(targetId, imageUrl, 2);
    } else {
      return await sendPrivateMessage(targetId, imageUrl, 2);
    }
  }

  static Future<ResponseDTO<MessageDTO>> sendAudioMessage(int targetId, String audioUrl, int duration, {bool isGroup = false}) async {
    if (isGroup) {
      return await sendGroupMessage(targetId, audioUrl, 3);
    } else {
      return await sendPrivateMessage(targetId, audioUrl, 3);
    }
  }

  static Future<ResponseDTO<MessageDTO>> sendVideoMessage(int targetId, String videoUrl, String coverUrl, int duration, {bool isGroup = false}) async {
    if (isGroup) {
      return await sendGroupMessage(targetId, videoUrl, 4);
    } else {
      return await sendPrivateMessage(targetId, videoUrl, 4);
    }
  }
}
