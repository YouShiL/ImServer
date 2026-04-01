import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/providers/content_audit_provider.dart';
import 'package:hailiao_flutter/screens/content_audit_list_screen.dart';

import '../support/list_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('ContentAuditListScreen should render loaded audit item', (
    WidgetTester tester,
  ) async {
    final provider = buildContentAuditProvider(<ContentAuditDTO>[
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

    await pumpContentAuditScreenApp(
      tester,
      contentAuditProvider: provider,
      home: const ContentAuditListScreen(),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Text #202'), findsOneWidget);
    expect(find.textContaining('hello world'), findsOneWidget);
  });

  testWidgets('ContentAuditListScreen should render empty state', (
    WidgetTester tester,
  ) async {
    final provider = buildContentAuditProvider(<ContentAuditDTO>[]);

    await pumpContentAuditScreenApp(
      tester,
      contentAuditProvider: provider,
      home: const ContentAuditListScreen(),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('\u6682\u65e0\u5ba1\u6838\u8bb0\u5f55'), findsOneWidget);
  });
}
