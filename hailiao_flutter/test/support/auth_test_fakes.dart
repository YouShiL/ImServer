import 'package:hailiao_flutter/models/auth_response_dto.dart';
import 'package:hailiao_flutter/models/login_request_dto.dart';
import 'package:hailiao_flutter/models/register_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'dart:convert';

typedef LoginHandler =
    Future<ResponseDTO<AuthResponseDTO>> Function(LoginRequestDTO request);
typedef RegisterHandler =
    Future<ResponseDTO<AuthResponseDTO>> Function(RegisterRequestDTO request);
typedef UserInfoHandler = Future<ResponseDTO<UserDTO>> Function();
typedef UpdateUserInfoHandler =
    Future<ResponseDTO<UserDTO>> Function(Map<String, dynamic> data);
typedef UserSessionsHandler = Future<ResponseDTO<List<UserSessionDTO>>> Function();
typedef RevokeSessionHandler = Future<ResponseDTO<String>> Function(
  String sessionId,
);
typedef StringResponseHandler = Future<ResponseDTO<String>> Function();

class FakeAuthApi implements AuthApi {
  FakeAuthApi({
    this.loginHandler,
    this.registerHandler,
    this.logoutHandler,
    this.userInfoHandler,
    this.updateUserInfoHandler,
    this.userSessionsHandler,
    this.revokeSessionHandler,
    this.terminateOtherSessionsHandler,
  });

  final LoginHandler? loginHandler;
  final RegisterHandler? registerHandler;
  final StringResponseHandler? logoutHandler;
  final UserInfoHandler? userInfoHandler;
  final UpdateUserInfoHandler? updateUserInfoHandler;
  final UserSessionsHandler? userSessionsHandler;
  final RevokeSessionHandler? revokeSessionHandler;
  final StringResponseHandler? terminateOtherSessionsHandler;

  @override
  Future<ResponseDTO<UserDTO>> getUserInfo() {
    if (userInfoHandler != null) {
      return userInfoHandler!.call();
    }
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<List<UserSessionDTO>>> getUserSessions() {
    if (userSessionsHandler != null) {
      return userSessionsHandler!.call();
    }
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<AuthResponseDTO>> login(LoginRequestDTO request) {
    if (loginHandler != null) {
      return loginHandler!.call(request);
    }
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> logout() {
    if (logoutHandler != null) {
      return logoutHandler!.call();
    }
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<AuthResponseDTO>> register(RegisterRequestDTO request) {
    if (registerHandler != null) {
      return registerHandler!.call(request);
    }
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> revokeUserSession(String sessionId) {
    if (revokeSessionHandler != null) {
      return revokeSessionHandler!.call(sessionId);
    }
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<String>> terminateOtherSessions() {
    if (terminateOtherSessionsHandler != null) {
      return terminateOtherSessionsHandler!.call();
    }
    throw UnimplementedError();
  }

  @override
  Future<ResponseDTO<UserDTO>> updateUserInfo(Map<String, dynamic> data) {
    if (updateUserInfoHandler != null) {
      return updateUserInfoHandler!.call(data);
    }
    throw UnimplementedError();
  }
}

class FakeAuthStorage implements AuthStorage {
  FakeAuthStorage({Map<String, String>? initialData})
    : data = <String, String>{...?initialData};

  final Map<String, String> data;

  @override
  Future<String?> getString(String key) async => data[key];

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    data[key] = value;
  }
}

class FakeDeviceInfoProvider implements DeviceInfoProvider {
  FakeDeviceInfoProvider({
    this.id = 'device-test',
    this.name = 'Test device',
    this.type = 'windows',
  });

  final String id;
  final String name;
  final String type;

  @override
  String deviceName() => name;

  @override
  String deviceType() => type;

  @override
  Future<String> getOrCreateDeviceId(AuthStorage storage) async => id;
}

AuthProvider buildSignedInAuthProvider({
  AuthApi? api,
  UserDTO? user,
  String token = 'token-1',
  DeviceInfoProvider? deviceInfoProvider,
}) {
  final currentUser =
      user ?? UserDTO(id: 1, userId: 'u1', nickname: 'Owner');
  return AuthProvider(
    api: api ?? FakeAuthApi(),
    storage: FakeAuthStorage(
      initialData: <String, String>{
        'token': token,
        'user': jsonEncode(currentUser.toJson()),
      },
    ),
    deviceInfoProvider: deviceInfoProvider ?? FakeDeviceInfoProvider(),
    autoLoadSavedToken: false,
    sessionUser: currentUser,
    sessionToken: token,
  );
}

AuthProvider buildDefaultScreenAuthProvider({AuthApi? api}) {
  return buildSignedInAuthProvider(api: api);
}
