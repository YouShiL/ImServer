import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/auth_response_dto.dart';
import 'package:hailiao_flutter/models/login_request_dto.dart';
import 'package:hailiao_flutter/models/register_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthApi {
  Future<ResponseDTO<AuthResponseDTO>> login(LoginRequestDTO request);
  Future<ResponseDTO<AuthResponseDTO>> register(RegisterRequestDTO request);
  Future<ResponseDTO<String>> logout();
  Future<ResponseDTO<UserDTO>> getUserInfo();
  Future<ResponseDTO<UserDTO>> updateUserInfo(Map<String, dynamic> data);
  Future<ResponseDTO<List<UserSessionDTO>>> getUserSessions();
  Future<ResponseDTO<String>> revokeUserSession(String sessionId);
  Future<ResponseDTO<String>> terminateOtherSessions();
}

class ApiAuthApi implements AuthApi {
  @override
  Future<ResponseDTO<AuthResponseDTO>> login(LoginRequestDTO request) {
    return ApiService.login(request);
  }

  @override
  Future<ResponseDTO<AuthResponseDTO>> register(RegisterRequestDTO request) {
    return ApiService.register(request);
  }

  @override
  Future<ResponseDTO<String>> logout() {
    return ApiService.logout();
  }

  @override
  Future<ResponseDTO<UserDTO>> getUserInfo() {
    return ApiService.getUserInfo();
  }

  @override
  Future<ResponseDTO<UserDTO>> updateUserInfo(Map<String, dynamic> data) {
    return ApiService.updateUserInfo(data);
  }

  @override
  Future<ResponseDTO<List<UserSessionDTO>>> getUserSessions() {
    return ApiService.getUserSessions();
  }

  @override
  Future<ResponseDTO<String>> revokeUserSession(String sessionId) {
    return ApiService.revokeUserSession(sessionId);
  }

  @override
  Future<ResponseDTO<String>> terminateOtherSessions() {
    return ApiService.terminateOtherSessions();
  }
}

abstract class AuthStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class SharedPrefsAuthStorage implements AuthStorage {
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async {
    return (await _prefs()).getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await (await _prefs()).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await _prefs()).remove(key);
  }
}

abstract class DeviceInfoProvider {
  Future<String> getOrCreateDeviceId(AuthStorage storage);
  String deviceName();
  String deviceType();
}

class DefaultDeviceInfoProvider implements DeviceInfoProvider {
  @override
  Future<String> getOrCreateDeviceId(AuthStorage storage) async {
    final existing = await storage.getString('device_id');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = 'device-${DateTime.now().microsecondsSinceEpoch}';
    await storage.setString('device_id', created);
    return created;
  }

