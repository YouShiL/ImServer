import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';

void main() {
  group('groupMemberRoleLabel', () {
    test('maps owner/admin/member roles', () {
      expect(ProfileDisplayTexts.groupMemberRoleLabel(1), '群主');
      expect(ProfileDisplayTexts.groupMemberRoleLabel(2), '管理员');
      expect(ProfileDisplayTexts.groupMemberRoleLabel(3), '普通成员');
      expect(ProfileDisplayTexts.groupMemberRoleLabel(null), '普通成员');
    });
  });

  group('groupMemberListSubtitle', () {
    test('includes role, optional mute, and userId using userInfo.userId', () {
      final GroupMemberDTO member = GroupMemberDTO(
        userId: 100,
        role: 1,
        isMute: false,
        userInfo: UserDTO(id: 100, userId: 'P100', nickname: 'N1'),
      );
      expect(
        ProfileDisplayTexts.groupMemberListSubtitle(member),
        '用户号：P100',
      );
    });

    test('falls back to numeric member.userId when userInfo.userId absent', () {
      final GroupMemberDTO member = GroupMemberDTO(
        userId: 42,
        role: 3,
        nickname: '仅昵称',
      );
      expect(
        ProfileDisplayTexts.groupMemberListSubtitle(member),
        '用户号：42',
      );
    });

    test('shows mute segment for admin role', () {
      final GroupMemberDTO member = GroupMemberDTO(
        userId: 2,
        role: 2,
        isMute: true,
        userInfo: UserDTO(id: 2, userId: 'a2', nickname: 'Ad'),
      );
      expect(
        ProfileDisplayTexts.groupMemberListSubtitle(member),
        '已被禁言 | 用户号：a2',
      );
    });

    test('uses accountIdLine placeholder when no user id available', () {
      final GroupMemberDTO member = GroupMemberDTO(role: 3);
      expect(
        ProfileDisplayTexts.groupMemberListSubtitle(member),
        '用户号：-',
      );
    });
  });

  group('joinRequestApplicantSubtitle', () {
    test('prefers userInfo.userId then appends trimmed message', () {
      expect(
        ProfileDisplayTexts.joinRequestApplicantSubtitle(
          userInfo: UserDTO(id: 7, userId: 'U7', nickname: 'A'),
          userIdFallback: 999,
          message: '  你好  ',
        ),
        '用户号：U7 | 你好',
      );
    });

    test('falls back to userIdFallback when userInfo missing string id', () {
      expect(
        ProfileDisplayTexts.joinRequestApplicantSubtitle(
          userInfo: null,
          userIdFallback: 88,
          message: null,
        ),
        '用户号：88',
      );
    });
  });

  group('userDetailSnapshotFromGroupMember', () {
    test('returns embedded userInfo when present', () {
      final UserDTO embedded =
          UserDTO(id: 5, userId: 'e5', nickname: 'Emb');
      final GroupMemberDTO member = GroupMemberDTO(
        userId: 5,
        userInfo: embedded,
        nickname: 'ignored',
      );
      expect(
        ProfileDisplayTexts.userDetailSnapshotFromGroupMember(member),
        same(embedded),
      );
    });

    test('returns nickname-only UserDTO when no userInfo', () {
      final GroupMemberDTO member = GroupMemberDTO(
        userId: 9,
        nickname: '群内名',
      );
      final UserDTO? s =
          ProfileDisplayTexts.userDetailSnapshotFromGroupMember(member);
      expect(s!.id, 9);
      expect(s.nickname, '群内名');
    });

    test('returns id-only UserDTO when no nickname', () {
      final GroupMemberDTO member = GroupMemberDTO(userId: 3);
      final UserDTO? s =
          ProfileDisplayTexts.userDetailSnapshotFromGroupMember(member);
      expect(s!.id, 3);
      expect(s.nickname, isNull);
    });

    test('returns null when userId missing', () {
      final GroupMemberDTO member = GroupMemberDTO(
        nickname: 'x',
        userInfo: UserDTO(id: 1, nickname: 'y'),
      );
      expect(
        ProfileDisplayTexts.userDetailSnapshotFromGroupMember(member),
        isNull,
      );
    });
  });

  group('userDetailSnapshotFromApplicant', () {
    test('returns null when userId null', () {
      expect(
        ProfileDisplayTexts.userDetailSnapshotFromApplicant(
          userId: null,
          userInfo: UserDTO(id: 1, nickname: 'a'),
        ),
        isNull,
      );
    });

    test('returns userInfo when provided', () {
      final UserDTO u = UserDTO(id: 12, userId: 'u12', nickname: 'Q');
      expect(
        ProfileDisplayTexts.userDetailSnapshotFromApplicant(
          userId: 12,
          userInfo: u,
        ),
        same(u),
      );
    });

    test('returns UserDTO id-only when userInfo null', () {
      final UserDTO? s =
          ProfileDisplayTexts.userDetailSnapshotFromApplicant(
        userId: 34,
        userInfo: null,
      );
      expect(s!.id, 34);
      expect(s.nickname, isNull);
    });
  });

  group('joinRequestApplicantTitle', () {
    test('uses displayName when userInfo present', () {
      expect(
        ProfileDisplayTexts.joinRequestApplicantTitle(
          GroupJoinRequestDTO(
            id: 1,
            userId: 9,
            userInfo: UserDTO(id: 9, userId: 'u9', nickname: '申请人'),
          ),
        ),
        '申请人',
      );
    });

    test('uses userId digits when userInfo absent', () {
      expect(
        ProfileDisplayTexts.joinRequestApplicantTitle(
          GroupJoinRequestDTO(id: 2, userId: 88, userInfo: null),
        ),
        '88',
      );
    });

    test('returns unset when neither userInfo nor userId', () {
      expect(
        ProfileDisplayTexts.joinRequestApplicantTitle(
          GroupJoinRequestDTO(id: 3, userInfo: null),
        ),
        ProfileDisplayTexts.unset,
      );
    });
  });

  group('groupMemberTitle (title source lock)', () {
    test('uses userInfo displayName over member nickname', () {
      final GroupMemberDTO member = GroupMemberDTO(
        userId: 1,
        nickname: '群内昵称',
        userInfo: UserDTO(
          id: 1,
          userId: 'uid',
          nickname: '资料昵称',
        ),
      );
      expect(ProfileDisplayTexts.groupMemberTitle(member), '资料昵称');
    });
  });
}
