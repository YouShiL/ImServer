import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/screens/group_detail_screen.dart';

import '../support/auth_test_fakes.dart';
import '../support/detail_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('GroupDetailScreen should render group and member info', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      arguments: const <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Team Alpha'), findsWidgets);
    expect(find.textContaining('Owner'), findsWidgets);
    expect(find.textContaining('Member'), findsWidgets);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('GroupDetailScreen should navigate to group chat', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      routes: buildTextRoutes(<String>['/chat']),
      arguments: const <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();

    expect(find.text('chat'), findsOneWidget);
  });

  testWidgets(
    'GroupDetailScreen should keep detail state after entering chat and returning',
    (WidgetTester tester) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        routes: buildTextRoutes(<String>['/chat']),
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets('GroupDetailScreen should open report dialog', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      arguments: const <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'GroupDetailScreen should keep detail state after closing report dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'GroupDetailScreen should keep detail state after report success',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u7fa4\u7ec4\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);
      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'GroupDetailScreen should keep detail state after report success and returning from chat',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        routes: buildTextRoutes(<String>['/chat']),
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u7fa4\u7ec4\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'GroupDetailScreen should keep detail state after report success and closing report dialog again',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u63d0\u4ea4\u4e3e\u62a5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u7fa4\u7ec4\u4e3e\u62a5\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets('GroupDetailScreen should show join actions for non-member', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      arguments: const <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(
          id: 1,
          groupId: '90001',
          groupName: 'Team Alpha',
          joinType: 1,
        ),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
    expect(find.byIcon(Icons.how_to_reg), findsOneWidget);
    expect(find.text('\u5237\u65b0'), findsOneWidget);
  });

  testWidgets('GroupDetailScreen should open join request dialog for non-member', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      arguments: const <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(
          id: 1,
          groupId: '90001',
          groupName: 'Team Alpha',
          joinType: 1,
        ),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('\u7533\u8bf7\u52a0\u5165'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'GroupDetailScreen should keep non-member state after closing join dialog',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(
            id: 1,
            groupId: '90001',
            groupName: 'Team Alpha',
            joinType: 1,
          ),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u7533\u8bf7\u52a0\u5165'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
      expect(find.text('\u5237\u65b0'), findsOneWidget);
      expect(find.byIcon(Icons.how_to_reg), findsOneWidget);
    },
  );

  testWidgets('GroupDetailScreen should refresh non-member state', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      arguments: const <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(
          id: 1,
          groupId: '90001',
          groupName: 'Team Alpha',
          joinType: 1,
        ),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('\u5237\u65b0'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(GroupDetailScreen), findsOneWidget);
    expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
    expect(find.text('\u5237\u65b0'), findsOneWidget);
  });

  testWidgets('GroupDetailScreen should show join request submitted feedback', (
    WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      arguments: const <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(
          id: 1,
          groupId: '90001',
          groupName: 'Team Alpha',
          joinType: 1,
        ),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('\u7533\u8bf7\u52a0\u5165'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '\u60f3\u52a0\u5165\u4e00\u8d77\u534f\u4f5c',
    );
    await tester.tap(find.text('\u63d0\u4ea4\u7533\u8bf7'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('\u5165\u7fa4\u7533\u8bf7\u5df2\u63d0\u4ea4'), findsOneWidget);
  });

  testWidgets(
    'GroupDetailScreen should keep non-member actions after join request success',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(
            id: 1,
            groupId: '90001',
            groupName: 'Team Alpha',
            joinType: 1,
          ),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u7533\u8bf7\u52a0\u5165'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '\u60f3\u52a0\u5165\u4e00\u8d77\u534f\u4f5c',
      );
      await tester.tap(find.text('\u63d0\u4ea4\u7533\u8bf7'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u5165\u7fa4\u7533\u8bf7\u5df2\u63d0\u4ea4'), findsOneWidget);
      expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
      expect(find.text('\u5237\u65b0'), findsOneWidget);
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsNothing);
      expect(find.text('\u9000\u51fa\u7fa4\u7ec4'), findsNothing);
    },
  );

  testWidgets(
    'GroupDetailScreen should keep non-member state after join request and refresh',
    (WidgetTester tester) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(
            id: 1,
            groupId: '90001',
            groupName: 'Team Alpha',
            joinType: 1,
          ),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u7533\u8bf7\u52a0\u5165'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '\u60f3\u52a0\u5165\u4e00\u8d77\u534f\u4f5c',
      );
      await tester.tap(find.text('\u63d0\u4ea4\u7533\u8bf7'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u5165\u7fa4\u7533\u8bf7\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tester.tap(find.text('\u5237\u65b0'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
      expect(find.text('\u5237\u65b0'), findsOneWidget);
      expect(find.byIcon(Icons.how_to_reg), findsOneWidget);
    },
  );

  testWidgets(
    'GroupDetailScreen should keep non-member state after join request and returning from chat route',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        routes: buildTextRoutes(<String>['/chat']),
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(
            id: 1,
            groupId: '90001',
            groupName: 'Team Alpha',
            joinType: 1,
          ),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u7533\u8bf7\u52a0\u5165'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '\u60f3\u52a0\u5165\u4e00\u8d77\u534f\u4f5c',
      );
      await tester.tap(find.text('\u63d0\u4ea4\u7533\u8bf7'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u5165\u7fa4\u7533\u8bf7\u5df2\u63d0\u4ea4'), findsOneWidget);
      expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
      expect(find.text('\u5237\u65b0'), findsOneWidget);

      Navigator.of(tester.element(find.byType(GroupDetailScreen))).pushNamed('/chat');
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
      expect(find.text('\u5237\u65b0'), findsOneWidget);
      expect(find.byIcon(Icons.how_to_reg), findsOneWidget);
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsNothing);
    },
  );

  testWidgets(
    'GroupDetailScreen should keep non-member state after join request success and closing join dialog again',
    (WidgetTester tester,
  ) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final groupProvider = GroupProvider(api: FakeNonMemberGroupDetailGroupApi());

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        arguments: const <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(
            id: 1,
            groupId: '90001',
            groupName: 'Team Alpha',
            joinType: 1,
          ),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u7533\u8bf7\u52a0\u5165'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '\u60f3\u52a0\u5165\u4e00\u8d77\u534f\u4f5c',
      );
      await tester.tap(find.text('\u63d0\u4ea4\u7533\u8bf7'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('\u5165\u7fa4\u7533\u8bf7\u5df2\u63d0\u4ea4'), findsOneWidget);

      await tester.tap(find.text('\u7533\u8bf7\u52a0\u5165'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('\u53d6\u6d88'));
      await tester.pumpAndSettle();

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
      expect(find.text('\u5237\u65b0'), findsOneWidget);
      expect(find.byIcon(Icons.how_to_reg), findsOneWidget);
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsNothing);
    },
  );
}
