import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';

import '../support/auth_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('HomeScreen should render tabs and profile info', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider(
      api: FakeAuthApi(
        updateUserInfoHandler: (Map<String, dynamic> data) async =>
            ResponseDTO<UserDTO>(
              code: 200,
              message: 'ok',
              data: UserDTO(
                id: 1,
                userId: 'u1',
                nickname: 'Owner',
                phone: '13800000000',
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
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.textContaining('Owner'), findsOneWidget);
    expect(find.byIcon(Icons.security_outlined), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('HomeScreen should switch between message and friend tabs', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(
      api: FakeHomeFriendApi(
        friends: <FriendDTO>[
          buildFriend(
            friendUserInfo: UserDTO(
              id: 2,
              userId: 'u2',
              nickname: 'Alice',
              signature: 'hello',
            ),
          ),
        ],
        receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
      ),
    );
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest hello',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(includeUserDetail: true),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Chat A'), findsOneWidget);
    expect(find.textContaining('Latest hello'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();

    expect(find.textContaining('Need approval'), findsOneWidget);
    expect(find.textContaining('Alice remark'), findsOneWidget);
  });

  testWidgets('HomeScreen should navigate to security page from profile tab', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.security_outlined));
    await tester.pumpAndSettle();

    expect(find.text('security'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen should keep profile state after entering security and returning',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.security_outlined));
      await tester.pumpAndSettle();

      expect(find.text('security'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Owner'), findsOneWidget);
      expect(find.byIcon(Icons.security_outlined), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets('HomeScreen should navigate to report list from profile tab', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.text('report-list'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen should keep profile state after entering report list and returning',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.text('report-list'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Owner'), findsOneWidget);
      expect(find.byIcon(Icons.security_outlined), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen should navigate to content audit list from profile tab',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.verified_outlined));
      await tester.pumpAndSettle();

      expect(find.text('content-audit-list'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen should keep profile state after entering content audit list and returning',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.verified_outlined));
      await tester.pumpAndSettle();

      expect(find.text('content-audit-list'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Owner'), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    },
  );

  testWidgets('HomeScreen should navigate to group list from messages tab', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();

    expect(find.text('groups'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen should keep message state after entering groups and returning',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest hello',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Chat A'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();

      expect(find.text('groups'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Chat A'), findsOneWidget);
      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    },
  );

  testWidgets('HomeScreen should render empty conversation state', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(conversations: const []),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('\u6682\u65e0\u6d88\u606f'), findsOneWidget);
  });

  testWidgets('HomeScreen should render empty friend state', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();

    expect(find.text('\u6682\u65e0\u597d\u53cb'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen should render friend requests without empty friend state',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
        ),
      );
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      expect(find.text('\u6682\u65e0\u597d\u53cb'), findsNothing);
      expect(find.text('\u6536\u5230\u7684\u597d\u53cb\u7533\u8bf7'), findsOneWidget);
      expect(find.textContaining('Need approval'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen should render friends without request sections',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendUserInfo: UserDTO(
                id: 2,
                userId: 'u2',
                nickname: 'Alice',
                signature: 'hello',
              ),
            ),
          ],
        ),
      );
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      expect(find.text('\u6682\u65e0\u597d\u53cb'), findsNothing);
      expect(find.text('\u6536\u5230\u7684\u597d\u53cb\u7533\u8bf7'), findsNothing);
      expect(find.text('\u53d1\u51fa\u7684\u597d\u53cb\u7533\u8bf7'), findsNothing);
      expect(find.textContaining('Alice remark'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen should keep friend state after entering user detail and returning',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendUserInfo: UserDTO(
                id: 2,
                userId: 'u2',
                nickname: 'Alice',
                signature: 'hello',
              ),
            ),
          ],
        ),
      );
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(includeUserDetail: true),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alice remark'), findsOneWidget);

      await tester.tap(find.textContaining('Alice remark'));
      await tester.pumpAndSettle();

      expect(find.text('user-detail'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Alice remark'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    },
  );

  testWidgets('HomeScreen should accept friend request with feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(
      api: FakeHomeFriendApi(
        receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
      ),
    );
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u540c\u610f'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5df2\u540c\u610f\u597d\u53cb\u7533\u8bf7'), findsOneWidget);
    expect(find.textContaining('Need approval'), findsNothing);
  });

  testWidgets('HomeScreen should reject friend request with feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(
      api: FakeHomeFriendApi(
        receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
      ),
    );
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u62d2\u7edd'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5df2\u62d2\u7edd\u597d\u53cb\u7533\u8bf7'), findsOneWidget);
    expect(find.textContaining('Need approval'), findsNothing);
  });

  testWidgets(
    'HomeScreen should render empty friend state after handling last request',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
        ),
      );
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u62d2\u7edd'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Need approval'), findsNothing);
      expect(find.text('\u6536\u5230\u7684\u597d\u53cb\u7533\u8bf7'), findsNothing);
      expect(find.text('\u6682\u65e0\u597d\u53cb'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen should keep friend list after handling last request',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendUserInfo: UserDTO(
                id: 2,
                userId: 'u2',
                nickname: 'Alice',
                signature: 'hello',
              ),
            ),
          ],
          receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
        ),
      );
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u62d2\u7edd'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Need approval'), findsNothing);
      expect(find.text('\u6536\u5230\u7684\u597d\u53cb\u7533\u8bf7'), findsNothing);
      expect(find.text('\u6682\u65e0\u597d\u53cb'), findsNothing);
      expect(find.textContaining('Alice remark'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen should keep friend-only state after tab switch following request handling',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendUserInfo: UserDTO(
                id: 2,
                userId: 'u2',
                nickname: 'Alice',
                signature: 'hello',
              ),
            ),
          ],
          receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
        ),
      );
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u540c\u610f'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('Need approval'), findsNothing);
      expect(find.text('\u6536\u5230\u7684\u597d\u53cb\u7533\u8bf7'), findsNothing);
      expect(find.text('\u6682\u65e0\u597d\u53cb'), findsNothing);
      expect(find.textContaining('Alice remark'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen should keep friend-only state after request handling and returning from user detail',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendUserInfo: UserDTO(
                id: 2,
                userId: 'u2',
                nickname: 'Alice',
                signature: 'hello',
              ),
            ),
          ],
          receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
        ),
      );
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(includeUserDetail: true),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u540c\u610f'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Need approval'), findsNothing);
      expect(find.textContaining('Alice remark'), findsOneWidget);

      await tester.tap(find.textContaining('Alice remark'));
      await tester.pumpAndSettle();

      expect(find.text('user-detail'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Need approval'), findsNothing);
      expect(find.text('\u6536\u5230\u7684\u597d\u53cb\u7533\u8bf7'), findsNothing);
      expect(find.textContaining('Alice remark'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen should keep friend-only state after rejecting request and returning from user detail',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendUserInfo: UserDTO(
                id: 2,
                userId: 'u2',
                nickname: 'Alice',
                signature: 'hello',
              ),
            ),
          ],
          receivedRequests: <FriendRequestDTO>[buildFriendRequest()],
        ),
      );
      final messageProvider = MessageProvider(api: FakeHomeMessageApi());

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(includeUserDetail: true),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u62d2\u7edd'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Need approval'), findsNothing);
      expect(find.textContaining('Alice remark'), findsOneWidget);

      await tester.tap(find.textContaining('Alice remark'));
      await tester.pumpAndSettle();

      expect(find.text('user-detail'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Need approval'), findsNothing);
      expect(find.text('\u6536\u5230\u7684\u597d\u53cb\u7533\u8bf7'), findsNothing);
      expect(find.textContaining('Alice remark'), findsOneWidget);
    },
  );

  testWidgets('HomeScreen should navigate to login after logout', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider(
      api: FakeAuthApi(
        logoutHandler: () async =>
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
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u9000\u51fa\u767b\u5f55'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('HomeScreen should open conversation actions on long press', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest hello',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();

    expect(find.text('\u7f6e\u9876\u4f1a\u8bdd'), findsOneWidget);
    expect(find.text('\u5f00\u542f\u514d\u6253\u6270'), findsOneWidget);
    expect(find.text('\u5220\u9664\u4f1a\u8bdd'), findsOneWidget);
  });

  testWidgets('HomeScreen should close conversation actions sheet', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest hello',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();

    expect(find.text('\u7f6e\u9876\u4f1a\u8bdd'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('\u7f6e\u9876\u4f1a\u8bdd'), findsNothing);
    expect(find.text('\u5f00\u542f\u514d\u6253\u6270'), findsNothing);
    expect(find.text('\u5220\u9664\u4f1a\u8bdd'), findsNothing);
  });

  testWidgets('HomeScreen should show top conversation feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest hello',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u7f6e\u9876\u4f1a\u8bdd'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5df2\u7f6e\u9876\u4f1a\u8bdd'), findsOneWidget);

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();

    expect(find.text('\u53d6\u6d88\u7f6e\u9876'), findsOneWidget);
  });

  testWidgets('HomeScreen should show mute conversation feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest hello',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u5f00\u542f\u514d\u6253\u6270'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5df2\u5f00\u542f\u514d\u6253\u6270'), findsOneWidget);

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();

    expect(find.text('\u53d6\u6d88\u514d\u6253\u6270'), findsOneWidget);
  });

  testWidgets('HomeScreen should show delete conversation feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest hello',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u5220\u9664\u4f1a\u8bdd'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u786e\u8ba4\u5220\u9664'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5df2\u5220\u9664\u4f1a\u8bdd'), findsOneWidget);
    expect(find.textContaining('Chat A'), findsNothing);
  });

  testWidgets(
    'HomeScreen should keep deleted conversation state after entering groups and returning',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest hello',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.longPress(find.textContaining('Chat A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u5220\u9664\u4f1a\u8bdd'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u786e\u8ba4\u5220\u9664'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Chat A'), findsNothing);

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(find.text('groups'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Chat A'), findsNothing);
    },
  );

  testWidgets(
    'HomeScreen should keep deleted conversation state after tab switch',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest hello',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.longPress(find.textContaining('Chat A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u5220\u9664\u4f1a\u8bdd'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u786e\u8ba4\u5220\u9664'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Chat A'), findsNothing);

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Chat A'), findsNothing);
    },
  );

  testWidgets('HomeScreen should move topped conversation ahead in list', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 3,
            type: 1,
            name: 'Chat B',
            lastMessage: 'Latest B',
            lastMessageTime: '2026-03-31T12:05:00',
          ),
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest A',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final beforeA = tester.getTopLeft(find.textContaining('Chat A').first).dy;
    final beforeB = tester.getTopLeft(find.textContaining('Chat B').first).dy;
    expect(beforeA, greaterThan(beforeB));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u7f6e\u9876\u4f1a\u8bdd'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final afterA = tester.getTopLeft(find.textContaining('Chat A').first).dy;
    final afterB = tester.getTopLeft(find.textContaining('Chat B').first).dy;
    expect(afterA, lessThan(afterB));
  });

  testWidgets('HomeScreen should show muted conversation in muted filter', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 3,
            type: 1,
            name: 'Chat B',
            lastMessage: 'Latest B',
            lastMessageTime: '2026-03-31T12:05:00',
          ),
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest A',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u5f00\u542f\u514d\u6253\u6270'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('\u514d\u6253\u6270'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chat A'), findsOneWidget);
    expect(find.textContaining('Chat B'), findsNothing);
  });

  testWidgets(
    'HomeScreen should keep muted filter result after tab switch',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 3,
              type: 1,
              name: 'Chat B',
              lastMessage: 'Latest B',
              lastMessageTime: '2026-03-31T12:05:00',
            ),
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest A',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.longPress(find.textContaining('Chat A').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u5f00\u542f\u514d\u6253\u6270'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u514d\u6253\u6270'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Chat A'), findsOneWidget);
      expect(find.textContaining('Chat B'), findsNothing);
    },
  );

  testWidgets(
    'HomeScreen should keep muted filter result after entering groups and returning',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 3,
              type: 1,
              name: 'Chat B',
              lastMessage: 'Latest B',
              lastMessageTime: '2026-03-31T12:05:00',
            ),
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest A',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.longPress(find.textContaining('Chat A').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u5f00\u542f\u514d\u6253\u6270'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(find.text('groups'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u514d\u6253\u6270'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Chat A'), findsOneWidget);
      expect(find.textContaining('Chat B'), findsNothing);
    },
  );

  testWidgets('HomeScreen should show topped conversation in top filter', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 3,
            type: 1,
            name: 'Chat B',
            lastMessage: 'Latest B',
            lastMessageTime: '2026-03-31T12:05:00',
          ),
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest A',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u7f6e\u9876\u4f1a\u8bdd'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('\u7f6e\u9876'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chat A'), findsOneWidget);
    expect(find.textContaining('Chat B'), findsNothing);
  });

  testWidgets(
    'HomeScreen should keep top filter result after tab switch',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 3,
              type: 1,
              name: 'Chat B',
              lastMessage: 'Latest B',
              lastMessageTime: '2026-03-31T12:05:00',
            ),
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest A',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.longPress(find.textContaining('Chat A').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u7f6e\u9876\u4f1a\u8bdd'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u7f6e\u9876'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Chat A'), findsOneWidget);
      expect(find.textContaining('Chat B'), findsNothing);
    },
  );

  testWidgets(
    'HomeScreen should keep top filter result after entering groups and returning',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 3,
              type: 1,
              name: 'Chat B',
              lastMessage: 'Latest B',
              lastMessageTime: '2026-03-31T12:05:00',
            ),
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest A',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.longPress(find.textContaining('Chat A').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u7f6e\u9876\u4f1a\u8bdd'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(find.text('groups'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u7f6e\u9876'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Chat A'), findsOneWidget);
      expect(find.textContaining('Chat B'), findsNothing);
    },
  );

  testWidgets('HomeScreen should show unmute conversation feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest A',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u5f00\u542f\u514d\u6253\u6270'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u53d6\u6d88\u514d\u6253\u6270'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5df2\u53d6\u6d88\u514d\u6253\u6270'), findsOneWidget);
  });

  testWidgets('HomeScreen should hide conversation from muted filter after unmute', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 3,
            type: 1,
            name: 'Chat B',
            lastMessage: 'Latest B',
            lastMessageTime: '2026-03-31T12:05:00',
          ),
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest A',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u5f00\u542f\u514d\u6253\u6270'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u53d6\u6d88\u514d\u6253\u6270'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('\u514d\u6253\u6270'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chat A'), findsNothing);
    expect(find.textContaining('Chat B'), findsNothing);
  });

  testWidgets('HomeScreen should show untop conversation feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest A',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u7f6e\u9876\u4f1a\u8bdd'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u53d6\u6d88\u7f6e\u9876'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5df2\u53d6\u6d88\u7f6e\u9876'), findsOneWidget);
  });

  testWidgets('HomeScreen should hide conversation from top filter after untop', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 3,
            type: 1,
            name: 'Chat B',
            lastMessage: 'Latest B',
            lastMessageTime: '2026-03-31T12:05:00',
          ),
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest A',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u7f6e\u9876\u4f1a\u8bdd'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u53d6\u6d88\u7f6e\u9876'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('\u7f6e\u9876'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chat A'), findsNothing);
    expect(find.textContaining('Chat B'), findsNothing);
  });

  testWidgets('HomeScreen should hide conversation from top filter after untop', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 3,
            type: 1,
            name: 'Chat B',
            lastMessage: 'Latest B',
            lastMessageTime: '2026-03-31T12:05:00',
          ),
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest A',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u7f6e\u9876\u4f1a\u8bdd'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.longPress(find.textContaining('Chat A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u53d6\u6d88\u7f6e\u9876'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('\u7f6e\u9876'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chat A'), findsNothing);
    expect(find.textContaining('Chat B'), findsNothing);
  });

  testWidgets('HomeScreen should render empty state after deleting last conversation', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: [
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'Latest hello',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await pumpHomeScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      routes: buildHomeRoutes(),
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.textContaining('Chat A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u5220\u9664\u4f1a\u8bdd'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u786e\u8ba4\u5220\u9664'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u6682\u65e0\u6d88\u606f'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen should keep empty message state after deleting last conversation and switching tabs',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest hello',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.longPress(find.textContaining('Chat A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u5220\u9664\u4f1a\u8bdd'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u786e\u8ba4\u5220\u9664'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u6682\u65e0\u6d88\u606f'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('\u6682\u65e0\u6d88\u606f'), findsOneWidget);
      expect(find.textContaining('Chat A'), findsNothing);
    },
  );

  testWidgets(
    'HomeScreen should keep empty message state after deleting last conversation and returning from groups',
    (WidgetTester tester,
  ) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: [
            buildConversation(
              targetId: 2,
              type: 1,
              name: 'Chat A',
              lastMessage: 'Latest hello',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await pumpHomeScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
        routes: buildHomeRoutes(),
        home: const HomeScreen(),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.longPress(find.textContaining('Chat A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u5220\u9664\u4f1a\u8bdd'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u786e\u8ba4\u5220\u9664'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u6682\u65e0\u6d88\u606f'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(find.text('groups'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('\u6682\u65e0\u6d88\u606f'), findsOneWidget);
      expect(find.textContaining('Chat A'), findsNothing);
    },
  );
}
