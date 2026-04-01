import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/providers/content_audit_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/screens/content_audit_list_screen.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';

import '../support/home_chat_test_fakes.dart';
import '../support/list_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('Home to content audit list flow should work', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());
    final contentAuditProvider = buildContentAuditProvider(<ContentAuditDTO>[
      ContentAuditDTO(
        id: 1,
        targetId: 202,
        contentTypeLabel: 'Text',
        finalResultLabel: 'Approved',
        content: 'hello world',
        statusLabel: 'Reviewed',
        createdAt: '2026-03-31T11:00:00',
      ),
    ]);

    await pumpHomeContentAuditFlowApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      contentAuditProvider: contentAuditProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(),
        '/content-audit-list': (_) => const ContentAuditListScreen(),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.verified_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(ContentAuditListScreen), findsOneWidget);
    expect(find.textContaining('Text #202'), findsOneWidget);
    expect(find.textContaining('hello world'), findsOneWidget);
  });

  testWidgets('Home to empty content audit flow should show empty state', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());
    final contentAuditProvider = buildContentAuditProvider(
      const <ContentAuditDTO>[],
    );

    await pumpHomeContentAuditFlowApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      contentAuditProvider: contentAuditProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(),
        '/content-audit-list': (_) => const ContentAuditListScreen(),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.verified_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(ContentAuditListScreen), findsOneWidget);
    expect(find.text('\u6682\u65e0\u5ba1\u6838\u8bb0\u5f55'), findsOneWidget);
  });
}
