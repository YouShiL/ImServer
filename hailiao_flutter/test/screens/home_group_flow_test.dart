import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/group_detail_screen.dart';
import 'package:hailiao_flutter/screens/group_list_screen.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';

import '../support/detail_screen_test_fakes.dart';
import '../support/home_chat_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('Home to group list to group detail flow should work', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());
    final groupProvider = GroupProvider(api: FakeGroupFlowApi());

    await pumpHomeGroupFlowApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      groupProvider: groupProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(),
        '/groups': (_) => const GroupListScreen(),
        '/group-detail': (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.textContaining('Team Alpha'), findsWidgets);

    await tester.tap(find.textContaining('Team Alpha').first);
    await tester.pumpAndSettle();

    expect(find.byType(GroupDetailScreen), findsOneWidget);
    expect(find.textContaining('Owner'), findsWidgets);
    expect(find.textContaining('Member'), findsWidgets);
  });
}
