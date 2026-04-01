import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/screens/group_detail_screen.dart';
import 'package:hailiao_flutter/screens/group_list_screen.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';

import '../support/detail_screen_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('Home should reach group chat through group detail', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = buildChatMessageProvider();
    final blacklistProvider = buildChatBlacklistProvider();
    final groupProvider = GroupProvider(api: FakeGroupFlowApi());

    await pumpHomeGroupChatFlowApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      blacklistProvider: blacklistProvider,
      groupProvider: groupProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(),
        '/groups': (_) => const GroupListScreen(),
        '/group-detail': (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
        '/chat': (_) => ChatScreen(api: FakeChatScreenApi()),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Team Alpha').first);
    await tester.pumpAndSettle();

    expect(find.byType(GroupDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byIcon(Icons.search), findsWidgets);
  });
}
