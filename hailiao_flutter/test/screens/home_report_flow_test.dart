import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/providers/report_provider.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';
import 'package:hailiao_flutter/screens/report_list_screen.dart';

import '../support/home_chat_test_fakes.dart';
import '../support/list_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('Home to report list flow should work', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());
    final reportProvider = buildReportProvider(<ReportDTO>[
      ReportDTO(
        id: 1,
        targetId: 101,
        targetTypeLabel: 'User',
        reason: 'spam',
        statusLabel: 'Pending',
        createdAt: '2026-03-31T10:20:00',
      ),
    ]);

    await pumpHomeReportFlowApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      reportProvider: reportProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(),
        '/report-list': (_) => const ReportListScreen(),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(ReportListScreen), findsOneWidget);
    expect(find.textContaining('spam'), findsOneWidget);
    expect(find.textContaining('User #101'), findsOneWidget);
  });

  testWidgets('Home to empty report list flow should show empty state', (
    WidgetTester tester,
  ) async {
    final authProvider = buildHomeAuthProvider();
    final friendProvider = FriendProvider(api: FakeHomeFriendApi());
    final messageProvider = MessageProvider(api: FakeHomeMessageApi());
    final reportProvider = buildReportProvider(const <ReportDTO>[]);

    await pumpHomeReportFlowApp(
      tester,
      authProvider: authProvider,
      friendProvider: friendProvider,
      messageProvider: messageProvider,
      reportProvider: reportProvider,
      routes: <String, WidgetBuilder>{
        ...buildHomeRoutes(),
        '/report-list': (_) => const ReportListScreen(),
      },
      home: const HomeScreen(),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(ReportListScreen), findsOneWidget);
    expect(find.text('\u6682\u65e0\u4e3e\u62a5\u8bb0\u5f55'), findsOneWidget);
  });
}
