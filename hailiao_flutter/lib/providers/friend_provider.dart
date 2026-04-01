import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';

abstract class FriendApi {
  Future<ResponseDTO<List<FriendDTO>>> getFriends();
  Future<ResponseDTO<List<FriendRequestDTO>>> getReceivedFriendRequests();
  Future<ResponseDTO<List<FriendRequestDTO>>> getSentFriendRequests();
  Future<ResponseDTO<String>> addFriend(int friendId, String remark, {String? message});
  Future<ResponseDTO<String>> acceptFriendRequest(int requestId);
  Future<ResponseDTO<String>> rejectFriendRequest(int requestId);
  Future<ResponseDTO<String>> deleteFriend(int friendId);
  Future<ResponseDTO<FriendDTO>> updateFriendRemark(int friendId, String remark);
}

class ApiFriendApi implements FriendApi {
  @override
  Future<ResponseDTO<List<FriendDTO>>> getFriends() {
    return ApiService.getFriends();
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getReceivedFriendRequests() {
    return ApiService.getReceivedFriendRequests();
  }

  @override
  Future<ResponseDTO<List<FriendRequestDTO>>> getSentFriendRequests() {
    return ApiService.getSentFriendRequests();
  }

  @override
  Future<ResponseDTO<String>> addFriend(int friendId, String remark, {String? message}) {
    return ApiService.addFriend(friendId, remark, message: message);
  }

  @override
  Future<ResponseDTO<String>> acceptFriendRequest(int requestId) {
    return ApiService.acceptFriendRequest(requestId);
  }

  @override
  Future<ResponseDTO<String>> rejectFriendRequest(int requestId) {
    return ApiService.rejectFriendRequest(requestId);
  }

  @override
  Future<ResponseDTO<String>> deleteFriend(int friendId) {
    return ApiService.deleteFriend(friendId);
  }

  @override
  Future<ResponseDTO<FriendDTO>> updateFriendRemark(int friendId, String remark) {
    return ApiService.updateFriendRemark(friendId, remark);
  }
}

class FriendProvider extends ChangeNotifier {
  FriendProvider({FriendApi? api}) : _api = api ?? ApiFriendApi();

  final FriendApi _api;
  List<FriendDTO> _friends = [];
  List<FriendRequestDTO> _receivedRequests = [];
  List<FriendRequestDTO> _sentRequests = [];
  bool _isLoading = false;
  String? _error;

  List<FriendDTO> get friends => _friends;
  List<FriendRequestDTO> get receivedRequests => _receivedRequests;
  List<FriendRequestDTO> get sentRequests => _sentRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getFriends();
      if (response.isSuccess && response.data != null) {
        _friends = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = '加载好友列表失败，请检查网络后重试。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFriendRequests() async {
    try {
      final receivedResponse = await _api.getReceivedFriendRequests();
      final sentResponse = await _api.getSentFriendRequests();

      if (receivedResponse.isSuccess && receivedResponse.data != null) {
        _receivedRequests = receivedResponse.data!;
      }
      if (sentResponse.isSuccess && sentResponse.data != null) {
        _sentRequests = sentResponse.data!;
      }

      notifyListeners();
    } catch (e) {
      // Keep the page usable even if loading requests fails.
    }
  }

  Future<bool> addFriend(int friendId, String remark, {String? message}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.addFriend(
        friendId,
        remark,
        message: message,
      );
      if (response.isSuccess) {
        await loadFriendRequests();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '发送好友申请失败。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptFriendRequest(int requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.acceptFriendRequest(requestId);
      if (response.isSuccess) {
        _receivedRequests.removeWhere((request) => request.id == requestId);
        await loadFriends();
        await loadFriendRequests();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '处理好友申请失败。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectFriendRequest(int requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.rejectFriendRequest(requestId);
      if (response.isSuccess) {
        _receivedRequests.removeWhere((request) => request.id == requestId);
        await loadFriendRequests();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '处理好友申请失败。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFriend(int friendId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.deleteFriend(friendId);
      if (response.isSuccess) {
        _friends.removeWhere((friend) => friend.friendId == friendId);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '删除好友失败。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFriendRemark(int friendId, String remark) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.updateFriendRemark(friendId, remark);
      if (response.isSuccess && response.data != null) {
        final index = _friends.indexWhere((friend) => friend.friendId == friendId);
        if (index != -1) {
          _friends[index] = response.data!;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '修改备注失败。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
