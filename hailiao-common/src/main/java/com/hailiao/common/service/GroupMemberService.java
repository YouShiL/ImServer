package com.hailiao.common.service;

import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupMember;
import com.hailiao.common.repository.GroupChatRepository;
import com.hailiao.common.repository.GroupMemberRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.Optional;

@Service
public class GroupMemberService {

    public static final int ROLE_OWNER = 1;
    public static final int ROLE_ADMIN = 2;
    public static final int ROLE_MEMBER = 3;

    @Autowired
    private GroupMemberRepository groupMemberRepository;

    @Autowired
    private GroupChatRepository groupChatRepository;

    public boolean isGroupAdmin(Long groupId, Long userId) {
        Optional<GroupMember> member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId);
        return member.isPresent()
                && member.get().getRole() != null
                && (member.get().getRole() == ROLE_OWNER || member.get().getRole() == ROLE_ADMIN);
    }

    public boolean isGroupOwner(Long groupId, Long userId) {
        Optional<GroupMember> member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId);
        return member.isPresent()
                && member.get().getRole() != null
                && member.get().getRole() == ROLE_OWNER;
    }

    public boolean isGroupMember(Long groupId, Long userId) {
        return groupMemberRepository.existsByGroupIdAndUserId(groupId, userId);
    }

    public boolean canInviteMembers(Long groupId, Long userId) {
        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("你不是群成员"));

        if (member.getRole() != null && (member.getRole() == ROLE_OWNER || member.getRole() == ROLE_ADMIN)) {
            return true;
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));
        return Boolean.TRUE.equals(group.getAllowMemberInvite());
    }

    @Transactional
    public void setGroupAdmin(Long groupId, Long userId, Long operatorId) {
        if (!isGroupOwner(groupId, operatorId)) {
            throw new RuntimeException("只有群主可以设置管理员");
        }

        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("目标用户不是群成员"));
        member.setRole(ROLE_ADMIN);
        groupMemberRepository.save(member);
    }

    @Transactional
    public void removeGroupAdmin(Long groupId, Long userId, Long operatorId) {
        if (!isGroupOwner(groupId, operatorId)) {
            throw new RuntimeException("只有群主可以取消管理员");
        }

        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("目标用户不是群成员"));
        member.setRole(ROLE_MEMBER);
        groupMemberRepository.save(member);
    }

    @Transactional
    public void transferOwnership(Long groupId, Long newOwnerId, Long operatorId) {
        if (!isGroupOwner(groupId, operatorId)) {
            throw new RuntimeException("只有群主可以转让群主身份");
        }

        GroupMember currentOwner = groupMemberRepository.findByGroupIdAndUserId(groupId, operatorId)
                .orElseThrow(() -> new RuntimeException("当前群主不在群组中"));
        GroupMember newOwner = groupMemberRepository.findByGroupIdAndUserId(groupId, newOwnerId)
                .orElseThrow(() -> new RuntimeException("目标用户不是群成员"));

        currentOwner.setRole(ROLE_MEMBER);
        newOwner.setRole(ROLE_OWNER);
        groupMemberRepository.save(currentOwner);
        groupMemberRepository.save(newOwner);

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));
        group.setOwnerId(newOwnerId);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    @Transactional
    public void muteMember(Long groupId, Long userId, Long operatorId, Integer muteMinutes) {
        if (!isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("只有管理员可以禁言成员");
        }

        GroupMember operator = groupMemberRepository.findByGroupIdAndUserId(groupId, operatorId)
                .orElseThrow(() -> new RuntimeException("操作者不是群成员"));
        GroupMember target = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("目标用户不是群成员"));

        if (target.getRole() != null && operator.getRole() != null && target.getRole() <= operator.getRole()) {
            throw new RuntimeException("不能禁言权限相同或更高的成员");
        }

        target.setIsMute(true);
        if (muteMinutes != null && muteMinutes > 0) {
            target.setMuteUntil(new Date(System.currentTimeMillis() + muteMinutes * 60 * 1000L));
        } else {
            target.setMuteUntil(null);
        }
        groupMemberRepository.save(target);
    }

    @Transactional
    public void unmuteMember(Long groupId, Long userId, Long operatorId) {
        if (!isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("只有管理员可以解除禁言");
        }

        GroupMember target = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("目标用户不是群成员"));
        target.setIsMute(false);
        target.setMuteUntil(null);
        groupMemberRepository.save(target);
    }

    @Transactional
    public void muteAll(Long groupId, Long operatorId, boolean mute) {
        if (!isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("只有管理员可以修改全员禁言");
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));
        group.setMuteAll(mute);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    public boolean canSendGroupMessage(Long groupId, Long userId) {
        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));

        if (Boolean.TRUE.equals(group.getMuteAll())) {
            return isGroupAdmin(groupId, userId);
        }

        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElse(null);
        if (member == null) {
            return false;
        }

        if (Boolean.TRUE.equals(member.getIsMute())) {
            if (member.getMuteUntil() != null && member.getMuteUntil().before(new Date())) {
                member.setIsMute(false);
                member.setMuteUntil(null);
                groupMemberRepository.save(member);
                return true;
            }
            return false;
        }

        return true;
    }

    @Transactional
    public void updateGroupNotice(Long groupId, Long operatorId, String notice) {
        if (!isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("只有管理员可以修改群公告");
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));
        group.setNotice(notice);
        group.setNoticeUpdatedAt(new Date());
        group.setNoticeUpdatedBy(operatorId);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    @Transactional
    public void kickMember(Long groupId, Long userId, Long operatorId) {
        if (!isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("只有管理员可以移除成员");
        }

        GroupMember operator = groupMemberRepository.findByGroupIdAndUserId(groupId, operatorId)
                .orElseThrow(() -> new RuntimeException("操作者不是群成员"));
        GroupMember target = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("目标用户不是群成员"));

        if (target.getRole() != null && operator.getRole() != null && target.getRole() <= operator.getRole()) {
            throw new RuntimeException("不能移除权限相同或更高的成员");
        }

        groupMemberRepository.delete(target);

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));
        group.setMemberCount(Math.max(0, (group.getMemberCount() != null ? group.getMemberCount() : 1) - 1));
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    @Transactional
    public void joinGroup(Long groupId, Long userId) {
        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            throw new RuntimeException("你已是群成员");
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));

        if (group.getMemberCount() != null
                && group.getMaxMemberCount() != null
                && group.getMemberCount() >= group.getMaxMemberCount()) {
            throw new RuntimeException("群成员数量已达上限");
        }

        GroupMember member = new GroupMember();
        member.setGroupId(groupId);
        member.setUserId(userId);
        member.setRole(ROLE_MEMBER);
        member.setJoinTime(new Date());
        member.setIsMute(false);
        member.setIsTop(false);
        member.setIsMuteNotification(false);
        groupMemberRepository.save(member);

        int currentCount = group.getMemberCount() != null ? group.getMemberCount() : 0;
        group.setMemberCount(currentCount + 1);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    @Transactional
    public void leaveGroup(Long groupId, Long userId) {
        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("你不是群成员"));

        if (member.getRole() != null && member.getRole() == ROLE_OWNER) {
            throw new RuntimeException("群主退出前请先转让群主身份");
        }

        groupMemberRepository.delete(member);

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));
        group.setMemberCount(Math.max(0, (group.getMemberCount() != null ? group.getMemberCount() : 1) - 1));
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    public List<GroupMember> getGroupMembers(Long groupId) {
        return groupMemberRepository.findByGroupId(groupId);
    }

    public List<GroupMember> getGroupAdmins(Long groupId) {
        return groupMemberRepository.findAdminsByGroupId(groupId);
    }

    public Optional<GroupMember> getGroupMember(Long groupId, Long userId) {
        return groupMemberRepository.findByGroupIdAndUserId(groupId, userId);
    }
}
