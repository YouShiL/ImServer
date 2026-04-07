import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/screens/group_detail_screen.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';

import '../support/auth_test_fakes.dart';
import '../support/detail_screen_test_fakes.dart';
import '../support/screen_test_helpers.dart';

/// 在默认两成员之外，追加仅含群内 nickname、无 [userInfo] 的成员，用于路由快照 shape 测试。
class _NicknameOnlyExtraMemberGroupApi extends FakeGroupDetailGroupApi {
  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) async {
    return ResponseDTO<List<GroupMemberDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupMemberDTO>[
        GroupMemberDTO(
          id: 1,
          groupId: groupId,
          userId: 1,
          role: 1,
          userInfo: UserDTO(id: 1, userId: 'u1', nickname: 'Owner'),
        ),
        GroupMemberDTO(
          id: 2,
          groupId: groupId,
          userId: 2,
          role: 3,
          userInfo: UserDTO(id: 2, userId: 'u2', nickname: 'Member'),
        ),
        GroupMemberDTO(
          id: 3,
          groupId: groupId,
          userId: 42,
          role: 3,
          nickname: '\u7fa4\u5185\u6635\u79f0',
        ),
      ],
    );
  }
}

/// [getGroupById] 带 [GroupDTO.joinType] == 1，便于展示入群申请区块。
class _JoinVerifyGroupDetailApi extends FakeGroupDetailApi {
  @override
  Future<ResponseDTO<GroupDTO>> getGroupById(int groupId) async {
    return ResponseDTO<GroupDTO>(
      code: 200,
      message: 'ok',
      data: GroupDTO(
        id: groupId,
        groupId: '90001',
        groupName: 'Team Alpha',
        ownerId: 1,
        memberCount: 2,
        joinType: 1,
      ),
    );
  }
}

/// 群成员变更 / 入群审批 API 均返回成功，用于断言 SnackBar 与弹窗文案。
class _GroupMemberOpsSuccessApi extends FakeGroupDetailGroupApi {
  static final ResponseDTO<String> _okString =
      ResponseDTO<String>(code: 200, message: 'ok', data: 'ok');

  @override
  Future<ResponseDTO<String>> setGroupMemberMute(
    int groupId,
    int memberId,
    bool isMute,
  ) async =>
      _okString;

  @override
  Future<ResponseDTO<String>> setGroupAdmin(int groupId, int memberId) async =>
      _okString;

  @override
  Future<ResponseDTO<String>> removeGroupAdmin(int groupId, int memberId) async =>
      _okString;

  @override
  Future<ResponseDTO<String>> transferGroupOwnership(
    int groupId,
    int memberId,
  ) async =>
      _okString;

  @override
  Future<ResponseDTO<String>> removeGroupMember(int groupId, int userId) async =>
      _okString;

  @override
  Future<ResponseDTO<String>> approveGroupJoinRequest(int requestId) async =>
      _okString;

  @override
  Future<ResponseDTO<String>> rejectGroupJoinRequest(int requestId) async =>
      _okString;
}

class _GroupApiWithPendingJoinRequest extends _GroupMemberOpsSuccessApi {
  _GroupApiWithPendingJoinRequest({
    required this.request,
  });

  final GroupJoinRequestDTO request;

  @override
  Future<ResponseDTO<List<GroupJoinRequestDTO>>> getGroupJoinRequests(
    int groupId,
  ) async {
    return ResponseDTO<List<GroupJoinRequestDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupJoinRequestDTO>[request],
    );
  }
}

/// 普通成员初始为禁言，用于「解除禁言」文案断言。
class _GroupMembersMutedTargetApi extends _GroupMemberOpsSuccessApi {
  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) async {
    return ResponseDTO<List<GroupMemberDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupMemberDTO>[
        GroupMemberDTO(
          id: 1,
          groupId: groupId,
          userId: 1,
          role: 1,
          userInfo: UserDTO(id: 1, userId: 'u1', nickname: 'Owner'),
        ),
        GroupMemberDTO(
          id: 2,
          groupId: groupId,
          userId: 2,
          role: 3,
          isMute: true,
          userInfo: UserDTO(id: 2, userId: 'u2', nickname: 'Member'),
        ),
      ],
    );
  }
}

