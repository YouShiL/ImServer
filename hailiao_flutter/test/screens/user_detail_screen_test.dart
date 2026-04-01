import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/screens/user_detail_screen.dart';

import '../support/auth_test_fakes.dart';
import '../support/detail_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('UserDetailScreen should render user info and friend actions', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Alice'), findsWidgets);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.textContaining('Work friend'), findsOneWidget);
  });

  testWidgets('UserDetailScreen should navigate to chat', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      routes: buildTextRoutes(<String>['/chat']),
      arguments: const <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();

    expect(find.text('chat'), findsOneWidget);
  });

  testWidgets(
    'UserDetailScreen should keep detail state after entering chat and returning',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        routes: buildTextRoutes(<String>['/chat']),
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets('UserDetailScreen should open report dialog', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'UserDetailScreen should keep detail state after closing report dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'UserDetailScreen should keep detail state after report success',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u7528\u6237\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);
      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'UserDetailScreen should keep detail state after report success and returning from chat',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        routes: buildTextRoutes(<String>['/chat']),
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u7528\u6237\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'UserDetailScreen should keep detail state after report success and closing blacklist dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u7528\u6237\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.block_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'UserDetailScreen should keep detail state after report success and closing report dialog again',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u7528\u6237\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    },
  );

  testWidgets('UserDetailScreen should open blacklist dialog', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.block_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextButton), findsWidgets);
  });

  testWidgets(
    'UserDetailScreen should keep detail state after closing blacklist dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.block_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    },
  );

  testWidgets('UserDetailScreen should show blocked state actions', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeBlockedUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('\u5df2\u62c9\u9ed1'), findsOneWidget);
    expect(find.text('\u89e3\u9664\u9ed1\u540d\u5355'), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);
  });

  testWidgets('UserDetailScreen should open unblock dialog when blocked', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeBlockedUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('\u89e3\u9664\u9ed1\u540d\u5355'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextButton), findsWidgets);
  });

  testWidgets(
    'UserDetailScreen should keep blocked state after closing unblock dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeBlockedUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u89e3\u9664\u9ed1\u540d\u5355'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.text('\u5df2\u62c9\u9ed1'), findsOneWidget);
      expect(find.text('\u89e3\u9664\u9ed1\u540d\u5355'), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
    },
  );

  testWidgets('UserDetailScreen should not navigate when main action is blocked', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeBlockedUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      routes: buildTextRoutes(<String>['/chat']),
      arguments: const <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('\u5df2\u62c9\u9ed1'));
    await tester.pumpAndSettle();

    expect(find.byType(UserDetailScreen), findsOneWidget);
    expect(find.text('chat'), findsNothing);
  });

  testWidgets('UserDetailScreen should show unblock success feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeBlockedUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('\u89e3\u9664\u9ed1\u540d\u5355'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u786e\u8ba4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5df2\u89e3\u9664\u9ed1\u540d\u5355'), findsOneWidget);
  });

  testWidgets(
    'UserDetailScreen should return to normal actions after unblock success',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeBlockedUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u89e3\u9664\u9ed1\u540d\u5355'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u5df2\u62c9\u9ed1'), findsNothing);
      expect(find.text('\u89e3\u9664\u9ed1\u540d\u5355'), findsNothing);
      expect(find.text('\u53d1\u9001\u6d88\u606f'), findsOneWidget);
      expect(find.text('\u52a0\u5165\u9ed1\u540d\u5355'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'UserDetailScreen should keep normal actions after unblock success and returning from chat',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeBlockedUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        routes: buildTextRoutes(<String>['/chat']),
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u89e3\u9664\u9ed1\u540d\u5355'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u53d1\u9001\u6d88\u606f'), findsOneWidget);
      expect(find.text('\u52a0\u5165\u9ed1\u540d\u5355'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.text('\u53d1\u9001\u6d88\u606f'), findsOneWidget);
      expect(find.text('\u52a0\u5165\u9ed1\u540d\u5355'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'UserDetailScreen should keep normal actions after unblock success and closing report dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
      final blacklistProvider = BlacklistProvider(
        api: FakeBlockedUserDetailBlacklistApi(),
      );

      await friendProvider.loadFriends();
      await blacklistProvider.loadBlacklist();

      await pumpUserDetailScreenApp(
        tester,
        authProvider: authProvider,
        friendProvider: friendProvider,
        blacklistProvider: blacklistProvider,
        arguments: const <String, dynamic>{'userId': 2},
        builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u89e3\u9664\u9ed1\u540d\u5355'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u53d1\u9001\u6d88\u606f'), findsOneWidget);
      expect(find.text('\u52a0\u5165\u9ed1\u540d\u5355'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.text('\u53d1\u9001\u6d88\u606f'), findsOneWidget);
      expect(find.text('\u52a0\u5165\u9ed1\u540d\u5355'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    },
  );
}
