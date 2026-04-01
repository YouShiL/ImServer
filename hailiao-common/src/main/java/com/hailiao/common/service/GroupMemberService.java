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
                .orElseThrow(() -> new RuntimeException("\u4f60\u4e0d\u662f\u7fa4\u6210\u5458"));

        if (member.getRole() != null && (member.getRole() == ROLE_OWNER || member.getRole() == ROLE_ADMIN)) {
            return true;
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));
        return Boolean.TRUE.equals(group.getAllowMemberInvite());
    }

    @Transactional
    public void setGroupAdmin(Long groupId, Long userId, Long operatorId) {
        if (!isGroupOwner(groupId, operatorId)) {
            throw new RuntimeException("\u53ea\u6709\u7fa4\u4e3b\u53ef\u4ee5\u8bbe\u7f6e\u7ba1\u7406\u5458");
        }

        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("\u76ee\u6807\u7528\u6237\u4e0d\u662f\u7fa4\u6210\u5458"));
        member.setRole(ROLE_ADMIN);
        groupMemberRepository.save(member);
    }

    @Transactional
    public void removeGroupAdmin(Long groupId, Long userId, Long operatorId) {
        if (!isGroupOwner(groupId, operatorId)) {
            throw new RuntimeException("\u53ea\u6709\u7fa4\u4e3b\u53ef\u4ee5\u53d6\u6d88\u7ba1\u7406\u5458");
        }

        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("\u76ee\u6807\u7528\u6237\u4e0d\u662f\u7fa4\u6210\u5458"));
        member.setRole(ROLE_MEMBER);
        groupMemberRepository.save(member);
    }

    @Transactional
    public void transferOwnership(Long groupId, Long newOwnerId, Long operatorId) {
        if (!isGroupOwner(groupId, operatorId)) {
            throw new RuntimeException("\u53ea\u6709\u7fa4\u4e3b\u53ef\u4ee5\u8f6c\u8ba9\u7fa4\u4e3b\u8eab\u4efd");
        }

        GroupMember currentOwner = groupMemberRepository.findByGroupIdAndUserId(groupId, operatorId)
                .orElseThrow(() -> new RuntimeException("\u5f53\u524d\u7fa4\u4e3b\u4e0d\u5728\u7fa4\u7ec4\u4e2d"));
        GroupMember newOwner = groupMemberRepository.findByGroupIdAndUserId(groupId, newOwnerId)
                .orElseThrow(() -> new RuntimeException("\u76ee\u6807\u7528\u6237\u4e0d\u662f\u7fa4\u6210\u5458"));

        currentOwner.setRole(ROLE_MEMBER);
        newOwner.setRole(ROLE_OWNER);
        groupMemberRepository.save(currentOwner);
        groupMemberRepository.save(newOwner);

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));
        group.setOwnerId(newOwnerId);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    @Transactional
    public void muteMember(Long groupId, Long userId, Long operatorId, Integer muteMinutes) {
        if (!isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("\u53ea\u6709\u7ba1\u7406\u5458\u53ef\u4ee5\u7981\u8a00\u6210\u5458");
        }

        GroupMember operator = groupMemberRepository.findByGroupIdAndUserId(groupId, operatorId)
                .orElseThrow(() -> new RuntimeException("\u64cd\u4f5c\u8005\u4e0d\u662f\u7fa4\u6210\u5458"));
        GroupMember target = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("\u76ee\u6807\u7528\u6237\u4e0d\u662f\u7fa4\u6210\u5458"));

        if (target.getRole() != null && operator.getRole() != null && target.getRole() <= operator.getRole()) {
            throw new RuntimeException("\u4e0d\u80fd\u7981\u8a00\u6743\u9650\u76f8\u540c\u6216\u66f4\u9ad8\u7684\u6210\u5458");
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
            throw new RuntimeException("\u53ea\u6709\u7ba1\u7406\u5458\u53ef\u4ee5\u89e3\u9664\u7981\u8a00");
        }

        GroupMember target = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("\u76ee\u6807\u7528\u6237\u4e0d\u662f\u7fa4\u6210\u5458"));
        target.setIsMute(false);
        target.setMuteUntil(null);
        groupMemberRepository.save(target);
    }

    @Transactional
    public void muteAll(Long groupId, Long operatorId, boolean mute) {
        if (!isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("\u53ea\u6709\u7ba1\u7406\u5458\u53ef\u4ee5\u4fee\u6539\u5168\u5458\u7981\u8a00");
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));
        group.setMuteAll(mute);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    public boolean canSendGroupMessage(Long groupId, Long userId) {
        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));

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
            throw new RuntimeException("\u53ea\u6709\u7ba1\u7406\u5458\u53ef\u4ee5\u4fee\u6539\u7fa4\u516c\u544a");
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));
        group.setNotice(notice);
        group.setNoticeUpdatedAt(new Date());
        group.setNoticeUpdatedBy(operatorId);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    @Transactional
    public void kickMember(Long groupId, Long userId, Long operatorId) {
        if (!isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("\u53ea\u6709\u7ba1\u7406\u5458\u53ef\u4ee5\u79fb\u9664\u6210\u5458");
        }

        GroupMember operator = groupMemberRepository.findByGroupIdAndUserId(groupId, operatorId)
                .orElseThrow(() -> new RuntimeException("\u64cd\u4f5c\u8005\u4e0d\u662f\u7fa4\u6210\u5458"));
        GroupMember target = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("\u76ee\u6807\u7528\u6237\u4e0d\u662f\u7fa4\u6210\u5458"));

        if (target.getRole() != null && operator.getRole() != null && target.getRole() <= operator.getRole()) {
            throw new RuntimeException("\u4e0d\u80fd\u79fb\u9664\u6743\u9650\u76f8\u540c\u6216\u66f4\u9ad8\u7684\u6210\u5458");
        }

        groupMemberRepository.delete(target);

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));
        group.setMemberCount(Math.max(0, (group.getMemberCount() != null ? group.getMemberCount() : 1) - 1));
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    @Transactional
    public void joinGroup(Long groupId, Long userId) {
        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            throw new RuntimeException("\u4f60\u5df2\u662f\u7fa4\u6210\u5458");
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));

        if (group.getMemberCount() != null
                && group.getMaxMemberCount() != null
                && group.getMemberCount() >= group.getMaxMemberCount()) {
            throw new RuntimeException("\u7fa4\u6210\u5458\u6570\u91cf\u5df2\u8fbe\u4e0a\u9650");
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
                .orElseThrow(() -> new RuntimeException("\u4f60\u4e0d\u662f\u7fa4\u6210\u5458"));

        if (member.getRole() != null && member.getRole() == ROLE_OWNER) {
            throw new RuntimeException("\u7fa4\u4e3b\u9000\u51fa\u524d\u8bf7\u5148\u8f6c\u8ba9\u7fa4\u4e3b\u8eab\u4efd");
        }

        groupMemberRepository.delete(member);

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));
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
