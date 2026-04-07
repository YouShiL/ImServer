import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/im/im_event_bridge.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/widgets/chat/chat_forward_chip.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';
import 'package:provider/provider.dart';

import '../support/auth_test_fakes.dart';
import '../support/empty_friends_api.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/noop_chat_group_api.dart';
import '../support/screen_test_helpers.dart';

Future<void> _pumpChatScreenSettled(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  testWidgets('ChatScreen should render title status and one message', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.textContaining('Hello there'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('ChatScreen should keep typed text in composer', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField), 'typed draft');
    await tester.pump();

    expect(find.text('typed draft'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('ChatScreen should toggle emoji picker', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(GridView), findsNothing);

    await tester.tap(find.byIcon(Icons.sentiment_satisfied_alt));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.sentiment_satisfied_alt));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('ChatScreen should navigate to user detail', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      routes: buildTextRoutes(<String>['/user-detail']),
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.info_outline).last);
    await tester.pumpAndSettle();

    expect(find.text('user-detail'), findsOneWidget);
  });

  testWidgets(
    'ChatScreen should pass userId and title-derived user snapshot to user-detail when not a friend',
    (WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      title: '\u8def\u7531\u6635\u79f0',
    );
    final blacklistProvider = buildChatBlacklistProvider();
    final List<Object?> captured = <Object?>[];

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': '\u8def\u7531\u6635\u79f0',
      },
      routes: <String, WidgetBuilder>{
        '/user-detail': captureUserDetailArgumentsRoute(captured),
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final String routeTitle = '\u8def\u7531\u6635\u79f0';
    expect(
      find.text(
        ProfileDisplayTexts.singleChatDisplayTitle(
          peer: null,
          nameFallback: routeTitle,
        ),
      ),
      findsWidgets,
    );

    await tester.tap(find.byIcon(Icons.info_outline).last);
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    final Map<String, dynamic> m = captured.single! as Map<String, dynamic>;
    expect(m['userId'], 2);
    expect(m['user'], isA<UserDTO>());
    final UserDTO u = m['user'] as UserDTO;
    expect(u.id, 2);
    expect(u.nickname, routeTitle);
  });

  testWidgets(
    'ChatScreen should pass friendUserInfo as user snapshot to user-detail when friend row has profile',
    (WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();
    final List<Object?> captured = <Object?>[];
    final UserDTO peer = UserDTO(id: 2, userId: 'u2', nickname: 'Bob');
    final FriendProvider friendProvider = FriendProvider(
      api: FakeHomeFriendApi(
        friends: <FriendDTO>[
          buildFriend(
            friendId: 2,
            remark: '\u5907\u6ce8\u5c0f\u7ea2',
            friendUserInfo: peer,
          ),
        ],
      ),
    );

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      friendProvider: friendProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      routes: <String, WidgetBuilder>{
        '/user-detail': captureUserDetailArgumentsRoute(captured),
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await friendProvider.loadFriends();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.info_outline).last);
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    final Map<String, dynamic> m = captured.single! as Map<String, dynamic>;
    expect(m['userId'], 2);
    final UserDTO passed = m['user'] as UserDTO;
    expect(passed.id, peer.id);
    expect(passed.nickname, peer.nickname);
  });

  testWidgets(
    'ChatScreen should keep chat state after entering user detail and returning',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final messageProvider = buildChatMessageProvider();
      final blacklistProvider = buildChatBlacklistProvider();

      await pumpChatScreenApp(
        tester,
        authProvider: authProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{
          'targetId': 2,
          'type': 1,
          'title': 'Alice',
        },
        routes: buildTextRoutes(<String>['/user-detail']),
        builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.info_outline).last);
      await tester.pumpAndSettle();

      expect(find.text('user-detail'), findsOneWidget);

      await popTopRoute(tester);

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    },
  );

  testWidgets('ChatScreen should open search dialog', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('ChatScreen should render empty message state', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(privateMessages: const []);
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('开始聊天'), findsOneWidget);
    expect(find.text('发一条消息，开启这段对话'), findsOneWidget);
  });

  testWidgets('ChatScreen should show empty search result message', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Finder searchField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchField, 'not-found');
    await tester.tap(find.text('\u641c\u7d22'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u6ca1\u6709\u627e\u5230\u5339\u914d\u7684\u6d88\u606f\u3002'), findsOneWidget);
  });

  testWidgets(
    'ChatScreen should keep chat state after closing empty search dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final messageProvider = buildChatMessageProvider();
      final blacklistProvider = buildChatBlacklistProvider();

      await pumpChatScreenApp(
        tester,
        authProvider: authProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{
          'targetId': 2,
          'type': 1,
          'title': 'Alice',
        },
        builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final Finder searchField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(searchField, 'not-found');
      await tester.tap(find.text('\u641c\u7d22'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u6ca1\u6709\u627e\u5230\u5339\u914d\u7684\u6d88\u606f\u3002'), findsOneWidget);

      await tester.tap(find.text('\u5173\u95ed'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'ChatScreen should keep composer draft after closing search dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final messageProvider = buildChatMessageProvider();
      final blacklistProvider = buildChatBlacklistProvider();

      await pumpChatScreenApp(
        tester,
        authProvider: authProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{
          'targetId': 2,
          'type': 1,
          'title': 'Alice',
        },
        builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField), 'draft while searching');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u5173\u95ed'));
      await tester.pumpAndSettle();

      expect(find.text('draft while searching'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets('ChatScreen should close search dialog', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('\u5173\u95ed'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('ChatScreen should open media options sheet', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('\u9009\u62e9\u56fe\u7247'), findsOneWidget);
    expect(find.text('\u9009\u62e9\u89c6\u9891'), findsOneWidget);
    expect(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'), findsOneWidget);
  });

  testWidgets('ChatScreen should close media options sheet', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('\u9009\u62e9\u56fe\u7247'), findsOneWidget);

    await popTopRouteAndSettle(tester);

    expect(find.text('\u9009\u62e9\u56fe\u7247'), findsNothing);
    expect(find.text('\u9009\u62e9\u89c6\u9891'), findsNothing);
  });

  testWidgets(
    'ChatScreen should keep chat state after closing media sheet',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final messageProvider = buildChatMessageProvider();
      final blacklistProvider = buildChatBlacklistProvider();

      await pumpChatScreenApp(
        tester,
        authProvider: authProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{
          'targetId': 2,
          'type': 1,
          'title': 'Alice',
        },
        builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('\u9009\u62e9\u56fe\u7247'), findsOneWidget);

      await popTopRouteAndSettle(tester);

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'ChatScreen should keep composer draft after closing media sheet',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final messageProvider = buildChatMessageProvider();
      final blacklistProvider = buildChatBlacklistProvider();

      await pumpChatScreenApp(
        tester,
        authProvider: authProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{
          'targetId': 2,
          'type': 1,
          'title': 'Alice',
        },
        builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField), 'draft while opening media');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await popTopRouteAndSettle(tester);

      expect(find.text('draft while opening media'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets('ChatScreen should open audio dialog from media sheet', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'));
    await tester.pumpAndSettle();

    expect(find.text('\u53d1\u9001\u97f3\u9891'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('ChatScreen should close audio dialog', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'));
    await tester.pumpAndSettle();

    expect(find.text('\u53d1\u9001\u97f3\u9891'), findsOneWidget);

    await tester.tap(find.text('\u53d6\u6d88'));
    await tester.pumpAndSettle();

    expect(find.text('\u53d1\u9001\u97f3\u9891'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'ChatScreen should keep chat state after closing audio dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final messageProvider = buildChatMessageProvider();
      final blacklistProvider = buildChatBlacklistProvider();

      await pumpChatScreenApp(
        tester,
        authProvider: authProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{
          'targetId': 2,
          'type': 1,
          'title': 'Alice',
        },
        builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'));
      await tester.pumpAndSettle();

      expect(find.text('\u53d1\u9001\u97f3\u9891'), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'ChatScreen should keep composer draft after closing audio dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final messageProvider = buildChatMessageProvider();
      final blacklistProvider = buildChatBlacklistProvider();

      await pumpChatScreenApp(
        tester,
        authProvider: authProvider,
        messageProvider: messageProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{
          'targetId': 2,
          'type': 1,
          'title': 'Alice',
        },
        builder: (_) => ChatScreen(api: FakeChatScreenApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField), 'draft before audio');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.text('draft before audio'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets('ChatScreen should validate empty audio path', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u53d1\u9001'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u8bf7\u8f93\u5165\u97f3\u9891\u6587\u4ef6\u8def\u5f84\u3002'), findsOneWidget);
    expect(find.text('\u91cd\u8bd5'), findsOneWidget);
  });

  testWidgets('ChatScreen should reopen audio dialog from retry action', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u53d1\u9001'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u91cd\u8bd5'), findsOneWidget);

    await tester.tap(find.text('\u91cd\u8bd5'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('\u53d1\u9001\u97f3\u9891'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('ChatScreen should preserve audio duration on retry reopen', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.tap(find.text('\u53d1\u9001'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('\u91cd\u8bd5'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('\u53d1\u9001\u97f3\u9891'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('ChatScreen should preserve audio path and duration on file-missing retry', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u4ece\u8def\u5f84\u53d1\u9001\u97f3\u9891'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), r'Z:\missing-audio.mp3');
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.tap(find.text('\u53d1\u9001'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u672a\u627e\u5230\u97f3\u9891\u6587\u4ef6\uff0c\u8bf7\u68c0\u67e5\u672c\u5730\u8def\u5f84\u3002'), findsOneWidget);
    expect(find.text('\u91cd\u8bd5'), findsOneWidget);

    await tester.tap(find.text('\u91cd\u8bd5'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('\u53d1\u9001\u97f3\u9891'), findsOneWidget);
    expect(find.text(r'Z:\missing-audio.mp3'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('ChatScreen 单聊顶栏好友备注优先于昵称', (WidgetTester tester) async {
    final FriendProvider friendProvider = FriendProvider(
      api: StaticFriendsFriendApi(<FriendDTO>[
        buildFriend(
          remark: '备注老王',
          friendUserInfo: UserDTO(
            id: 2,
            userId: 'u2',
            nickname: '昵称小王',
          ),
        ),
      ]),
    );
    await friendProvider.loadFriends();

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      title: '会话快照',
      targetId: 2,
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      friendProvider: friendProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.text('备注老王'), findsOneWidget);
    expect(
      find.text(
        ProfileDisplayTexts.displayName(
          UserDTO(id: 2, userId: 'u2', nickname: '昵称小王'),
          friendRemark: '备注老王',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ChatScreen 群聊顶栏使用 GroupProvider 的 groupName', (
    WidgetTester tester,
  ) async {
    const int groupId = 100;
    final GroupProvider groupProvider = GroupProvider(
      api: NoopChatGroupApi(
        presetMyGroups: <GroupDTO>[
          GroupDTO(id: groupId, groupName: '产品讨论组'),
        ],
        presetMembers: <GroupMemberDTO>[
          GroupMemberDTO(userId: 1, groupId: groupId),
        ],
      ),
    );
    await groupProvider.loadGroups();
    await groupProvider.loadGroupMembers(groupId);

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      title: '会话里的旧名',
      targetId: groupId,
      type: 2,
      privateMessages: const <MessageDTO>[],
      groupMessages: <MessageDTO>[buildPrivateMessage()],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      groupProvider: groupProvider,
      arguments: <String, dynamic>{
        'targetId': groupId,
        'type': 2,
        'title': '路由快照',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.text('产品讨论组'), findsOneWidget);
  });

  testWidgets('ChatScreen 群聊顶栏 groupName 为 null 或空串时显示未命名群组', (
    WidgetTester tester,
  ) async {
    const int groupId = 101;
    final GroupProvider groupProvider = GroupProvider(
      api: NoopChatGroupApi(
        presetMyGroups: <GroupDTO>[
          GroupDTO(id: groupId, groupName: null),
        ],
        presetMembers: <GroupMemberDTO>[
          GroupMemberDTO(userId: 1, groupId: groupId),
        ],
      ),
    );
    await groupProvider.loadGroups();
    await groupProvider.loadGroupMembers(groupId);

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      title: '群聊',
      targetId: groupId,
      type: 2,
      privateMessages: const <MessageDTO>[],
      groupMessages: <MessageDTO>[buildPrivateMessage()],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      groupProvider: groupProvider,
      arguments: <String, dynamic>{
        'targetId': groupId,
        'type': 2,
        'title': '群聊',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.text('未命名群组'), findsOneWidget);
    // `groupName == ''` 时 trim 后同兜底，省略重复用例。
  });

  testWidgets('ChatScreen 群聊在 groups 未命中时回退到会话名称', (
    WidgetTester tester,
  ) async {
    const int groupId = 202;
    final GroupProvider groupProvider = GroupProvider(api: NoopChatGroupApi());
    await groupProvider.loadGroups();

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      title: '会话名回退',
      targetId: groupId,
      type: 2,
      privateMessages: const <MessageDTO>[],
      groupMessages: <MessageDTO>[buildPrivateMessage()],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      groupProvider: groupProvider,
      arguments: <String, dynamic>{
        'targetId': groupId,
        'type': 2,
        'title': '路由占位',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.text('会话名回退'), findsOneWidget);
  });

  testWidgets('ChatScreen 拉黑后会禁用输入区并展示占位与提示条', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProviderWithBlocked(<int>{2});

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(field.decoration?.hintText, '已拉黑对方，无法发送');
    expect(find.text('无法发送消息'), findsOneWidget);
  });

  testWidgets('ChatScreen 群全体禁言时禁用输入并展示占位与提示条', (
    WidgetTester tester,
  ) async {
    const int groupId = 300;
    final GroupProvider groupProvider = GroupProvider(
      api: NoopChatGroupApi(
        presetMyGroups: <GroupDTO>[
          GroupDTO(id: groupId, groupName: '全员禁言群', isMute: true),
        ],
        presetMembers: <GroupMemberDTO>[
          GroupMemberDTO(userId: 1, groupId: groupId),
        ],
      ),
    );
    await groupProvider.loadGroups();
    await groupProvider.loadGroupMembers(groupId);

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      targetId: groupId,
      type: 2,
      privateMessages: const <MessageDTO>[],
      groupMessages: <MessageDTO>[buildPrivateMessage()],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      groupProvider: groupProvider,
      arguments: <String, dynamic>{
        'targetId': groupId,
        'type': 2,
        'title': '群',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(field.decoration?.hintText, '全员禁言中，暂无法发送');
    expect(find.text('全体禁言中'), findsOneWidget);
  });

  testWidgets('ChatScreen 群成员被禁言时禁用输入并展示占位与提示条', (
    WidgetTester tester,
  ) async {
    const int groupId = 301;
    final GroupProvider groupProvider = GroupProvider(
      api: NoopChatGroupApi(
        presetMyGroups: <GroupDTO>[
          GroupDTO(id: groupId, groupName: '普群', isMute: false),
        ],
        presetMembers: <GroupMemberDTO>[
          GroupMemberDTO(userId: 1, groupId: groupId, isMute: true),
        ],
      ),
    );
    await groupProvider.loadGroups();
    await groupProvider.loadGroupMembers(groupId);

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      targetId: groupId,
      type: 2,
      privateMessages: const <MessageDTO>[],
      groupMessages: <MessageDTO>[buildPrivateMessage()],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      groupProvider: groupProvider,
      arguments: <String, dynamic>{
        'targetId': groupId,
        'type': 2,
        'title': '群',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(field.decoration?.hintText, '你已被禁言，暂无法发送');
    expect(find.text('你已被禁言'), findsOneWidget);
  });

  testWidgets('ChatScreen 群聊无消息时展示开始聊天空态', (WidgetTester tester) async {
    const int groupId = 400;
    final GroupProvider groupProvider = GroupProvider(
      api: NoopChatGroupApi(
        presetMyGroups: <GroupDTO>[
          GroupDTO(id: groupId, groupName: '空群'),
        ],
        presetMembers: <GroupMemberDTO>[
          GroupMemberDTO(userId: 1, groupId: groupId),
        ],
      ),
    );
    await groupProvider.loadGroups();
    await groupProvider.loadGroupMembers(groupId);

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      targetId: groupId,
      type: 2,
      privateMessages: const <MessageDTO>[],
      groupMessages: const <MessageDTO>[],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      groupProvider: groupProvider,
      arguments: <String, dynamic>{
        'targetId': groupId,
        'type': 2,
        'title': '空群',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.text('开始聊天'), findsOneWidget);
    expect(find.text('发一条消息，开启这段对话'), findsOneWidget);
  });

  testWidgets('ChatScreen 消息底栏 meta：发送中、已送达、已读、已编辑、已撤回', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      privateMessages: <MessageDTO>[
        buildPrivateMessage(
          id: 1,
          fromUserId: 1,
          toUserId: 2,
          content: 'a',
          createdAt: '09:01',
          status: 0,
        ),
        buildPrivateMessage(
          id: 2,
          fromUserId: 1,
          toUserId: 2,
          content: 'b',
          createdAt: '09:02',
          status: 1,
          isRead: false,
        ),
        buildPrivateMessage(
          id: 3,
          fromUserId: 1,
          toUserId: 2,
          content: 'c',
          createdAt: '09:03',
          isRead: true,
          status: 1,
        ),
        buildPrivateMessage(
          id: 4,
          fromUserId: 1,
          toUserId: 2,
          content: 'd',
          createdAt: '09:04',
          isEdited: true,
          status: 1,
          isRead: false,
        ),
        buildPrivateMessage(
          id: 5,
          fromUserId: 1,
          toUserId: 2,
          content: 'e',
          createdAt: '09:05',
          isRecalled: true,
        ),
      ],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.text('09:01 · 发送中…'), findsOneWidget);
    expect(find.text('09:02 · 已送达'), findsOneWidget);
    expect(find.text('09:03 · 已读'), findsOneWidget);
    expect(find.text('09:04 · 已编辑 · 已送达'), findsOneWidget);
    expect(find.text('此消息已撤回'), findsOneWidget);
    expect(find.text('09:05 · 已撤回'), findsNothing);
  });

  testWidgets('ChatScreen 转发条展示「转发 · 摘要」，与引用规则对齐', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      privateMessages: <MessageDTO>[
        buildPrivateMessage(
          id: 18,
          fromUserId: 2,
          toUserId: 1,
          content: '原图',
          msgType: 2,
        ),
        buildPrivateMessage(
          id: 20,
          fromUserId: 2,
          forwardFromMsgId: 18,
          msgType: 2,
          content: 'https://example.com/fwd.png',
        ),
        buildPrivateMessage(
          id: 21,
          fromUserId: 2,
          forwardFromMsgId: 99,
        ),
      ],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.byType(ChatForwardChip), findsNWidgets(2));
    expect(find.text('转发 · [图片]'), findsOneWidget);
    expect(find.text('转发 · 原消息未加载或已删除'), findsOneWidget);
  });

  testWidgets('ChatScreen 己方图片消息发送中/失败：底栏 meta 与气泡提示一致', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      privateMessages: <MessageDTO>[
        buildPrivateMessage(
          id: 30,
          fromUserId: 1,
          toUserId: 2,
          content: 'https://example.com/p.png',
          msgType: 2,
          createdAt: '10:01',
          status: 0,
        ),
        buildPrivateMessage(
          id: 31,
          fromUserId: 1,
          toUserId: 2,
          content: 'https://example.com/p2.png',
          msgType: 2,
          createdAt: '10:02',
          status: 2,
        ),
      ],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.text('10:01 · 发送中…'), findsOneWidget);
    expect(find.text('10:02 · 发送失败'), findsOneWidget);
    expect(find.text('发送中…'), findsOneWidget);
    expect(find.text('发送失败 · 可点击重试'), findsOneWidget);
  });

  testWidgets('ChatScreen 长按进入回复态：横幅、说明与输入框占位一致', (
    WidgetTester tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1400));

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    await tester.longPress(find.textContaining('Hello there'));
    await tester.pumpAndSettle();

    final replyTile = find.text('回复');
    await tester.ensureVisible(replyTile.first);
    await tester.pumpAndSettle();
    expect(find.text('引用该条消息进行回复'), findsOneWidget);
    await tester.tap(replyTile.first);
    await tester.pumpAndSettle();

    expect(find.text('回复消息'), findsOneWidget);
    expect(
      find.text('输入回复后点击下方发送，将引用所选摘要'),
      findsOneWidget,
    );

    final TextField composer = tester.widget<TextField>(find.byType(TextField));
    expect(composer.decoration?.hintText, '输入回复内容…');
  });

  testWidgets('ChatScreen 列表展示回复引用：摘要与原消息类型占位一致', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      privateMessages: <MessageDTO>[
        buildPrivateMessage(
          id: 701,
          fromUserId: 2,
          toUserId: 1,
          content: '引用原文摘要',
        ),
        buildPrivateMessage(
          id: 702,
          fromUserId: 1,
          toUserId: 2,
          content: '这条是答复',
          replyToMsgId: 701,
          status: 1,
        ),
        buildPrivateMessage(
          id: 703,
          fromUserId: 1,
          toUserId: 2,
          content: '找不到原消息时',
          replyToMsgId: 999,
          status: 1,
        ),
      ],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    expect(find.text('引用原文摘要'), findsWidgets);
    expect(find.text('这条是答复'), findsOneWidget);
    expect(find.text('找不到原消息时'), findsOneWidget);
    expect(find.text('原消息未加载或已删除'), findsOneWidget);
    expect(find.byIcon(Icons.reply_rounded), findsWidgets);
  });

  testWidgets('ChatScreen 发送回复：HTTP 未返回前即可见引用块，返回后仍保留', (
    WidgetTester tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1400));

    final gate = Completer<void>();
    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      lastMessage: '被引用原文',
      privateMessages: <MessageDTO>[
        buildPrivateMessage(
          id: 88,
          fromUserId: 2,
          toUserId: 1,
          content: '被引用原文',
        ),
      ],
      replyMessageHandler: ({
        required int replyToMsgId,
        int? toUserId,
        int? groupId,
        required String content,
        int msgType = 1,
      }) async {
        expect(replyToMsgId, 88);
        await gate.future;
        return ResponseDTO<MessageDTO>(
          code: 200,
          message: 'ok',
          data: MessageDTO(
            id: 9001,
            fromUserId: 1,
            toUserId: 2,
            content: content,
            msgType: 1,
            replyToMsgId: replyToMsgId,
            status: 1,
            createdAt: '2026-04-06T12:00:00',
          ),
        );
      },
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    await tester.longPress(find.textContaining('被引用原文'));
    await tester.pumpAndSettle();
    final replyTile = find.text('回复');
    await tester.ensureVisible(replyTile.first);
    await tester.pumpAndSettle();
    await tester.tap(replyTile.first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '我的回复');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.text('我的回复'), findsWidgets);
    expect(find.byIcon(Icons.reply_rounded), findsWidgets);
    expect(find.text('被引用原文'), findsWidgets);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.reply_rounded), findsWidgets);
    expect(find.text('我的回复'), findsWidgets);
  });

  testWidgets('ChatScreen 多选：顶栏与蓝色提示条信息分层', (
    WidgetTester tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1400));

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    await tester.longPress(find.textContaining('Hello there'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入多选'));
    await tester.pumpAndSettle();

    expect(find.text('已选 1 条'), findsOneWidget);
    expect(
      find.text('轻触消息勾选 · 左上角关闭退出'),
      findsOneWidget,
    );
    expect(
      find.textContaining('「移出当前视图」仅隐藏本页列表，服务端记录不受影响。'),
      findsOneWidget,
    );
    expect(find.textContaining('条文本'), findsOneWidget);
    expect(find.textContaining('条对方发送'), findsWidgets);
    expect(find.text('已选择 1 条'), findsNothing);
  });

  testWidgets('ChatScreen 多选：系统返回先退出多选不 pop 聊天路由', (
    WidgetTester tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1400));

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
          ChangeNotifierProvider<BlacklistProvider>.value(
            value: blacklistProvider,
          ),
          ChangeNotifierProvider<FriendProvider>.value(
            value: FriendProvider(api: EmptyFriendsFriendApi()),
          ),
          ChangeNotifierProvider<GroupProvider>.value(
            value: GroupProvider(api: NoopChatGroupApi()),
          ),
          Provider<ImEventBridge>(
            create: (BuildContext context) => ImEventBridge(
              authProvider: context.read<AuthProvider>(),
              messageProvider: context.read<MessageProvider>(),
            ),
            dispose: (_, ImEventBridge bridge) => bridge.dispose(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (BuildContext context) {
                  return TextButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(
                            arguments: <String, dynamic>{
                              'targetId': 2,
                              'type': 1,
                              'title': 'Alice',
                            },
                          ),
                          builder: (_) => ChatScreen(api: FakeChatScreenApi()),
                        ),
                      );
                    },
                    child: const Text('multi-select-back-test-entry'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('multi-select-back-test-entry'));
    await tester.pumpAndSettle();

    await _pumpChatScreenSettled(tester);

    await tester.longPress(find.textContaining('Hello there'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入多选'));
    await tester.pumpAndSettle();

    expect(find.text('已选 1 条'), findsOneWidget);

    await Navigator.maybePop(tester.element(find.byType(ChatScreen)));
    await tester.pumpAndSettle();

    expect(find.text('已选 1 条'), findsNothing);
    expect(find.textContaining('Hello there'), findsWidgets);
    expect(find.text('multi-select-back-test-entry'), findsNothing);

    await Navigator.maybePop(tester.element(find.byType(ChatScreen)));
    await tester.pumpAndSettle();

    expect(find.text('multi-select-back-test-entry'), findsOneWidget);
  });

  testWidgets('ChatScreen 多选：移出视图确认框包含已选条数', (
    WidgetTester tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1400));

    final authProvider = buildDefaultScreenAuthProvider();
    final messageProvider = buildChatMessageProvider(
      privateMessages: <MessageDTO>[
        buildPrivateMessage(id: 100, content: 'First'),
        buildPrivateMessage(id: 101, content: 'Second line'),
      ],
    );
    final blacklistProvider = buildChatBlacklistProvider();

    await pumpChatScreenApp(
      tester,
      authProvider: authProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{
        'targetId': 2,
        'type': 1,
        'title': 'Alice',
      },
      builder: (_) => ChatScreen(api: FakeChatScreenApi()),
    );

    await _pumpChatScreenSettled(tester);

    await tester.longPress(find.textContaining('First'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入多选'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Second line'));
    await tester.pumpAndSettle();

    expect(find.text('已选 2 条'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('将本页中的 2 条已选消息移出列表'),
      findsOneWidget,
    );
    expect(
      find.textContaining('不会删除服务器上的历史记录'),
      findsOneWidget,
    );

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });
}
