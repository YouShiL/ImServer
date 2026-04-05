import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/theme/group_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/badge_tag.dart';

class GroupMemberPreviewStrip extends StatelessWidget {
  const GroupMemberPreviewStrip({
    super.key,
    required this.members,
    required this.totalCount,
    this.onInvite,
    this.canInvite = false,
  });

  final List<GroupMemberDTO> members;
  final int totalCount;
  final VoidCallback? onInvite;
  final bool canInvite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GroupUiTokens.memberPreviewStripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.take(8).length + 1 + (canInvite ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(
          width: GroupUiTokens.memberPreviewGap,
        ),
        itemBuilder: (BuildContext context, int index) {
          final int previewCount = members.take(8).length;
          if (index < previewCount) {
            return _MemberAvatar(member: members[index]);
          }
          if (canInvite && index == previewCount) {
            return _ActionTile(
              icon: Icons.person_add_alt_1_rounded,
              label: '邀请',
              onTap: onInvite,
            );
          }
          return _CountTile(totalCount: totalCount);
        },
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final GroupMemberDTO member;

  @override
  Widget build(BuildContext context) {
    final String nickname =
        member.userInfo?.nickname ?? member.nickname ?? '成员';
    final String initial = nickname.isNotEmpty ? nickname.substring(0, 1) : '群';
    final String role = switch (member.role) {
      1 => '群主',
      2 => '管理员',
      _ => '成员',
    };

    return SizedBox(
      width: 62,
      child: Column(
        children: <Widget>[
          Container(
            width: GroupUiTokens.memberPreviewAvatarSize,
            height: GroupUiTokens.memberPreviewAvatarSize,
            decoration: BoxDecoration(
              color: GroupUiTokens.memberAvatarBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GroupUiTokens.memberAvatarBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GroupUiTokens.sectionTitleText.copyWith(
                color: GroupUiTokens.memberAvatarText,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GroupUiTokens.memberNameText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GroupUiTokens.memberRoleText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Container(
              width: GroupUiTokens.memberPreviewAvatarSize,
              height: GroupUiTokens.memberPreviewAvatarSize,
              decoration: BoxDecoration(
                color: GroupUiTokens.chipAccentBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: GroupUiTokens.chipAccentText,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GroupUiTokens.memberNameText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          BadgeTag(
            label: '$totalCount 人',
            backgroundColor: GroupUiTokens.chipBackground,
            textColor: GroupUiTokens.chipText,
          ),
          const SizedBox(height: 10),
          Text(
            '查看全部',
            style: GroupUiTokens.memberNameText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
