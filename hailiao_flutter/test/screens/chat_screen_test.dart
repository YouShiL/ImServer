import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';

import '../support/auth_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

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
    expect(find.byIcon(Icons.send), findsOneWidget);
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
    expect(find.byIcon(Icons.send), findsOneWidget);
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

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
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

    expect(find.text('\u6682\u65e0\u6d88\u606f'), findsOneWidget);
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

    await tester.enterText(find.byType(TextField).first, 'not-found');
    await tester.tap(find.text('\u641c\u7d22'));
    await tester.pumpAndSettle();

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

      await tester.enterText(find.byType(TextField).first, 'not-found');
      await tester.tap(find.text('\u641c\u7d22'));
      await tester.pumpAndSettle();

      expect(find.text('\u6ca1\u6709\u627e\u5230\u5339\u914d\u7684\u6d88\u606f\u3002'), findsOneWidget);

      await tester.tap(find.text('\u5173\u95ed'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
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

    await tester.pageBack();
    await tester.pumpAndSettle();

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

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
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
      await tester.pageBack();
      await tester.pumpAndSettle();

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
      expect(find.byIcon(Icons.send), findsOneWidget);
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
}
