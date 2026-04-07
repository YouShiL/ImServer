import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/screens/group_list_screen.dart';
import 'package:hailiao_flutter/theme/empty_state_ux_strings.dart';
import 'package:hailiao_flutter/theme/search_ux_strings.dart';

import '../support/list_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('GroupListScreen 无群与无入群申请展示统一空态', (
    WidgetTester tester,
  ) async {
    final provider = buildGroupListProvider();

    await pumpGroupListScreenApp(
      tester,
      groupProvider: provider,
      home: const GroupListScreen(),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(EmptyStateUxStrings.groupListEmptyTitle),
      findsOneWidget,
    );
    expect(
      find.text(EmptyStateUxStrings.groupListEmptyDetail),
      findsOneWidget,
    );
    expect(
      find.text(EmptyStateUxStrings.groupMyJoinRequestsEmptyTitle),
      findsOneWidget,
    );
  });

  testWidgets('GroupListScreen should render groups and join requests', (
    WidgetTester tester,
  ) async {
    final provider = buildGroupListProvider(
      groups: <GroupDTO>[buildGroup()],
      requests: <GroupJoinRequestDTO>[
        buildJoinRequest(groupInfo: buildGroup(memberCount: null)),
      ],
    );

    await pumpGroupListScreenApp(
      tester,
      groupProvider: provider,
      home: const GroupListScreen(),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Team Alpha'), findsWidgets);
    expect(find.textContaining('90001'), findsWidgets);
  });

  testWidgets('GroupListScreen should navigate to group detail', (
    WidgetTester tester,
  ) async {
    final provider = buildGroupListProvider(groups: <GroupDTO>[buildGroup()]);

    await pumpGroupListScreenApp(
      tester,
      groupProvider: provider,
      routes: buildTextRoutes(<String>['/group-detail']),
      home: const GroupListScreen(),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.textContaining('Team Alpha').first);
    await tester.pumpAndSettle();

    expect(find.text('group-detail'), findsOneWidget);
  });

  testWidgets(
    'GroupListScreen should keep list state after entering group detail and returning',
    (WidgetTester tester,
  ) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(groupInfo: buildGroup(memberCount: null)),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        routes: buildTextRoutes(<String>['/group-detail']),
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.textContaining('Team Alpha').first);
      await tester.pumpAndSettle();

      expect(find.text('group-detail'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.text('\u6211\u7684\u5165\u7fa4\u7533\u8bf7'), findsOneWidget);
      expect(find.text('\u6211\u7684\u7fa4\u7ec4'), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
    },
  );

  testWidgets('GroupListScreen should open search group dialog', (
    WidgetTester tester,
  ) async {
    final provider = buildGroupListProvider();

    await pumpGroupListScreenApp(
      tester,
      groupProvider: provider,
      home: const GroupListScreen(),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets(
    'GroupListScreen search group dialog uses SearchUx hint and empty validation',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider();

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final TextField field = tester.widget<TextField>(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
      );
      expect(field.decoration?.hintText, SearchUxStrings.hintGroupBusinessId);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byIcon(Icons.search),
        ),
      );
      await tester.pump();

      expect(find.text(SearchUxStrings.errorGroupIdRequired), findsOneWidget);
    },
  );

  testWidgets('GroupListScreen should close search group dialog', (
    WidgetTester tester,
  ) async {
    final provider = buildGroupListProvider();

    await pumpGroupListScreenApp(
      tester,
      groupProvider: provider,
      home: const GroupListScreen(),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('\u5173\u95ed'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'GroupListScreen should keep main state after closing search dialog',
    (WidgetTester tester,
  ) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(groupInfo: buildGroup(memberCount: null)),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u5173\u95ed'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.text('\u6211\u7684\u5165\u7fa4\u7533\u8bf7'), findsOneWidget);
      expect(find.text('\u6211\u7684\u7fa4\u7ec4'), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
    },
  );

  testWidgets(
    'GroupListScreen should reopen search dialog with empty input after closing',
    (WidgetTester tester,
  ) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(groupInfo: buildGroup(memberCount: null)),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '90001');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '90001',
      );

      await tester.tap(find.text('\u5173\u95ed'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final groupIdField = tester.widget<TextField>(find.byType(TextField));
      expect(groupIdField.controller?.text ?? '', isEmpty);
    },
  );

  testWidgets('GroupListScreen should open create group dialog', (
    WidgetTester tester,
  ) async {
    final provider = buildGroupListProvider();

    await pumpGroupListScreenApp(
      tester,
      groupProvider: provider,
      home: const GroupListScreen(),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets(
    'GroupListScreen should validate empty group name in create dialog',
    (WidgetTester tester,
  ) async {
      final provider = buildGroupListProvider();

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u521b\u5efa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u8bf7\u8f93\u5165\u7fa4\u540d\u79f0'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should create group with feedback and updated list',
    (WidgetTester tester,
  ) async {
      final provider = buildGroupListProvider(
        groups: const <GroupDTO>[],
        requests: const <GroupJoinRequestDTO>[],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'New Team');
      await tester.enterText(find.byType(TextField).at(1), 'Fresh group');
      await tester.tap(find.text('\u521b\u5efa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u7fa4\u804a\u5df2\u521b\u5efa'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsNothing);
      expect(find.textContaining('New Team'), findsOneWidget);
      expect(find.textContaining('Fresh group'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should keep created group after entering detail and returning',
    (WidgetTester tester,
  ) async {
      final provider = buildGroupListProvider(
        groups: const <GroupDTO>[],
        requests: const <GroupJoinRequestDTO>[],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        routes: buildTextRoutes(<String>['/group-detail']),
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'New Team');
      await tester.enterText(find.byType(TextField).at(1), 'Fresh group');
      await tester.tap(find.text('\u521b\u5efa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('New Team'), findsOneWidget);

      await tester.tap(find.textContaining('New Team'));
      await tester.pumpAndSettle();

      expect(find.text('group-detail'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.textContaining('New Team'), findsOneWidget);
      expect(find.textContaining('Fresh group'), findsOneWidget);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsNothing);
    },
  );

  testWidgets(
    'GroupListScreen should keep created group after refresh',
    (WidgetTester tester,
  ) async {
      final provider = buildGroupListProvider(
        groups: const <GroupDTO>[],
        requests: const <GroupJoinRequestDTO>[],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'New Team');
      await tester.enterText(find.byType(TextField).at(1), 'Fresh group');
      await tester.tap(find.text('\u521b\u5efa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('New Team'), findsOneWidget);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.textContaining('New Team'), findsOneWidget);
      expect(find.textContaining('Fresh group'), findsOneWidget);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsNothing);
    },
  );

  testWidgets(
    'GroupListScreen should keep created group after opening and closing search dialog',
    (WidgetTester tester,
  ) async {
      final groupProvider = buildGroupListProvider();

      await pumpGroupListScreenApp(
        tester,
        groupProvider: groupProvider,
        home: const GroupListScreen(),
        routes: buildTextRoutes(<String>['/group-detail']),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'New Team');
      await tester.enterText(find.byType(TextField).at(1), 'Fresh group');
      await tester.tap(find.text('\u521b\u5efa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('New Team'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u5173\u95ed'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.textContaining('New Team'), findsOneWidget);
      expect(find.textContaining('Fresh group'), findsOneWidget);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsNothing);
    },
  );

  testWidgets(
    'GroupListScreen should keep created group after reopening and closing create dialog',
    (WidgetTester tester,
  ) async {
      final groupProvider = buildGroupListProvider();

      await pumpGroupListScreenApp(
        tester,
        groupProvider: groupProvider,
        home: const GroupListScreen(),
        routes: buildTextRoutes(<String>['/group-detail']),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'New Team');
      await tester.enterText(find.byType(TextField).at(1), 'Fresh group');
      await tester.tap(find.text('\u521b\u5efa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('New Team'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.textContaining('New Team'), findsOneWidget);
      expect(find.textContaining('Fresh group'), findsOneWidget);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsNothing);
    },
  );

  testWidgets(
    'GroupListScreen should reopen create dialog with empty inputs after successful creation',
    (WidgetTester tester,
  ) async {
      final groupProvider = buildGroupListProvider();

      await pumpGroupListScreenApp(
        tester,
        groupProvider: groupProvider,
        home: const GroupListScreen(),
        routes: buildTextRoutes(<String>['/group-detail']),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'New Team');
      await tester.enterText(find.byType(TextField).at(1), 'Fresh group');
      await tester.tap(find.text('\u521b\u5efa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('New Team'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextField>(find.byType(TextField).at(0));
      final descField = tester.widget<TextField>(find.byType(TextField).at(1));

      expect(nameField.controller?.text ?? '', isEmpty);
      expect(descField.controller?.text ?? '', isEmpty);
    },
  );

  testWidgets('GroupListScreen should close create group dialog', (
    WidgetTester tester,
  ) async {
    final provider = buildGroupListProvider();

    await pumpGroupListScreenApp(
      tester,
      groupProvider: provider,
      home: const GroupListScreen(),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('\u53d6\u6d88'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'GroupListScreen should keep main state after closing create dialog',
    (WidgetTester tester,
  ) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(groupInfo: buildGroup(memberCount: null)),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.text('\u6211\u7684\u5165\u7fa4\u7533\u8bf7'), findsOneWidget);
      expect(find.text('\u6211\u7684\u7fa4\u7ec4'), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
    },
  );

  testWidgets('GroupListScreen should render empty group state', (
    WidgetTester tester,
  ) async {
    final provider = buildGroupListProvider(
      groups: const <GroupDTO>[],
      requests: const <GroupJoinRequestDTO>[],
    );

    await pumpGroupListScreenApp(
      tester,
      groupProvider: provider,
      home: const GroupListScreen(),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('\u6682\u65e0\u5165\u7fa4\u7533\u8bf7'), findsOneWidget);
    expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsOneWidget);
  });

  testWidgets(
    'GroupListScreen should render join requests without empty group state',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: const <GroupDTO>[],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(groupInfo: buildGroup(memberCount: null)),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('\u6682\u65e0\u5165\u7fa4\u7533\u8bf7'), findsNothing);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
      expect(find.text('\u6211\u7684\u5165\u7fa4\u7533\u8bf7'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should render groups without join request entries',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: const <GroupJoinRequestDTO>[],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('\u6682\u65e0\u5165\u7fa4\u7533\u8bf7'), findsOneWidget);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsNothing);
      expect(find.textContaining('Team Alpha'), findsOneWidget);
      expect(find.text('\u6211\u7684\u7fa4\u7ec4'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should show withdraw feedback and updated status',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: const <GroupDTO>[],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(
            groupInfo: buildGroup(memberCount: null),
            message: 'Please let me join',
          ),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('\u64a4\u56de\u7533\u8bf7'), findsOneWidget);

      await tester.tap(find.text('\u64a4\u56de\u7533\u8bf7'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u786e\u8ba4\u64a4\u56de'));
      await tester.pumpAndSettle();

      expect(find.text('\u5165\u7fa4\u7533\u8bf7\u5df2\u64a4\u56de'), findsOneWidget);
      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);
      expect(find.text('\u64a4\u56de\u7533\u8bf7'), findsNothing);
      expect(find.textContaining('Please let me join'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should keep withdrawn status after refresh',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: const <GroupDTO>[],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(
            groupInfo: buildGroup(memberCount: null),
            message: 'Please let me join',
          ),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('\u64a4\u56de\u7533\u8bf7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4\u64a4\u56de'));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);

      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, 300),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);
      expect(find.text('\u64a4\u56de\u7533\u8bf7'), findsNothing);
      expect(find.textContaining('Please let me join'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should keep withdrawn status after leaving and returning',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(
            groupInfo: buildGroup(memberCount: null),
            message: 'Please let me join',
          ),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        routes: buildTextRoutes(<String>['/group-detail']),
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('\u64a4\u56de\u7533\u8bf7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4\u64a4\u56de'));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);

      await tester.tap(find.text('\u67e5\u770b\u7fa4\u8be6\u60c5').first);
      await tester.pumpAndSettle();
      expect(find.text('group-detail'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);
      expect(find.text('\u64a4\u56de\u7533\u8bf7'), findsNothing);
      expect(find.textContaining('Please let me join'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should keep groups visible after withdrawing last request',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(
            groupInfo: buildGroup(memberCount: null),
            message: 'Please let me join',
          ),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('\u64a4\u56de\u7533\u8bf7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4\u64a4\u56de'));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);
      expect(find.textContaining('Please let me join'), findsOneWidget);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsNothing);
      expect(find.text('\u6211\u7684\u7fa4\u7ec4'), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
    },
  );

  testWidgets(
    'GroupListScreen should keep withdrawn request visible while group section stays empty',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: const <GroupDTO>[],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(
            groupInfo: buildGroup(memberCount: null),
            message: 'Please let me join',
          ),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('\u64a4\u56de\u7533\u8bf7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4\u64a4\u56de'));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);
      expect(find.textContaining('Please let me join'), findsOneWidget);
      expect(find.text('\u6682\u65e0\u5165\u7fa4\u7533\u8bf7'), findsNothing);
      expect(find.text('\u6682\u65e0\u7fa4\u7ec4'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should keep withdrawn status after opening and closing search dialog',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(
            groupInfo: buildGroup(memberCount: null),
            message: 'Please let me join',
          ),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('\u64a4\u56de\u7533\u8bf7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4\u64a4\u56de'));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u5173\u95ed'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);
      expect(find.text('\u64a4\u56de\u7533\u8bf7'), findsNothing);
      expect(find.textContaining('Please let me join'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupListScreen should keep withdrawn status after opening and closing create dialog',
    (WidgetTester tester) async {
      final provider = buildGroupListProvider(
        groups: <GroupDTO>[buildGroup()],
        requests: <GroupJoinRequestDTO>[
          buildJoinRequest(
            groupInfo: buildGroup(memberCount: null),
            message: 'Please let me join',
          ),
        ],
      );

      await pumpGroupListScreenApp(
        tester,
        groupProvider: provider,
        home: const GroupListScreen(),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('\u64a4\u56de\u7533\u8bf7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u786e\u8ba4\u64a4\u56de'));
      await tester.pumpAndSettle();

      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupListScreen), findsOneWidget);
      expect(find.text('\u5df2\u64a4\u56de'), findsOneWidget);
      expect(find.text('\u64a4\u56de\u7533\u8bf7'), findsNothing);
      expect(find.textContaining('Please let me join'), findsOneWidget);
    },
  );
}
