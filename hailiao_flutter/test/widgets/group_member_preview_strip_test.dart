import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/widgets/group/group_member_preview_strip.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';

import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('preview uses groupMemberTitle under nickname label', (
    WidgetTester tester,
  ) async {
    final GroupMemberDTO member = GroupMemberDTO(
      userId: 1,
      nickname: '群内',
      userInfo: UserDTO(
        id: 1,
        userId: 'u1',
        nickname: '资料页昵称',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupMemberPreviewStrip(
            members: <GroupMemberDTO>[member],
            totalCount: 1,
          ),
        ),
      ),
    );
    expect(find.text(ProfileDisplayTexts.groupMemberTitle(member)), findsOneWidget);
    expect(find.text('资料页昵称'), findsOneWidget);
    expect(find.text('群内'), findsNothing);
  });

  testWidgets('letter avatar path when avatar is not http(s)', (
    WidgetTester tester,
  ) async {
    final GroupMemberDTO member = GroupMemberDTO(
      userId: 2,
      role: 3,
      userInfo: UserDTO(
        id: 2,
        userId: 'u2',
        nickname: '李四',
        avatar: 'ftp://bad.example/a.png',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupMemberPreviewStrip(
            members: <GroupMemberDTO>[member],
            totalCount: 1,
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(
      find.text(ProfileDisplayTexts.listAvatarInitial('李四')),
      findsWidgets,
    );
  });

  testWidgets('network avatar path renders Image when url is https', (
    WidgetTester tester,
  ) async {
    final GroupMemberDTO member = GroupMemberDTO(
      userId: 3,
      userInfo: UserDTO(
        id: 3,
        userId: 'u3',
        nickname: 'Net',
        avatar: 'https://example.com/face.png',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupMemberPreviewStrip(
            members: <GroupMemberDTO>[member],
            totalCount: 1,
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('tap avatar pushes user-detail with userId and snapshot shape', (
    WidgetTester tester,
  ) async {
    final List<Object?> captured = <Object?>[];
    final GroupMemberDTO member = GroupMemberDTO(
      userId: 901,
      nickname: '快照昵称',
    );
    await tester.pumpWidget(
      MaterialApp(
        routes: <String, WidgetBuilder>{
          '/user-detail': captureUserDetailArgumentsRoute(captured),
        },
        home: Scaffold(
          body: GroupMemberPreviewStrip(
            members: <GroupMemberDTO>[member],
            totalCount: 1,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(captured, hasLength(1));
    final Map<String, dynamic> m = captured.single! as Map<String, dynamic>;
    expect(m['userId'], 901);
    expect(m['user'], isA<UserDTO>());
    final UserDTO u = m['user'] as UserDTO;
    expect(u.id, 901);
    expect(u.nickname, '快照昵称');
  });

  testWidgets('null userId does not register navigation when tapping avatar', (
    WidgetTester tester,
  ) async {
    final List<Object?> captured = <Object?>[];
    final GroupMemberDTO member = GroupMemberDTO(
      userInfo: UserDTO(id: 1, nickname: '无uid'),
    );
    await tester.pumpWidget(
      MaterialApp(
        routes: <String, WidgetBuilder>{
          '/user-detail': captureUserDetailArgumentsRoute(captured),
        },
        home: Scaffold(
          body: GroupMemberPreviewStrip(
            members: <GroupMemberDTO>[member],
            totalCount: 1,
          ),
        ),
      ),
    );
    final InkWell ink = tester.widget<InkWell>(find.byType(InkWell).first);
    expect(ink.onTap, isNull);
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(captured, isEmpty);
  });
}
