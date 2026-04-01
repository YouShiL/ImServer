import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/blacklist_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';

abstract class BlacklistApi {
  Future<ResponseDTO<List<BlacklistDTO>>> getBlacklist();
  Future<ResponseDTO<BlacklistDTO>> addToBlacklist(int blockedUserId);
  Future<ResponseDTO<String>> removeFromBlacklist(int blockedUserId);
}

class ApiBlacklistApi implements BlacklistApi {
  @override
  Future<ResponseDTO<List<BlacklistDTO>>> getBlacklist() {
    return ApiService.getBlacklist();
  }

  @override
  Future<ResponseDTO<BlacklistDTO>> addToBlacklist(int blockedUserId) {
    return ApiService.addToBlacklist(blockedUserId);
  }

  @override
  Future<ResponseDTO<String>> removeFromBlacklist(int blockedUserId) {
    return ApiService.removeFromBlacklist(blockedUserId);
  }
}

class BlacklistProvider extends ChangeNotifier {
  BlacklistProvider({BlacklistApi? api}) : _api = api ?? ApiBlacklistApi();

  final BlacklistApi _api;
  List<BlacklistDTO> _blacklist = [];
  bool _isLoading = false;
  String? _error;

  List<BlacklistDTO> get blacklist => _blacklist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBlacklist() async {
    _startLoading();
    try {
      final response = await _api.getBlacklist();
      if (response.isSuccess && response.data != null) {
        _blacklist = response.data!;
      } else {
        _error = response.message;
      }
    } catch (_) {
      _error = '加载黑名单失败，请稍后重试。';
    } finally {
      _finishLoading();
    }
  }

  Future<bool> addToBlacklist(int blockedUserId) async {
    _startLoading();
    try {
      final response = await _api.addToBlacklist(blockedUserId);
      if (response.isSuccess && response.data != null) {
        _blacklist = [..._blacklist, response.data!];
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '加入黑名单失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> removeFromBlacklist(int blockedUserId) async {
    _startLoading();
    try {
      final response = await _api.removeFromBlacklist(blockedUserId);
      if (response.isSuccess) {
        _blacklist = _blacklist
            .where((item) => item.blockedUserId != blockedUserId)
            .toList();
        return true;
      }

      _error = response.message;
      return false;
    } catch (_) {
      _error = '移出黑名单失败。';
      return false;
    } finally {
      _finishLoading();
    }
  }

  bool isBlocked(int userId) {
    return _blacklist.any((item) => item.blockedUserId == userId);
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
