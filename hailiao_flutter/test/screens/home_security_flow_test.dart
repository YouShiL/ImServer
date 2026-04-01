import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';
import 'package:hailiao_flutter/screens/security_screen.dart';

import '../support/auth_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('Home profile should navigate to security screen and manage sessions', (
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
    final authProvider = buildHomeAuthProvider(
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
    );
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(),
        '/security': (_) => const SecurityScreen(),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.security_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SecurityScreen), findsOneWidget);
    expect(find.textContaining('Windows desktop'), findsOneWidget);
    expect(find.textContaining('iPhone'), findsOneWidget);
    expect(find.text('\u5f53\u524d\u6ca1\u6709\u5176\u4ed6\u5728\u7ebf\u8bbe\u5907'), findsNothing);

    final beforeButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '\u4e0b\u7ebf\u5176\u4ed6\u8bbe\u5907'),
    );
    expect(beforeButton.onPressed, isNotNull);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('iPhone'), findsNothing);
    expect(find.text('\u5f53\u524d\u6ca1\u6709\u5176\u4ed6\u5728\u7ebf\u8bbe\u5907'), findsOneWidget);

    final afterButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '\u4e0b\u7ebf\u5176\u4ed6\u8bbe\u5907'),
    );
    expect(afterButton.onPressed, isNull);
  });

  testWidgets('Home profile should toggle device lock on security screen', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider(
      api: FakeAuthApi(
        userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
          code: 200,
          message: 'ok',
          data: <UserSessionDTO>[],
        ),
        updateUserInfoHandler: (Map<String, dynamic> data) async =>
            ResponseDTO<UserDTO>(
              code: 200,
              message: 'ok',
              data: UserDTO(
                id: 1,
                userId: 'u1',
                nickname: 'Owner',
                phone: '13800000000',
                deviceLock: data['deviceLock'] == true,
              ),
            ),
      ),
    );
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(),
        '/security': (_) => const SecurityScreen(),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.security_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SecurityScreen), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets(
    'Home profile should keep device lock state after returning from security screen',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider(
        api: FakeAuthApi(
          userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
            code: 200,
            message: 'ok',
            data: const <UserSessionDTO>[],
          ),
          updateUserInfoHandler: (Map<String, dynamic> data) async =>
              ResponseDTO<UserDTO>(
                code: 200,
                message: 'ok',
                data: UserDTO(
                  id: 1,
                  userId: 'u1',
                  nickname: 'Owner',
                  phone: '13800000000',
                  deviceLock: data['deviceLock'] == true,
                ),
              ),
        ),
      );
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: <String, WidgetBuilder>{
          ...buildHomeRoutes(),
          '/security': (_) => const SecurityScreen(),
        },
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, true);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, true);
    },
  );

  testWidgets(
    'Home profile should keep disabled device lock state after returning from security screen',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider(
        api: FakeAuthApi(
          userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
            code: 200,
            message: 'ok',
            data: const <UserSessionDTO>[],
          ),
          updateUserInfoHandler: (Map<String, dynamic> data) async =>
              ResponseDTO<UserDTO>(
                code: 200,
                message: 'ok',
                data: UserDTO(
                  id: 1,
                  userId: 'u1',
                  nickname: 'Owner',
                  phone: '13800000000',
                  deviceLock: data['deviceLock'] == true,
                ),
              ),
        ),
        user: UserDTO(
          id: 1,
          userId: 'u1',
          nickname: 'Owner',
          phone: '13800000000',
          deviceLock: true,
        ),
      );
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: <String, WidgetBuilder>{
          ...buildHomeRoutes(),
          '/security': (_) => const SecurityScreen(),
        },
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, true);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, false);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    },
  );

  testWidgets(
    'Home profile should keep terminated other sessions state after returning from security screen',
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
      final authProvider = buildHomeAuthProvider(
        api: FakeAuthApi(
          userSessionsHandler: () async => ResponseDTO<List<UserSessionDTO>>(
            code: 200,
            message: 'ok',
            data: sessions,
          ),
          terminateOtherSessionsHandler: () async {
            sessions = sessions
                .where(
                  (UserSessionDTO session) => session.currentSession == true,
                )
                .toList();
            return ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');
          },
        ),
      );
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: <String, WidgetBuilder>{
          ...buildHomeRoutes(),
          '/security': (_) => const SecurityScreen(),
        },
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.textContaining('Windows desktop'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('iPhone'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(find.textContaining('Windows desktop'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsNothing);
      expect(find.text('\u5f53\u524d\u6ca1\u6709\u5176\u4ed6\u5728\u7ebf\u8bbe\u5907'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '\u4e0b\u7ebf\u5176\u4ed6\u8bbe\u5907'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'Home profile should keep revoked other session state after returning from security screen',
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
      final authProvider = buildHomeAuthProvider(
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
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: <String, WidgetBuilder>{
          ...buildHomeRoutes(),
          '/security': (_) => const SecurityScreen(),
        },
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.textContaining('Windows desktop'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsOneWidget);

      await tester.tap(find.text('\u4e0b\u7ebf'));
      await tester.pumpAndSettle();

      expect(find.textContaining('iPhone'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(find.textContaining('Windows desktop'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsNothing);
    },
  );

  testWidgets(
    'Home profile should navigate to login after logging out current session from security screen',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider(
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
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: <String, WidgetBuilder>{
          ...buildHomeRoutes(),
          '/security': (_) => const SecurityScreen(),
        },
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(find.textContaining('Windows desktop'), findsOneWidget);

      await tester.tap(find.text('\u9000\u51fa'));
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(SecurityScreen), findsNothing);
    },
  );

  testWidgets(
    'Home profile should not return to home after logging out current session from security screen',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider(
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
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: <String, WidgetBuilder>{
          ...buildHomeRoutes(),
          '/security': (_) => const SecurityScreen(),
        },
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u9000\u51fa'));
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    },
  );
}
