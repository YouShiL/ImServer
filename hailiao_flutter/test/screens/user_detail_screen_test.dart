import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/screens/user_detail_screen.dart';
import 'package:hailiao_flutter/theme/empty_state_ux_strings.dart';

import '../support/auth_test_fakes.dart';
import '../support/detail_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

/// 仅匹配资料页主体内的文案，避免与对话框标题等同名 [Text] 冲突。
Finder userDetailText(String text) {
  return find.descendant(
    of: find.byType(UserDetailScreen),
    matching: find.text(text),
  );
}

/// 「举报用户」在 ListView 底部，测试视口默认较矮时需先滚入可视区。
Future<void> tapReportUser(WidgetTester tester) async {
  final Finder finder = userDetailText('举报用户');
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tapTextOnUserDetail(WidgetTester tester, String text) async {
  final Finder finder = userDetailText(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> popTextRouteShowing(WidgetTester tester, String routeMarker) async {
  final BuildContext ctx = tester.element(find.text(routeMarker));
  Navigator.of(ctx).pop();
  await tester.pumpAndSettle();
}

class _GateUserDetailApi implements UserDetailApi {
  _GateUserDetailApi(this._until, this._inner);
  final Future<void> _until;
  final UserDetailApi _inner;

  @override
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) =>
      _inner.createReport(targetId, targetType, reason, evidence: evidence);

  @override
  Future<ResponseDTO<UserDTO>> getUserById(int userId) async {
    await _until;
    return _inner.getUserById(userId);
  }

  @override
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(
    int userId,
  ) async {
    await _until;
    return _inner.getUserOnlineInfo(userId);
  }
}

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
    expect(find.text('发消息'), findsOneWidget);
    expect(find.text('加入黑名单'), findsOneWidget);
    expect(find.text('修改备注'), findsOneWidget);
    expect(find.textContaining('Work friend'), findsWidgets);
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

    await tester.tap(find.text('发消息'));
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

      await tester.tap(find.text('发消息'));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await popTextRouteShowing(tester, 'chat');

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('发消息'), findsOneWidget);
      expect(userDetailText('举报用户'), findsOneWidget);
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

    await tapReportUser(tester);

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

      await tapReportUser(tester);

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('发消息'), findsOneWidget);
      expect(userDetailText('举报用户'), findsOneWidget);
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

      await tapReportUser(tester);

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pumpAndSettle();

      expect(find.text('\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);
      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('发消息'), findsOneWidget);
      expect(userDetailText('举报用户'), findsOneWidget);
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

      await tapReportUser(tester);

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pumpAndSettle();

      expect(find.text('\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tapTextOnUserDetail(tester, '发消息');

      expect(find.text('chat'), findsOneWidget);

      await popTextRouteShowing(tester, 'chat');

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('发消息'), findsOneWidget);
      expect(userDetailText('举报用户'), findsOneWidget);
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

      await tapReportUser(tester);

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pumpAndSettle();

      expect(find.text('\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tapTextOnUserDetail(tester, '加入黑名单');

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('发消息'), findsOneWidget);
      expect(userDetailText('举报用户'), findsOneWidget);
      expect(find.text('加入黑名单'), findsOneWidget);
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

      await tapReportUser(tester);

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pumpAndSettle();

      expect(find.text('\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tapReportUser(tester);

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('发消息'), findsOneWidget);
      expect(userDetailText('举报用户'), findsOneWidget);
      expect(find.text('加入黑名单'), findsOneWidget);
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

    await tester.tap(find.text('加入黑名单'));
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

      await tester.tap(find.text('加入黑名单'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('发消息'), findsOneWidget);
      expect(find.text('加入黑名单'), findsOneWidget);
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

    expect(find.text('发消息'), findsOneWidget);
    expect(find.text('解除拉黑'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
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

    await tester.tap(find.text('解除拉黑'));
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

      await tester.tap(find.text('解除拉黑'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.text('发消息'), findsOneWidget);
      expect(find.text('解除拉黑'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    },
  );

  testWidgets(
    'UserDetailScreen should navigate to chat when user is blacklisted but still a friend',
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

    await tester.tap(find.text('发消息'));
    await tester.pumpAndSettle();

    expect(find.text('chat'), findsOneWidget);

    await popTextRouteShowing(tester, 'chat');

    expect(find.byType(UserDetailScreen), findsOneWidget);
    expect(find.text('解除拉黑'), findsOneWidget);
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

    await tester.tap(find.text('解除拉黑'));
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

      await tester.tap(find.text('解除拉黑'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('解除拉黑'), findsNothing);
      expect(find.text('发消息'), findsOneWidget);
      expect(find.text('加入黑名单'), findsOneWidget);
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

      await tester.tap(find.text('解除拉黑'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('发消息'), findsOneWidget);
      expect(find.text('加入黑名单'), findsOneWidget);

      await tester.tap(find.text('发消息'));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await popTextRouteShowing(tester, 'chat');

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.text('发消息'), findsOneWidget);
      expect(find.text('加入黑名单'), findsOneWidget);
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

      await tester.tap(find.text('解除拉黑'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('发消息'), findsOneWidget);
      expect(find.text('加入黑名单'), findsOneWidget);

      await tapReportUser(tester);

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
      expect(find.text('发消息'), findsOneWidget);
      expect(find.text('加入黑名单'), findsOneWidget);
    },
  );

  testWidgets(
    'UserDetailScreen should render snapshot title before getUserById completes',
    (WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeUserDetailBlacklistApi(),
    );
    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    final Completer<void> gate = Completer<void>();
    final UserDetailApi api = _GateUserDetailApi(gate.future, FakeUserDetailApi());

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: <String, dynamic>{
        'userId': 2,
        'user': UserDTO(id: 2, nickname: '\u5feb\u7167\u6635\u79f0'),
      },
      builder: (_) => UserDetailScreen(api: api),
    );

    await tester.pump();
    expect(find.text('\u5feb\u7167\u6635\u79f0'), findsWidgets);
    expect(find.text('Alice'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsWidgets);
  });

  testWidgets(
    'UserDetailScreen should show loading when no user snapshot until first load',
    (WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeUserDetailBlacklistApi(),
    );
    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    final Completer<void> gate = Completer<void>();
    final UserDetailApi api = _GateUserDetailApi(gate.future, FakeUserDetailApi());

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: <String, dynamic>{'userId': 2},
      builder: (_) => UserDetailScreen(api: api),
    );

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Alice'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Alice'), findsWidgets);
  });

  testWidgets('UserDetailScreen 缺少 userId 时展示统一占位', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeUserDetailBlacklistApi(),
    );

    await pumpUserDetailScreenApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      blacklistProvider: blacklistProvider,
      arguments: const <String, dynamic>{},
      builder: (_) => UserDetailScreen(api: FakeUserDetailApi()),
    );

    await tester.pump();
    await tester.pump();

    expect(
      find.text(EmptyStateUxStrings.userTargetMissingMessage),
      findsOneWidget,
    );
  });
}