  @override
  String deviceType() {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  @override
  String deviceName() {
    switch (deviceType()) {
      case 'android':
        return 'Android device';
      case 'ios':
        return 'iPhone or iPad';
      case 'macos':
        return 'macOS device';
      case 'windows':
        return 'Windows desktop';
      case 'linux':
        return 'Linux device';
      case 'web':
        return 'Web browser';
      default:
        return 'Current device';
    }
  }
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthApi? api,
    AuthStorage? storage,
    DeviceInfoProvider? deviceInfoProvider,
    bool autoLoadSavedToken = true,
    UserDTO? sessionUser,
    String? sessionToken,
  }) : _api = api ?? ApiAuthApi(),
       _storage = storage ?? SharedPrefsAuthStorage(),
       _deviceInfoProvider = deviceInfoProvider ?? DefaultDeviceInfoProvider() {
    if (sessionUser != null && sessionToken != null) {
      _user = sessionUser;
      _token = sessionToken;
      ApiService.setToken(sessionToken);
    } else if (autoLoadSavedToken) {
      _loadSavedToken();
    }
  }

  final AuthApi _api;
  final AuthStorage _storage;
  final DeviceInfoProvider _deviceInfoProvider;

  UserDTO? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  String? _loginNotice;
  List<UserSessionDTO> _sessions = const [];
  bool _handlingUnauthorized = false;
  String? _logoutNotice;

  UserDTO? get user => _user;
  String? get token => _token;

  /// 聊天 / IM / 乐观消息使用的数值用户 id：优先 [UserDTO.id]，否则解析 [UserDTO.userId]（业务号多为数字串）。
  int? get messagingUserId {
    final UserDTO? u = _user;
    if (u == null) {
      return null;
    }
    if (u.id != null) {
      return u.id;
    }
    final String s = (u.userId ?? '').trim();
    if (s.isEmpty) {
      return null;
    }
    return int.tryParse(s);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get loginNotice => _loginNotice;
  List<UserSessionDTO> get sessions => _sessions;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> _loadSavedToken() async {
    final token = await _storage.getString('token');
    final userJson = await _storage.getString('user');

    if (token != null && userJson != null) {
      _token = token;
      _user = UserDTO.fromJson(
        Map<String, dynamic>.from(
          await compute((json) => jsonDecode(json), userJson),
        ),
      );
      ApiService.setToken(token);
      notifyListeners();
    }
  }

  Future<void> _saveToken(String token, UserDTO user) async {
    await _storage.setString('token', token);
    await _storage.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> _clearToken() async {
    await _storage.remove('token');
    await _storage.remove('user');
  }

  Future<bool> login(
    String phone,
    String password, {
    bool replaceExistingSession = false,
  }) async {
    _isLoading = true;
    _error = null;
    _loginNotice = null;
    notifyListeners();

    try {
      final request = LoginRequestDTO(
        phone: phone,
        password: password,
        deviceId: await _deviceInfoProvider.getOrCreateDeviceId(_storage),
        deviceName: _deviceInfoProvider.deviceName(),
        deviceType: _deviceInfoProvider.deviceType(),
        replaceExistingSession: replaceExistingSession,
      );
      final response = await _api.login(request);

      if (response.isSuccess && response.data != null) {
        _token = response.data!.token;
        _user = response.data!.user;
        _loginNotice = response.data!.loginNotice;
        _logoutNotice = null;
        ApiService.setToken(_token!);
        await _saveToken(_token!, _user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = '登录失败，请检查网络后重试。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String phone, String password, String nickname) async {
    _isLoading = true;
    _error = null;
    _loginNotice = null;
    notifyListeners();

    try {
      final request = RegisterRequestDTO(
        phone: phone,
        password: password,
        nickname: nickname,
      );
      final response = await _api.register(request);

      if (response.isSuccess && response.data != null) {
        _token = response.data!.token;
        _user = response.data!.user;
        _loginNotice = response.data!.loginNotice;
        _logoutNotice = null;
        ApiService.setToken(_token!);
        await _saveToken(_token!, _user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = '注册失败，请检查网络后重试。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    _token = null;
    _user = null;
    _sessions = const [];
    _loginNotice = null;
    ApiService.setToken('');
    await _clearToken();
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    if (_handlingUnauthorized) {
      return;
    }
    _handlingUnauthorized = true;
    _error = '登录状态已失效，请重新登录。';
    _logoutNotice =
        '当前账户已在其他设备上登录或登录状态已过期，请重新登录。';
    _token = null;
    _user = null;
    _sessions = const [];
    _loginNotice = null;
    ApiService.setToken('');
    await _clearToken();
    notifyListeners();
    _handlingUnauthorized = false;
  }

  String? consumeLogoutNotice() {
    final notice = _logoutNotice;
    _logoutNotice = null;
    return notice;
  }

  Future<bool> updateUserInfo(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.updateUserInfo(data);

      if (response.isSuccess && response.data != null) {
        _user = response.data!;
        if (_token != null) {
          await _saveToken(_token!, _user!);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = '更新失败，请检查网络后重试。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshUserInfo() async {
    try {
      final response = await _api.getUserInfo();

      if (response.isSuccess && response.data != null) {
        _user = response.data!;
        if (_token != null) {
          await _saveToken(_token!, _user!);
        }
        notifyListeners();
        return true;
      }

      await logout();
      return false;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<bool> loadSessions() async {
    try {
      final response = await _api.getUserSessions();
      if (response.isSuccess && response.data != null) {
        _sessions = response.data!;
        notifyListeners();
        return true;
      }
      _error = response.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = '加载设备会话失败。';
      notifyListeners();
      return false;
    }
  }

  Future<bool> revokeSession(String sessionId) async {
    try {
      final response = await _api.revokeUserSession(sessionId);
      if (response.isSuccess) {
        await loadSessions();
        return true;
      }
      _error = response.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = '移除设备失败。';
      notifyListeners();
      return false;
    }
  }

  Future<bool> terminateOtherSessions() async {
    try {
      final response = await _api.terminateOtherSessions();
      if (response.isSuccess) {
        await loadSessions();
        return true;
      }
      _error = response.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = '下线其他设备失败。';
      notifyListeners();
      return false;
    }
  }
}
