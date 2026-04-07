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
  testWidgets('Home friend tab should reach chat through user detail', (
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
        '/user-detail': (_) => UserDetailScreen(api: FakeUserDetailApi()),
        '/chat': (_) => ChatScreen(api: FakeChatScreenApi()),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Work friend').first);
    await tester.pumpAndSettle();

    expect(find.byType(UserDetailScreen), findsOneWidget);

    await tester.tap(find.text('发消息'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byIcon(Icons.search), findsWidgets);
  });
}
