import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/screens/security_screen.dart';
import '../support/auth_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('SecurityScreen should render loaded session item', (
    WidgetTester tester,
  ) async {
    final provider = AuthProvider(
      api: FakeAuthApi(
        userSessionsHandler: () async =>
            ResponseDTO<List<UserSessionDTO>>(
              code: 200,
              message: 'ok',
              data: <UserSessionDTO>[
                UserSessionDTO(
                  sessionId: 's1',
                  deviceName: 'Windows desktop',
                  deviceType: 'windows',
                  loginIp: '127.0.0.1',
                  active: true,
                  currentSession: true,
                  createdAt: '2026-03-31T12:00:00',
                  lastActiveAt: '2026-03-31T12:30:00',
                ),
              ],
            ),
      ),
      storage: FakeAuthStorage(),
      deviceInfoProvider: FakeDeviceInfoProvider(),
      autoLoadSavedToken: false,
    );

    await pumpAuthScreenApp(
      tester,
      authProvider: provider,
      routes: buildTextRoutes(<String>['/login']),
      home: const SecurityScreen(),
    );

    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Windows desktop'), findsOneWidget);
    expect(find.textContaining('127.0.0.1'), findsOneWidget);
  });

  testWidgets('SecurityScreen should render empty session state', (
    WidgetTester tester,
  ) async {
    final provider = AuthProvider(
      api: FakeAuthApi(
        userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
          code: 200,
          message: 'ok',
          data: const <UserSessionDTO>[],
        ),
      ),
      storage: FakeAuthStorage(),
      deviceInfoProvider: FakeDeviceInfoProvider(),
      autoLoadSavedToken: false,
    );

    await pumpAuthScreenApp(
      tester,
      authProvider: provider,
      routes: buildTextRoutes(<String>['/login']),
      home: const SecurityScreen(),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('\u6682\u65e0\u8bbe\u5907\u8bb0\u5f55'), findsOneWidget);
  });

  testWidgets('SecurityScreen should show terminate other sessions feedback', (
    WidgetTester tester,
  ) async {
    List<UserSessionDTO> sessions = <UserSessionDTO>[
      UserSessionDTO(
        sessionId: 's1',
        deviceName: 'Windows desktop',
        deviceType: 'windows',
        loginIp: '127.0.0.1',
        active: true,
        currentSession: true,
        createdAt: '2026-03-31T12:00:00',
        lastActiveAt: '2026-03-31T12:30:00',
      ),
      UserSessionDTO(
        sessionId: 's2',
        deviceName: 'iPhone',
        deviceType: 'ios',
        loginIp: '10.0.0.8',
        active: true,
        currentSession: false,
        createdAt: '2026-03-31T10:00:00',
        lastActiveAt: '2026-03-31T11:30:00',
      ),
    ];
    final provider = AuthProvider(
      api: FakeAuthApi(
        userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
          code: 200,
          message: 'ok',
          data: sessions,
        ),
        terminateOtherSessionsHandler: () async {
          sessions = sessions
              .where((UserSessionDTO session) => session.currentSession == true)
              .toList();
          return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
        },
      ),
      storage: FakeAuthStorage(),
      deviceInfoProvider: FakeDeviceInfoProvider(),
      autoLoadSavedToken: false,
    );

    await pumpAuthScreenApp(
      tester,
      authProvider: provider,
      routes: buildTextRoutes(<String>['/login']),
      home: const SecurityScreen(),
    );

    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Windows desktop'), findsOneWidget);
    expect(find.textContaining('iPhone'), findsOneWidget);

    await tester.tap(find.text('\u4e0b\u7ebf\u5176\u4ed6\u8bbe\u5907'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5176\u4ed6\u8bbe\u5907\u5df2\u4e0b\u7ebf'), findsOneWidget);
    expect(find.textContaining('Windows desktop'), findsOneWidget);
    expect(find.textContaining('iPhone'), findsNothing);
    expect(find.text('\u6682\u65e0\u8bbe\u5907\u8bb0\u5f55'), findsNothing);
    expect(find.text('\u5f53\u524d\u6ca1\u6709\u5176\u4ed6\u5728\u7ebf\u8bbe\u5907'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '\u4e0b\u7ebf\u5176\u4ed6\u8bbe\u5907'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'SecurityScreen should enable terminate other sessions button when another active session exists',
    (WidgetTester tester,
  ) async {
      final provider = buildSignedInAuthProvider(
        user: UserDTO(
          id: 1,
          userId: 'u1',
          nickname: 'Owner',
          deviceLock: false,
        ),
        api: FakeAuthApi(
          userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
            code: 200,
            message: 'ok',
            data: <UserSessionDTO>[
              UserSessionDTO(
                sessionId: 's1',
                deviceName: 'Windows desktop',
                deviceType: 'windows',
                loginIp: '127.0.0.1',
                active: true,
                currentSession: true,
                createdAt: '2026-03-31T12:00:00',
                lastActiveAt: '2026-03-31T12:30:00',
              ),
              UserSessionDTO(
                sessionId: 's2',
                deviceName: 'iPhone',
                deviceType: 'ios',
                loginIp: '10.0.0.8',
                active: true,
                currentSession: false,
                createdAt: '2026-03-31T10:00:00',
                lastActiveAt: '2026-03-31T11:30:00',
              ),
            ],
          ),
        ),
      );

      await pumpAuthScreenApp(
        tester,
        authProvider: provider,
        routes: buildTextRoutes(<String>['/login']),
        home: const SecurityScreen(),
      );

      await tester.pump();
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '\u4e0b\u7ebf\u5176\u4ed6\u8bbe\u5907'),
      );
      expect(button.onPressed, isNotNull);
      expect(find.text('\u5f53\u524d\u6ca1\u6709\u5176\u4ed6\u5728\u7ebf\u8bbe\u5907'), findsNothing);
    },
  );

  testWidgets(
    'SecurityScreen should disable terminate other sessions button when only current session remains',
    (WidgetTester tester,
  ) async {
      final provider = buildSignedInAuthProvider(
        user: UserDTO(
          id: 1,
          userId: 'u1',
          nickname: 'Owner',
          deviceLock: false,
        ),
        api: FakeAuthApi(
          userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
            code: 200,
            message: 'ok',
            data: <UserSessionDTO>[
              UserSessionDTO(
                sessionId: 's1',
                deviceName: 'Windows desktop',
                deviceType: 'windows',
                loginIp: '127.0.0.1',
                active: true,
                currentSession: true,
                createdAt: '2026-03-31T12:00:00',
                lastActiveAt: '2026-03-31T12:30:00',
              ),
            ],
          ),
        ),
      );

      await pumpAuthScreenApp(
        tester,
        authProvider: provider,
        routes: buildTextRoutes(<String>['/login']),
        home: const SecurityScreen(),
      );

      await tester.pump();
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '\u4e0b\u7ebf\u5176\u4ed6\u8bbe\u5907'),
      );
      expect(button.onPressed, isNull);
      expect(find.text('\u5f53\u524d\u6ca1\u6709\u5176\u4ed6\u5728\u7ebf\u8bbe\u5907'), findsOneWidget);
    },
  );

  testWidgets('SecurityScreen should show device lock enable feedback', (
    WidgetTester tester,
  ) async {
    final provider = buildSignedInAuthProvider(
      user: UserDTO(
        id: 1,
        userId: 'u1',
        nickname: 'Owner',
        deviceLock: false,
      ),
      api: FakeAuthApi(
        userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
          code: 200,
          message: 'ok',
          data: <UserSessionDTO>[
            UserSessionDTO(
              sessionId: 's1',
              deviceName: 'Windows desktop',
              deviceType: 'windows',
              loginIp: '127.0.0.1',
              active: true,
              currentSession: true,
              createdAt: '2026-03-31T12:00:00',
              lastActiveAt: '2026-03-31T12:30:00',
            ),
          ],
        ),
        updateUserInfoHandler: (Map<String, dynamic> data) async =>
            ResponseDTO<UserDTO>(
              code: 200,
              message: 'ok',
              data: UserDTO(
                id: 1,
                userId: 'u1',
                nickname: 'Owner',
                deviceLock: data['deviceLock'] == true,
              ),
            ),
      ),
    );

    await pumpAuthScreenApp(
      tester,
      authProvider: provider,
      routes: buildTextRoutes(<String>['/login']),
      home: const SecurityScreen(),
    );

    await tester.pump();
    await tester.pump();

    expect(tester.widget<Switch>(find.byType(Switch)).value, false);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u8bbe\u5907\u9501\u5df2\u5f00\u542f'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, true);
  });

  testWidgets('SecurityScreen should show device lock disable feedback', (
    WidgetTester tester,
  ) async {
    final provider = buildSignedInAuthProvider(
      user: UserDTO(
        id: 1,
        userId: 'u1',
        nickname: 'Owner',
        deviceLock: true,
      ),
      api: FakeAuthApi(
        userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
          code: 200,
          message: 'ok',
          data: <UserSessionDTO>[
            UserSessionDTO(
              sessionId: 's1',
              deviceName: 'Windows desktop',
              deviceType: 'windows',
              loginIp: '127.0.0.1',
              active: true,
              currentSession: true,
              createdAt: '2026-03-31T12:00:00',
              lastActiveAt: '2026-03-31T12:30:00',
            ),
          ],
        ),
        updateUserInfoHandler: (Map<String, dynamic> data) async =>
            ResponseDTO<UserDTO>(
              code: 200,
              message: 'ok',
              data: UserDTO(
                id: 1,
                userId: 'u1',
                nickname: 'Owner',
                deviceLock: data['deviceLock'] == true,
              ),
            ),
      ),
    );

    await pumpAuthScreenApp(
      tester,
      authProvider: provider,
      routes: buildTextRoutes(<String>['/login']),
      home: const SecurityScreen(),
    );

    await tester.pump();
    await tester.pump();

    expect(tester.widget<Switch>(find.byType(Switch)).value, true);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u8bbe\u5907\u9501\u5df2\u5173\u95ed'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
  });

  testWidgets('SecurityScreen should navigate to login after logging out current session', (
    WidgetTester tester,
  ) async {
    final provider = buildSignedInAuthProvider(
      user: UserDTO(
        id: 1,
        userId: 'u1',
        nickname: 'Owner',
        deviceLock: false,
      ),
      api: FakeAuthApi(
        userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
          code: 200,
          message: 'ok',
          data: <UserSessionDTO>[
            UserSessionDTO(
              sessionId: 's1',
              deviceName: 'Windows desktop',
              deviceType: 'windows',
              loginIp: '127.0.0.1',
              active: true,
              currentSession: true,
              createdAt: '2026-03-31T12:00:00',
              lastActiveAt: '2026-03-31T12:30:00',
            ),
          ],
        ),
        revokeSessionHandler: (String sessionId) async =>
            ResponseDTO<String>(code: 200, message: 'ok', data: 'ok'),
      ),
    );

    await pumpAuthScreenApp(
      tester,
      authProvider: provider,
      routes: buildTextRoutes(<String>['/login']),
      home: const SecurityScreen(),
    );

    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Windows desktop'), findsOneWidget);

    await tester.tap(find.text('\u9000\u51fa'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.byType(SecurityScreen), findsNothing);
  });

  testWidgets(
    'SecurityScreen should stay on page after revoking another session',
    (WidgetTester tester,
  ) async {
      List<UserSessionDTO> sessions = <UserSessionDTO>[
        UserSessionDTO(
          sessionId: 's1',
          deviceName: 'Windows desktop',
          deviceType: 'windows',
          loginIp: '127.0.0.1',
          active: true,
          currentSession: true,
          createdAt: '2026-03-31T12:00:00',
          lastActiveAt: '2026-03-31T12:30:00',
        ),
        UserSessionDTO(
          sessionId: 's2',
          deviceName: 'iPhone',
          deviceType: 'ios',
          loginIp: '10.0.0.8',
          active: true,
          currentSession: false,
          createdAt: '2026-03-31T10:00:00',
          lastActiveAt: '2026-03-31T11:30:00',
        ),
      ];
      final provider = buildSignedInAuthProvider(
        user: UserDTO(
          id: 1,
          userId: 'u1',
          nickname: 'Owner',
          deviceLock: false,
        ),
        api: FakeAuthApi(
          userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
            code: 200,
            message: 'ok',
            data: sessions,
          ),
          revokeSessionHandler: (String sessionId) async {
            sessions = sessions
                .where((UserSessionDTO session) => session.sessionId != sessionId)
                .toList();
            return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
          },
        ),
      );

      await pumpAuthScreenApp(
        tester,
        authProvider: provider,
        routes: buildTextRoutes(<String>['/login']),
        home: const SecurityScreen(),
      );

      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Windows desktop'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(5));

      await tester.tap(find.text('\u4e0b\u7ebf'));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(find.text('\u8bbe\u5907\u5df2\u4e0b\u7ebf'), findsOneWidget);
      expect(find.textContaining('Windows desktop'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(4));
    },
  );
}
