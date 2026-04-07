import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';
import 'package:hailiao_flutter/theme/empty_state_ux_strings.dart';
import 'package:hailiao_flutter/theme/search_ux_strings.dart';
import 'package:hailiao_flutter/widgets/chat/conversation_list_item.dart';
import 'package:hailiao_flutter/widgets/chat/conversation_search_bar.dart';

import '../support/auth_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

Future<void> _pumpHomeMessagesTabReady(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required MessageProvider messageProvider,
}) async {
  await pumpHomeScreenApp(
    tester,
    authProvider: authProvider,
    friendProvider: friendProvider,
    messageProvider: messageProvider,
    routes: buildHomeRoutes(),
    home: const HomeScreen(),
  );
  await messageProvider.loadConversations();
  await friendProvider.loadFriends();
  await pumpPostFrameBudget(tester);
}

Finder _conversationSearchField() {
  return find.descendant(
    of: find.byType(ConversationSearchBar),
    matching: find.byType(TextField),
  );
}

Future<void> _selectConversationSort(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.sort));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _selectConversationFilterChip(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('HomeScreen conversation search bar uses SearchUx hint', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'x',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await _pumpHomeMessagesTabReady(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
    );

    final TextField field = tester.widget(_conversationSearchField());
    expect(field.decoration?.hintText, SearchUxStrings.hintConversationList);
  });

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

  testWidgets(
    'HomeScreen single-chat list title prefers friend remark over nickname and snapshot name',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendId: 2,
              remark: '\u5907\u6ce8\u5217\u8868\u4f18\u5148',
              friendUserInfo: UserDTO(
                id: 2,
                userId: 'u2',
                nickname: '\u6635\u79f0\u6b21\u4e4b',
              ),
            ),
          ],
          receivedRequests: <FriendRequestDTO>[],
        ),
      );
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 2,
              type: 1,
              name: '\u5feb\u7167\u540d\u6b21\u4e4b',
              lastMessage: 'hi',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      expect(find.text('\u5907\u6ce8\u5217\u8868\u4f18\u5148'), findsOneWidget);
      expect(find.text('\u6635\u79f0\u6b21\u4e4b'), findsNothing);
    },
  );

  testWidgets(
    'HomeScreen single-chat list title falls back to conversation name when not a friend',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[],
          receivedRequests: <FriendRequestDTO>[],
        ),
      );
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 99,
              type: 1,
              name: '\u65e0\u597d\u53cb\u5feb\u7167\u6807\u9898',
              lastMessage: 'm',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      expect(find.text('\u65e0\u597d\u53cb\u5feb\u7167\u6807\u9898'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen list avatar initial matches resolved title when image URL is non-http',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[],
          receivedRequests: <FriendRequestDTO>[],
        ),
      );
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 101,
              type: 1,
              name: 'ZebraListTitle',
              avatar: 'not-a-network-url',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      final ConversationListItem tile = tester.widget<ConversationListItem>(
        find.byType(ConversationListItem).first,
      );
      expect(tile.title, 'ZebraListTitle');
      expect(tile.avatarText, 'Z');
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets(
    'HomeScreen list uses https conversation avatar as network image',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[],
          receivedRequests: <FriendRequestDTO>[],
        ),
      );
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 102,
              type: 1,
              name: 'HttpsAvatarRow',
              avatar: 'https://example.com/avatar.png',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      expect(find.byType(Image), findsWidgets);
    },
  );

  testWidgets(
    'HomeScreen single-chat list prefers friend profile https avatar over non-http conversation snapshot',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendId: 55,
              remark: '',
              friendUserInfo: UserDTO(
                id: 55,
                userId: 'u55',
                nickname: 'FriendAv',
                avatar: 'https://example.com/from-friend.png',
              ),
            ),
          ],
          receivedRequests: <FriendRequestDTO>[],
        ),
      );
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 55,
              type: 1,
              name: 'SnapName',
              avatar: 'no-network-scheme',
              lastMessage: 'm',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      expect(find.byType(Image), findsWidgets);
    },
  );

  testWidgets(
    'HomeScreen conversation search matches displayTitle conversation.name lastMessage draft',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[
            buildFriend(
              friendId: 20,
              remark: '',
              friendUserInfo: UserDTO(
                id: 20,
                userId: 'u20',
                nickname: '\u6635\u79f0\u4e13\u7528',
              ),
            ),
          ],
          receivedRequests: <FriendRequestDTO>[],
        ),
      );
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 20,
              type: 1,
              name: 'HayUniqueConvNameXYZ',
              lastMessage: 'plain',
              lastMessageTime: '2026-03-31T10:00:00',
            ),
            buildConversation(
              targetId: 21,
              type: 1,
              name: 'OtherRow',
              lastMessage: 'needleLM4422extra',
              lastMessageTime: '2026-03-31T11:00:00',
            ),
            buildConversation(
              targetId: 22,
              type: 1,
              name: 'ThirdRow',
              lastMessage: 'x',
              lastMessageTime: '2026-03-31T09:00:00',
              draft: 'draftHayBody9911',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      await tester.enterText(_conversationSearchField(), '\u6635\u79f0\u4e13\u7528');
      await tester.pump();
      expect(find.byType(ConversationListItem), findsNWidgets(1));

      await tester.enterText(_conversationSearchField(), 'HayUniqueConvName');
      await tester.pump();
      expect(find.byType(ConversationListItem), findsNWidgets(1));

      await tester.enterText(_conversationSearchField(), 'needleLM4422');
      await tester.pump();
      expect(find.byType(ConversationListItem), findsNWidgets(1));
      expect(find.text('OtherRow'), findsOneWidget);

      await tester.enterText(_conversationSearchField(), 'draftHayBody');
      await tester.pump();
      expect(find.byType(ConversationListItem), findsNWidgets(1));

      await tester.enterText(_conversationSearchField(), '');
      await tester.pump();
      expect(find.byType(ConversationListItem), findsNWidgets(3));
    },
  );

  testWidgets(
    'HomeScreen conversation search matches MessageProvider draft in haystack',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[],
          receivedRequests: <FriendRequestDTO>[],
        ),
      );
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 30,
              type: 1,
              name: 'RowProvDraft',
              lastMessage: 'z',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
            buildConversation(
              targetId: 31,
              type: 1,
              name: 'NoiseRow',
              lastMessage: 'z',
              lastMessageTime: '2026-03-31T11:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      messageProvider.setDraft(30, 1, 'providerDraftKEY998');
      await tester.pump();

      await tester.enterText(_conversationSearchField(), 'providerDraftKEY');
      await tester.pump();
      expect(find.byType(ConversationListItem), findsNWidgets(1));
      expect(find.text('RowProvDraft'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen name sort orders rows by conversation list title',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(
        api: FakeHomeFriendApi(
          friends: <FriendDTO>[],
          receivedRequests: <FriendRequestDTO>[],
        ),
      );
      final messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 201,
              type: 1,
              name: 'MangoSort',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
            buildConversation(
              targetId: 202,
              type: 1,
              name: 'ApricotSort',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T11:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      await _selectConversationSort(tester, '\u540d\u79f0\u6392\u5e8f');

      final List<ConversationListItem> tiles =
          tester.widgetList<ConversationListItem>(
        find.byType(ConversationListItem),
      ).toList();
      expect(tiles, hasLength(2));
      expect(tiles[0].title, 'ApricotSort');
      expect(tiles[1].title, 'MangoSort');
    },
  );

  testWidgets(
    'HomeScreen smart sort orders draft before newer time when pins tie',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 20,
              type: 1,
              name: 'NewerNoDraft',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
            buildConversation(
              targetId: 21,
              type: 1,
              name: 'OlderWithDraft',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T11:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );

      messageProvider.setDraft(21, 1, 'localDraftBody');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await _selectConversationSort(tester, '\u667a\u80fd\u6392\u5e8f');

      final List<ConversationListItem> tiles =
          tester.widgetList<ConversationListItem>(
        find.byType(ConversationListItem),
      ).toList();
      expect(tiles, hasLength(2));
      expect(tiles[0].title, 'OlderWithDraft');
      expect(tiles[1].title, 'NewerNoDraft');
    },
  );

  testWidgets(
    'HomeScreen smart sort keeps pinned ahead of draft and newer time',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 32,
              type: 1,
              name: 'DraftNewer',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
            buildConversation(
              targetId: 31,
              type: 1,
              name: 'PinnedOlder',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T10:00:00',
              isTop: true,
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );
      messageProvider.setDraft(32, 1, 'd');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await _selectConversationSort(tester, '\u667a\u80fd\u6392\u5e8f');

      final List<ConversationListItem> tiles =
          tester.widgetList<ConversationListItem>(
        find.byType(ConversationListItem),
      ).toList();
      expect(tiles[0].title, 'PinnedOlder');
      expect(tiles[1].title, 'DraftNewer');
    },
  );

  testWidgets(
    'HomeScreen smart sort puts any unread ahead when draft state ties',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 41,
              type: 1,
              name: 'NewerClean',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
              unreadCount: 0,
            ),
            buildConversation(
              targetId: 40,
              type: 1,
              name: 'OlderUnread',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T11:00:00',
              unreadCount: 2,
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );
      await _selectConversationSort(tester, '\u667a\u80fd\u6392\u5e8f');

      final List<ConversationListItem> tiles =
          tester.widgetList<ConversationListItem>(
        find.byType(ConversationListItem),
      ).toList();
      expect(tiles[0].title, 'OlderUnread');
      expect(tiles[1].title, 'NewerClean');
    },
  );

  testWidgets(
    'HomeScreen recent sort orders by lastMessageTime desc with pinned first',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 52,
              type: 1,
              name: 'Older',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T11:00:00',
            ),
            buildConversation(
              targetId: 51,
              type: 1,
              name: 'Newer',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );
      await _selectConversationSort(tester, '\u6700\u8fd1\u6d88\u606f');

      final List<ConversationListItem> tiles =
          tester.widgetList<ConversationListItem>(
        find.byType(ConversationListItem),
      ).toList();
      expect(tiles[0].title, 'Newer');
      expect(tiles[1].title, 'Older');
    },
  );

  testWidgets(
    'HomeScreen unread-first sort prefers higher unreadCount then time',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 62,
              type: 1,
              name: 'LowUnread',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
              unreadCount: 1,
            ),
            buildConversation(
              targetId: 61,
              type: 1,
              name: 'HighUnread',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T11:00:00',
              unreadCount: 5,
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );
      await _selectConversationSort(tester, '\u672a\u8bfb\u4f18\u5148');

      final List<ConversationListItem> tiles =
          tester.widgetList<ConversationListItem>(
        find.byType(ConversationListItem),
      ).toList();
      expect(tiles[0].title, 'HighUnread');
      expect(tiles[1].title, 'LowUnread');
    },
  );

  testWidgets(
    'HomeScreen unread filter lists only conversations with unreadCount>0',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 101,
              type: 1,
              name: 'FilterZeroUnread',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
              unreadCount: 0,
            ),
            buildConversation(
              targetId: 102,
              type: 1,
              name: 'FilterHasUnread',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T11:00:00',
              unreadCount: 3,
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );
      await _selectConversationFilterChip(tester, '\u672a\u8bfb');

      expect(find.textContaining('FilterHasUnread'), findsOneWidget);
      expect(find.textContaining('FilterZeroUnread'), findsNothing);
      expect(find.byType(ConversationListItem), findsNWidgets(1));
    },
  );

  testWidgets(
    'HomeScreen draft filter includes MessageProvider-only draft text',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 201,
              type: 1,
              name: 'DraftProviderRow',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
            ),
            buildConversation(
              targetId: 202,
              type: 1,
              name: 'DraftNoneRow',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T11:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );
      messageProvider.setDraft(201, 1, 'onlyInProviderDraft');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await _selectConversationFilterChip(tester, '\u8349\u7a3f');

      expect(find.textContaining('DraftProviderRow'), findsOneWidget);
      expect(find.textContaining('DraftNoneRow'), findsNothing);
      expect(find.byType(ConversationListItem), findsNWidgets(1));
    },
  );

  testWidgets(
    'HomeScreen draft filter includes conversation snapshot draft when no provider draft',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 301,
              type: 1,
              name: 'SnapDraftRow',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
              draft: 'fromSnapshot899',
            ),
            buildConversation(
              targetId: 302,
              type: 1,
              name: 'SnapNoDraftRow',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T11:00:00',
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );
      await _selectConversationFilterChip(tester, '\u8349\u7a3f');

      expect(find.textContaining('SnapDraftRow'), findsOneWidget);
      expect(find.textContaining('SnapNoDraftRow'), findsNothing);
    },
  );

  testWidgets(
    'HomeScreen applies name sort after unread filter on the remaining rows',
    (WidgetTester tester) async {
      final authProvider = buildHomeAuthProvider();
      final friendProvider = FriendProvider(api: FakeHomeFriendApi());
      final MessageProvider messageProvider = MessageProvider(
        api: FakeHomeMessageApi(
          conversations: <ConversationDTO>[
            buildConversation(
              targetId: 401,
              type: 1,
              name: 'ZebraUnread',
              lastMessage: 'a',
              lastMessageTime: '2026-03-31T12:00:00',
              unreadCount: 2,
            ),
            buildConversation(
              targetId: 402,
              type: 1,
              name: 'AppleUnread',
              lastMessage: 'b',
              lastMessageTime: '2026-03-31T11:00:00',
              unreadCount: 5,
            ),
            buildConversation(
              targetId: 403,
              type: 1,
              name: 'NoUnreadSkip',
              lastMessage: 'c',
              lastMessageTime: '2026-03-31T10:00:00',
              unreadCount: 0,
            ),
          ],
        ),
      );

      await _pumpHomeMessagesTabReady(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        messageProvider: messageProvider,
      );
      await _selectConversationFilterChip(tester, '\u672a\u8bfb');
      await _selectConversationSort(tester, '\u540d\u79f0\u6392\u5e8f');

      final List<ConversationListItem> tiles =
          tester.widgetList<ConversationListItem>(
        find.byType(ConversationListItem),
      ).toList();
      expect(tiles, hasLength(2));
      expect(tiles[0].title, 'AppleUnread');
      expect(tiles[1].title, 'ZebraUnread');
    },
  );

  testWidgets('HomeScreen 无会话时展示统一空态文案', (WidgetTester tester) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(conversations: <ConversationDTO>[]),
    );

    await _pumpHomeMessagesTabReady(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
    );

    expect(
      find.text(EmptyStateUxStrings.conversationListEmptyTitle),
      findsOneWidget,
    );
    expect(
      find.text(EmptyStateUxStrings.conversationListEmptyDetail),
      findsOneWidget,
    );
  });

  testWidgets('HomeScreen 筛选无匹配时展示筛选空态而非搜索无结果', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'AllRead',
            lastMessage: 'x',
            lastMessageTime: '2026-03-31T12:00:00',
            unreadCount: 0,
          ),
        ],
      ),
    );

    await _pumpHomeMessagesTabReady(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
    );
    await _selectConversationFilterChip(tester, '\u672a\u8bfb');

    expect(
      find.text(EmptyStateUxStrings.conversationFilterEmptyTitle),
      findsOneWidget,
    );
    expect(
      find.text(EmptyStateUxStrings.conversationFilterEmptyDetail),
      findsOneWidget,
    );
    expect(find.text(SearchUxStrings.emptyNoResults), findsNothing);
  });

  testWidgets('HomeScreen 会话搜索无匹配时展示未找到相关结果', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(
      api: FakeHomeMessageApi(
        conversations: <ConversationDTO>[
          buildConversation(
            targetId: 2,
            type: 1,
            name: 'Chat A',
            lastMessage: 'hello',
            lastMessageTime: '2026-03-31T12:00:00',
          ),
        ],
      ),
    );

    await _pumpHomeMessagesTabReady(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
    );
    await tester.enterText(_conversationSearchField(), '__no_match__');
    await tester.pumpAndSettle();

    expect(find.text(SearchUxStrings.emptyNoResults), findsOneWidget);
    expect(
      find.text(EmptyStateUxStrings.conversationSearchNoMatchDetail),
      findsOneWidget,
    );
  });
}
