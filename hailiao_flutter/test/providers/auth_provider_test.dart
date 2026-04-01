import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/auth_response_dto.dart';
import 'package:hailiao_flutter/models/login_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';

import '../support/auth_test_fakes.dart';

UserDTO buildUser({
  int id = 1,
  String nickname = 'tester',
  String phone = '13800000000',
}) {
  return UserDTO(
    id: id,
    userId: id.toString(),
    phone: phone,
    nickname: nickname,
  );
}

void main() {
  group('AuthProvider', () {
    test('login should persist token and user on success', () async {
      final storage = FakeAuthStorage();
      LoginRequestDTO? capturedRequest;
      final api = FakeAuthApi(
        loginHandler: (LoginRequestDTO request) async {
          capturedRequest = request;
          return ResponseDTO<AuthResponseDTO>(
            code: 200,
            message: 'ok',
            data: AuthResponseDTO(
              token: 'token-1',
              user: buildUser(),
              loginNotice: 'notice',
            ),
          );
        },
      );

      final provider = AuthProvider(
        api: api,
        storage: storage,
        deviceInfoProvider: FakeDeviceInfoProvider(),
        autoLoadSavedToken: false,
      );

      final result = await provider.login('13800000000', 'secret');

      expect(result, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.token, 'token-1');
      expect(provider.user?.nickname, 'tester');
      expect(provider.loginNotice, 'notice');
      expect(storage.data['token'], 'token-1');
      expect(storage.data['user'], isNotNull);
      expect(capturedRequest?.deviceId, 'device-test');
      expect(capturedRequest?.deviceName, 'Test device');
      expect(capturedRequest?.deviceType, 'windows');
    });

    test('loadSessions should populate session list', () async {
      final api = FakeAuthApi(
        userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
          code: 200,
          message: 'ok',
          data: <UserSessionDTO>[
            UserSessionDTO(
              sessionId: 's1',
              deviceName: 'Desktop',
              active: true,
            ),
          ],
        ),
      );
      final provider = AuthProvider(
        api: api,
        storage: FakeAuthStorage(),
        deviceInfoProvider: FakeDeviceInfoProvider(),
        autoLoadSavedToken: false,
      );

      final result = await provider.loadSessions();

      expect(result, isTrue);
      expect(provider.sessions.length, 1);
      expect(provider.sessions.first.sessionId, 's1');
    });

    test('handleUnauthorized should clear auth state and expose logout notice', () async {
      final storage = FakeAuthStorage(
        initialData: <String, String>{
          'token': 'saved-token',
          'user': '{"id":1,"userId":1,"nickname":"tester"}',
        },
      );
      final provider = AuthProvider(
        api: FakeAuthApi(),
        storage: storage,
        deviceInfoProvider: FakeDeviceInfoProvider(),
        autoLoadSavedToken: false,
      );

      await provider.handleUnauthorized();

      expect(provider.isAuthenticated, isFalse);
      expect(
        provider.error,
        '\u767b\u5f55\u72b6\u6001\u5df2\u5931\u6548\uff0c\u8bf7\u91cd\u65b0\u767b\u5f55\u3002',
      );
      expect(provider.consumeLogoutNotice(), isNotNull);
      expect(storage.data.containsKey('token'), isFalse);
      expect(storage.data.containsKey('user'), isFalse);
    });

    test('login should expose api error on failure', () async {
      final provider = AuthProvider(
        api: FakeAuthApi(
          loginHandler: (LoginRequestDTO request) async =>
              ResponseDTO<AuthResponseDTO>(
                code: 400,
                message: 'bad credentials',
                data: null,
              ),
        ),
        storage: FakeAuthStorage(),
        deviceInfoProvider: FakeDeviceInfoProvider(),
        autoLoadSavedToken: false,
      );

      final result = await provider.login('13800000000', 'wrong');

      expect(result, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.error, 'bad credentials');
    });

    test('terminateOtherSessions should refresh sessions on success', () async {
      final api = FakeAuthApi(
        terminateOtherSessionsHandler: () async =>
            ResponseDTO<String>(code: 200, message: 'ok', data: 'done'),
        userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
          code: 200,
          message: 'ok',
          data: <UserSessionDTO>[
            UserSessionDTO(
              sessionId: 'current',
              currentSession: true,
              active: true,
            ),
          ],
        ),
      );
      final provider = AuthProvider(
        api: api,
        storage: FakeAuthStorage(),
        deviceInfoProvider: FakeDeviceInfoProvider(),
        autoLoadSavedToken: false,
      );

      final result = await provider.terminateOtherSessions();

      expect(result, isTrue);
      expect(provider.sessions.length, 1);
      expect(provider.sessions.first.sessionId, 'current');
    });
  });
}
