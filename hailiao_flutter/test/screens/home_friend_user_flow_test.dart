import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';
import 'package:hailiao_flutter/screens/user_detail_screen.dart';

import '../support/detail_screen_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('Home friend list should navigate to user detail', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());
    final blacklistProvider = BlacklistProvider(
      api: FakeUserDetailBlacklistApi(),
    );

    await friendProvider.loadFriends();
    await blacklistProvider.loadBlacklist();

    await pumpHomeChatUserFlowApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(includeUserDetail: true),
        '/user-detail': (_) => UserDetailScreen(api: FakeUserDetailApi()),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();

    expect(find.textContaining('Alice'), findsWidgets);

    await tester.tap(find.textContaining('Alice').first);
    await tester.pumpAndSettle();

    expect(find.byType(UserDetailScreen), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.block_outlined), findsOneWidget);
  });
}
