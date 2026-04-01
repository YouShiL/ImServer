import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/providers/report_provider.dart';
import 'package:hailiao_flutter/screens/report_list_screen.dart';

import '../support/list_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('ReportListScreen should render loaded report item', (
    WidgetTester tester,
  ) async {
    final provider = buildReportProvider(<ReportDTO>[
      ReportDTO(
        id: 1,
        targetId: 101,
        targetTypeLabel: 'User',
        reason: 'spam',
        statusLabel: 'Pending',
        createdAt: '2026-03-31T10:20:00',
      ),
    ]);

    await pumpReportScreenApp(
      tester,
      reportProvider: provider,
      home: const ReportListScreen(),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('spam'), findsOneWidget);
    expect(find.textContaining('User #101'), findsOneWidget);
  });

  testWidgets('ReportListScreen should render empty state', (
    WidgetTester tester,
  ) async {
    final provider = buildReportProvider(<ReportDTO>[]);

    await pumpReportScreenApp(
      tester,
      reportProvider: provider,
      home: const ReportListScreen(),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('\u6682\u65e0\u4e3e\u62a5\u8bb0\u5f55'), findsOneWidget);
  });
}
