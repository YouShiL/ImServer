import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';
import 'package:hailiao_flutter/screens/user_detail_screen.dart';

import '../support/detail_screen_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('Home to chat to user detail flow should work', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeUserDetailFriendApi());
    final messageProvider = buildChatMessageProvider();
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
        '/chat': (_) => ChatScreen(api: FakeChatScreenApi()),
        '/user-detail': (_) => UserDetailScreen(api: FakeUserDetailApi()),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Alice'), findsWidgets);

    await tester.tap(find.textContaining('Alice').first);
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsWidgets);

    await tester.tap(find.byIcon(Icons.info_outline).last);
    await tester.pumpAndSettle();

    expect(find.byType(UserDetailScreen), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });
}
