import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';

/// 返回固定 [friends] 列表，供聊天页顶栏备注/昵称规则测试。
class StaticFriendsFriendApi extends EmptyFriendsFriendApi {
  StaticFriendsFriendApi(this.friends);

  final List<FriendDTO> friends;

  @override
  Future<ResponseDTO<List<FriendDTO>>> getFriends() async {
    return ResponseDTO<List<FriendDTO>>(
      code: 200,
      message: 'ok',
      data: friends,
    );
  }
}

/// 无任何好友关系，供聊天页等测试注入 [FriendProvider]。
class EmptyFriendsFriendApi implements FriendApi {
  @override
  Future<ResponseDTO<String>> acceptFriendRequest(int requestId) async {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> addFriend(
    int friendId,
    String remark, {
    String? message,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> deleteFriend(int friendId) async {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<FriendDTO>>> getFriends() async {
    return ResponseDTO<List<FriendDTO>>(
      code: 200,
      message: 'ok',
      data: <FriendDTO>[],
    );
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>>
      getReceivedFriendRequests() async {
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
  Future<ResponseDTO<String>> rejectFriendRequest(int requestId) async {
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<FriendDTO>> updateFriendRemark(
    int friendId,
    String remark,
  ) async {
    throw UnimplementedError();
  }
}