/// 初始即有一名管理员，用于稳定断言「取消管理员」SnackBar（不依赖先 promotion 再撤销的两步状态）。
class _GroupMembersAdminTargetApi extends _GroupMemberOpsSuccessApi {
  @override
  Future<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(int groupId) async {
    return ResponseDTO<List<GroupMemberDTO>>(
      code: 200,
      message: 'ok',
      data: <GroupMemberDTO>[
        GroupMemberDTO(
          id: 1,
          groupId: groupId,
          userId: 1,
          role: 1,
          userInfo: UserDTO(id: 1, userId: 'u1', nickname: 'Owner'),
        ),
        GroupMemberDTO(
          id: 2,
          groupId: groupId,
          userId: 2,
          role: 2,
          userInfo: UserDTO(id: 2, userId: 'u2', nickname: 'Member'),
        ),
      ],
    );
  }
}

Future<void> _pumpOwnerGroupDetail(
  WidgetTester tester,
  GroupProvider groupProvider,
) async {
  await pumpGroupDetailScreenApp(
    tester,
    authProvider: buildDefaultScreenAuthProvider(),
    groupProvider: groupProvider,
    arguments: <String, dynamic>{
      'groupId': 1,
      'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
    },
    builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _openMemberManageMenu(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Member', skipOffstage: false));
  await tester.pump();
  final Finder memberTile = find.ancestor(
    of: find.text('Member'),
    matching: find.byType(ListTile),
  );
  final Finder popup = find.descendant(
    of: memberTile,
    matching: find.byType(PopupMenuButton<String>),
  );
  await tester.tap(popup);
  await tester.pumpAndSettle();
}

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
      arguments: <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Team Alpha'), findsWidgets);
    expect(
      find.textContaining('Owner', skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.textContaining('Member', skipOffstage: false),
      findsWidgets,
    );
    expect(find.text('\u8fdb\u5165\u804a\u5929'), findsOneWidget);
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
      arguments: <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('\u8fdb\u5165\u804a\u5929'));
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
        arguments: <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('\u8fdb\u5165\u804a\u5929'));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await popTopRoute(tester);

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsOneWidget);
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
      arguments: <String, dynamic>{
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
        arguments: <String, dynamic>{
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
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsOneWidget);
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
        arguments: <String, dynamic>{
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
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsOneWidget);
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
        arguments: <String, dynamic>{
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

      await tester.tap(find.text('\u8fdb\u5165\u804a\u5929'));
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await popTopRoute(tester);

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.textContaining('Team Alpha'), findsWidgets);
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsOneWidget);
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
        arguments: <String, dynamic>{
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
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsOneWidget);
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
      arguments: <String, dynamic>{
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
    expect(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'), findsOneWidget);
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
      arguments: <String, dynamic>{
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
        arguments: <String, dynamic>{
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
      expect(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'), findsOneWidget);
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
      arguments: <String, dynamic>{
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

    await tester.tap(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(GroupDetailScreen), findsOneWidget);
    expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
    expect(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'), findsOneWidget);
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
      arguments: <String, dynamic>{
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
        arguments: <String, dynamic>{
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
      expect(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'), findsOneWidget);
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
        arguments: <String, dynamic>{
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

      await tester.tap(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
      expect(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'), findsOneWidget);
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
        arguments: <String, dynamic>{
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
      expect(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'), findsOneWidget);

      Navigator.of(tester.element(find.byType(GroupDetailScreen))).pushNamed('/chat');
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);

      await popTopRoute(tester);

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.text('\u7533\u8bf7\u52a0\u5165'), findsOneWidget);
      expect(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'), findsOneWidget);
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
        arguments: <String, dynamic>{
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
      expect(find.text('\u5237\u65b0\u7fa4\u4fe1\u606f'), findsOneWidget);
      expect(find.byIcon(Icons.how_to_reg), findsOneWidget);
      expect(find.text('\u8fdb\u5165\u804a\u5929'), findsNothing);
    },
  );

  testWidgets(
    'GroupDetailScreen member tap should pass userId and user snapshot from userInfo',
    (WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: FakeGroupDetailGroupApi());
    final List<Object?> captured = <Object?>[];

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      routes: <String, WidgetBuilder>{
        '/user-detail': captureUserDetailArgumentsRoute(captured),
      },
      arguments: <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Finder memberTitle = find.text('Member', skipOffstage: false);
    await tester.ensureVisible(memberTitle);
    await tester.pump();
    await tester.tap(memberTitle);
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    final Object? raw = captured.single;
    expect(raw, isA<Map<String, dynamic>>());
    final Map<String, dynamic> m = raw! as Map<String, dynamic>;
    expect(m['userId'], 2);
    expect(m['user'], isA<UserDTO>());
    final UserDTO u = m['user'] as UserDTO;
    expect(u.id, 2);
    expect(u.nickname, 'Member');
  });

  testWidgets(
    'GroupDetailScreen member without userInfo should pass userId and nickname-only snapshot',
    (WidgetTester tester,
  ) async {
    final authProvider = buildDefaultScreenAuthProvider();
    final groupProvider = GroupProvider(api: _NicknameOnlyExtraMemberGroupApi());
    final List<Object?> captured = <Object?>[];

    await pumpGroupDetailScreenApp(
      tester,
      authProvider: authProvider,
      groupProvider: groupProvider,
      routes: <String, WidgetBuilder>{
        '/user-detail': captureUserDetailArgumentsRoute(captured),
      },
      arguments: <String, dynamic>{
        'groupId': 1,
        'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
      },
      builder: (_) => GroupDetailScreen(api: FakeGroupDetailApi()),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Finder nickFinder =
        find.text('\u7fa4\u5185\u6635\u79f0', skipOffstage: false);
    await tester.ensureVisible(nickFinder);
    await tester.pump();
    await tester.tap(nickFinder);
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    final Map<String, dynamic> m = captured.single! as Map<String, dynamic>;
    expect(m['userId'], 42);
    expect(m['user'], isA<UserDTO>());
    final UserDTO u = m['user'] as UserDTO;
    expect(u.id, 42);
    expect(u.nickname, '\u7fa4\u5185\u6635\u79f0');
  });

  testWidgets(
    'GroupDetailScreen join request row shows applicant subtitle and opens user-detail',
    (WidgetTester tester) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final GroupJoinRequestDTO request = GroupJoinRequestDTO(
        id: 501,
        userId: 77,
        message: '\u7533\u8bf7\u9644\u8a00A',
        userInfo: UserDTO(
          id: 77,
          userId: 'pretty77',
          nickname: '\u7533\u8bf7\u4ebaA',
        ),
      );
      final groupProvider =
          GroupProvider(api: _GroupApiWithPendingJoinRequest(request: request));
      final List<Object?> captured = <Object?>[];

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        routes: <String, WidgetBuilder>{
          '/user-detail': captureUserDetailArgumentsRoute(captured),
        },
        arguments: <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: _JoinVerifyGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final Finder joinSectionTitle =
          find.text('\u5165\u7fa4\u7533\u8bf7', skipOffstage: false);
      expect(joinSectionTitle, findsOneWidget);
      await tester.ensureVisible(joinSectionTitle);
      await tester.pump();

      final String expectedSubtitle =
          ProfileDisplayTexts.joinRequestApplicantSubtitle(
        userInfo: request.userInfo,
        userIdFallback: request.userId,
        message: request.message,
      );
      expect(find.text(expectedSubtitle, skipOffstage: false), findsOneWidget);

      final Finder applicantTitle =
          find.text('\u7533\u8bf7\u4ebaA', skipOffstage: false);
      await tester.ensureVisible(applicantTitle);
      await tester.pump();
      await tester.tap(applicantTitle);
      await tester.pumpAndSettle();

      expect(captured, hasLength(1));
      final Map<String, dynamic> m = captured.single! as Map<String, dynamic>;
      expect(m['userId'], 77);
      expect(m['user'], isA<UserDTO>());
      expect(identical(m['user'] as UserDTO, request.userInfo), isTrue);
    },
  );

  testWidgets(
    'GroupDetailScreen join request without userInfo still opens user-detail id snapshot',
    (WidgetTester tester) async {
      final authProvider = buildDefaultScreenAuthProvider();
      final GroupJoinRequestDTO request = GroupJoinRequestDTO(
        id: 502,
        userId: 88,
        message: null,
        userInfo: null,
      );
      final groupProvider =
          GroupProvider(api: _GroupApiWithPendingJoinRequest(request: request));
      final List<Object?> captured = <Object?>[];

      await pumpGroupDetailScreenApp(
        tester,
        authProvider: authProvider,
        groupProvider: groupProvider,
        routes: <String, WidgetBuilder>{
          '/user-detail': captureUserDetailArgumentsRoute(captured),
        },
        arguments: <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: _JoinVerifyGroupDetailApi()),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.ensureVisible(
        find.text('\u5165\u7fa4\u7533\u8bf7', skipOffstage: false),
      );
      await tester.pump();

      final String expectedSubtitle =
          ProfileDisplayTexts.joinRequestApplicantSubtitle(
        userInfo: null,
        userIdFallback: 88,
        message: null,
      );
      expect(find.text(expectedSubtitle, skipOffstage: false), findsOneWidget);

      await tester.ensureVisible(find.text('88', skipOffstage: false));
      await tester.pump();
      await tester.tap(find.text('88'));
      await tester.pumpAndSettle();

      expect(captured, hasLength(1));
      final Map<String, dynamic> m = captured.single! as Map<String, dynamic>;
      expect(m['userId'], 88);
      expect(m['user'], isA<UserDTO>());
      final UserDTO u = m['user'] as UserDTO;
      expect(u.id, 88);
      expect(u.nickname, isNull);
    },
  );

  testWidgets(
    'GroupDetailScreen transfer ownership dialog and success snackbar name',
    (WidgetTester tester) async {
      final groupProvider = GroupProvider(api: _GroupMemberOpsSuccessApi());
      await _pumpOwnerGroupDetail(tester, groupProvider);
      await _openMemberManageMenu(tester);
      await tester.tap(find.text('\u8f6c\u8ba9\u7fa4\u4e3b'));
      await tester.pumpAndSettle();
      expect(
        find.text('\u786e\u8ba4\u5c06\u7fa4\u4e3b\u8eab\u4efd\u8f6c\u8ba9\u7ed9\u300cMember\u300d\u5417\uff1f'),
        findsOneWidget,
      );
      await tester.tap(find.text('\u786e\u8ba4\u8f6c\u8ba9'));
      await tester.pumpAndSettle();
      expect(
        find.text('\u5df2\u5c06\u7fa4\u4e3b\u8f6c\u8ba9\u7ed9\u300cMember\u300d'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GroupDetailScreen remove member dialog and success snackbar name',
    (WidgetTester tester) async {
      final groupProvider = GroupProvider(api: _GroupMemberOpsSuccessApi());
      await _pumpOwnerGroupDetail(tester, groupProvider);
      await _openMemberManageMenu(tester);
      await tester.tap(find.text('\u79fb\u9664\u6210\u5458'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('\u5c06\u300cMember\u300d\u4ece\u672c\u7fa4\u79fb\u51fa'),
        findsOneWidget,
      );
      await tester.tap(find.text('\u79fb\u51fa\u7fa4\u7ec4'));
      await tester.pumpAndSettle();
      expect(
        find.text('\u5df2\u5c06\u300cMember\u300d\u79fb\u51fa\u7fa4\u7ec4'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GroupDetailScreen mute snackbar uses groupMemberTitle',
    (WidgetTester tester) async {
      final groupProvider = GroupProvider(api: _GroupMemberOpsSuccessApi());
      await _pumpOwnerGroupDetail(tester, groupProvider);
      await _openMemberManageMenu(tester);
      await tester.tap(find.text('\u8bbe\u7f6e\u7981\u8a00'));
      await tester.pumpAndSettle();
      expect(find.text('\u5df2\u5bf9\u300cMember\u300d\u7981\u8a00'), findsOneWidget);
    },
  );

  testWidgets(
    'GroupDetailScreen unmute from initial muted member uses groupMemberTitle',
    (WidgetTester tester) async {
      final groupProvider = GroupProvider(api: _GroupMembersMutedTargetApi());
      await _pumpOwnerGroupDetail(tester, groupProvider);
      await _openMemberManageMenu(tester);
      await tester.tap(find.text('\u89e3\u9664\u7981\u8a00'));
      await tester.pumpAndSettle();
      expect(
        find.text('\u5df2\u89e3\u9664\u300cMember\u300d\u7684\u7981\u8a00'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GroupDetailScreen grant admin snackbar uses groupMemberTitle',
    (WidgetTester tester) async {
      final groupProvider = GroupProvider(api: _GroupMemberOpsSuccessApi());
      await _pumpOwnerGroupDetail(tester, groupProvider);
      await _openMemberManageMenu(tester);
      await tester.tap(find.text('\u8bbe\u4e3a\u7ba1\u7406\u5458'));
      await tester.pumpAndSettle();
      expect(
        find.text('\u5df2\u5c06\u300cMember\u300d\u8bbe\u4e3a\u7ba1\u7406\u5458'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GroupDetailScreen revoke admin snackbar uses groupMemberTitle',
    (WidgetTester tester) async {
      final groupProvider = GroupProvider(api: _GroupMembersAdminTargetApi());
      await _pumpOwnerGroupDetail(tester, groupProvider);
      await _openMemberManageMenu(tester);
      await tester.tap(find.text('\u53d6\u6d88\u7ba1\u7406\u5458'));
      await tester.pumpAndSettle();
      expect(
        find.text('\u5df2\u53d6\u6d88\u300cMember\u300d\u7684\u7ba1\u7406\u5458\u8eab\u4efd'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GroupDetailScreen approve join request snackbar matches joinRequestApplicantTitle',
    (WidgetTester tester) async {
      final GroupJoinRequestDTO request = GroupJoinRequestDTO(
        id: 601,
        userId: 701,
        message: 'm',
        userInfo: UserDTO(
          id: 701,
          userId: 'u701',
          nickname: '\u7533\u8bf7\u4ebaOps',
        ),
      );
      final String who =
          ProfileDisplayTexts.joinRequestApplicantTitle(request);
      expect(who, '\u7533\u8bf7\u4ebaOps');
      final groupProvider =
          GroupProvider(api: _GroupApiWithPendingJoinRequest(request: request));
      await pumpGroupDetailScreenApp(
        tester,
        authProvider: buildDefaultScreenAuthProvider(),
        groupProvider: groupProvider,
        arguments: <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: _JoinVerifyGroupDetailApi()),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.ensureVisible(
        find.text('\u5165\u7fa4\u7533\u8bf7', skipOffstage: false),
      );
      await tester.pump();
      await tester.tap(find.text('\u540c\u610f'));
      await tester.pumpAndSettle();
      expect(
        find.text('\u5df2\u540c\u610f\u300c$who\u300d\u7684\u5165\u7fa4\u7533\u8bf7'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GroupDetailScreen reject join request snackbar matches joinRequestApplicantTitle',
    (WidgetTester tester) async {
      final GroupJoinRequestDTO request = GroupJoinRequestDTO(
        id: 602,
        userId: 702,
        userInfo: UserDTO(
          id: 702,
          userId: 'u702',
          nickname: '\u62d2\u7edd\u6d4b\u8bd5',
        ),
      );
      final String who =
          ProfileDisplayTexts.joinRequestApplicantTitle(request);
      final groupProvider =
          GroupProvider(api: _GroupApiWithPendingJoinRequest(request: request));
      await pumpGroupDetailScreenApp(
        tester,
        authProvider: buildDefaultScreenAuthProvider(),
        groupProvider: groupProvider,
        arguments: <String, dynamic>{
          'groupId': 1,
          'group': GroupDTO(id: 1, groupId: '90001', groupName: 'Team Alpha'),
        },
        builder: (_) => GroupDetailScreen(api: _JoinVerifyGroupDetailApi()),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.ensureVisible(
        find.text('\u5165\u7fa4\u7533\u8bf7', skipOffstage: false),
      );
      await tester.pump();
      await tester.tap(find.text('\u62d2\u7edd'));
      await tester.pumpAndSettle();
      expect(
        find.text('\u5df2\u62d2\u7edd\u300c$who\u300d\u7684\u5165\u7fa4\u7533\u8bf7'),
        findsOneWidget,
      );
    },
  );
}
