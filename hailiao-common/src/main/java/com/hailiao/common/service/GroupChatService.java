package com.hailiao.common.service;

import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupMember;
import com.hailiao.common.entity.User;
import com.hailiao.common.repository.GroupChatRepository;
import com.hailiao.common.repository.GroupMemberRepository;
import com.hailiao.common.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Random;
import java.util.Set;

/**
 * 群组核心服务，负责建群、成员管理和群设置更新。
 */
@Service
public class GroupChatService {

    @Autowired
    private GroupChatRepository groupChatRepository;

    @Autowired
    private GroupMemberRepository groupMemberRepository;

    @Autowired
    private UserRepository userRepository;

    private boolean canInviteMember(GroupChat group, Long operatorId) {
        if (operatorId == null) {
            return true;
        }

        GroupMember operator = groupMemberRepository.findByGroupIdAndUserId(group.getId(), operatorId)
                .orElseThrow(() -> new RuntimeException("群主不存在"));

        if (operator.getRole() != null && operator.getRole() <= 2) {
            return true;
        }

        return group.getAllowMemberInvite() != null && group.getAllowMemberInvite();
    }

    /**
     * 创建群组，并添加初始成员。
     */
    @Transactional
    public GroupChat createGroup(Long ownerId, String groupName, String description, List<Long> memberIds) {
        User owner = userRepository.findById(ownerId).get();
        
        long groupCount = groupMemberRepository.countByUserId(ownerId);
        if (groupCount >= owner.getGroupLimit()) {
            throw new RuntimeException("创建群组数量已达上限");
        }

        GroupChat group = new GroupChat();
        group.setGroupId(generateGroupId());
        group.setGroupName(groupName);
        group.setOwnerId(ownerId);
        group.setDescription(description);
        group.setAvatar("");
        group.setNotice("");
        group.setMemberCount(1);
        group.setMaxMemberCount(owner.getGroupMemberLimit());
        group.setIsMute(false);
        group.setAllowMemberInvite(true);
        group.setJoinType(0);
        group.setStatus(1);
        group.setCreatedAt(new Date());
        group.setUpdatedAt(new Date());

        GroupChat savedGroup = groupChatRepository.save(group);

        GroupMember ownerMember = new GroupMember();
        ownerMember.setGroupId(savedGroup.getId());
        ownerMember.setUserId(ownerId);
        ownerMember.setRole(1);
        ownerMember.setNickname(owner.getNickname());
        ownerMember.setIsMute(false);
        ownerMember.setJoinTime(new Date());
        groupMemberRepository.save(ownerMember);

        if (memberIds != null) {
            for (Long memberId : memberIds) {
                if (!memberId.equals(ownerId)) {
                    addGroupMember(savedGroup.getId(), memberId, 3);
                }
            }
        }

        return savedGroup;
    }

    /**
     * 根据数据库主键获取群组。
     */
    public GroupChat getGroupById(Long id) {
        return groupChatRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("群组不存在"));
    }

    /**
     * 根据业务群号获取群组。
     */
    public GroupChat getGroupByGroupId(String groupId) {
        return groupChatRepository.findByGroupId(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));
    }

    /**
     * 向群组中添加成员。
     */
    @Transactional
    public GroupMember addGroupMember(Long groupId, Long userId, Integer role) {
        return addGroupMember(groupId, userId, role, null);
    }

    @Transactional
    public GroupMember addGroupMember(Long groupId, Long userId, Integer role, Long operatorId) {
        GroupChat group = getGroupById(groupId);
        if (!canInviteMember(group, operatorId)) {
            throw new RuntimeException("当前群组不允许普通成员邀请新成员");
        }
        
        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            throw new RuntimeException("用户已在群组中");
        }

        long memberCount = groupMemberRepository.countByGroupId(groupId);
        if (memberCount >= group.getMaxMemberCount()) {
            throw new RuntimeException("群组成员已满");
        }

        User user = userRepository.findById(userId).get();

        GroupMember member = new GroupMember();
        member.setGroupId(groupId);
        member.setUserId(userId);
        member.setRole(role);
        member.setNickname(user.getNickname());
        member.setIsMute(false);
        member.setJoinTime(new Date());

        group.setMemberCount((int) (memberCount + 1));
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);

        return groupMemberRepository.save(member);
    }

    /**
     * 从群组中移除指定成员。
     */
    @Transactional
    public void removeGroupMember(Long groupId, Long userId) {
        GroupChat group = getGroupById(groupId);
        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("成员不在群组中"));

        groupMemberRepository.delete(member);

        long memberCount = groupMemberRepository.countByGroupId(groupId);
        group.setMemberCount((int) memberCount);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    /**
     * 用户主动退出群组。群主不能直接退出。
     */
    @Transactional
    public void quitGroup(Long groupId, Long userId) {
        GroupChat group = getGroupById(groupId);
        if (group.getOwnerId().equals(userId)) {
            throw new RuntimeException("群主不能退出群组");
        }
        removeGroupMember(groupId, userId);
    }

    /**
     * 获取群组成员列表。
     */
    public List<GroupMember> getGroupMembers(Long groupId) {
        return groupMemberRepository.findByGroupId(groupId);
    }

    /**
     * 获取用户加入的群成员关系列表。
     */
    public List<GroupMember> getUserGroups(Long userId) {
        return groupMemberRepository.findByUserId(userId);
    }

    public List<GroupChat> getUserGroupChats(Long userId) {
        List<GroupMember> memberships = groupMemberRepository.findByUserId(userId);
        Set<Long> groupIds = new LinkedHashSet<>();
        for (GroupMember membership : memberships) {
            groupIds.add(membership.getGroupId());
        }

        List<GroupChat> groups = new ArrayList<>();
        for (Long groupId : groupIds) {
            groupChatRepository.findById(groupId)
                    .filter(group -> group.getStatus() != null && group.getStatus() == 1)
                    .ifPresent(groups::add);
        }
        return groups;
    }

    /**
     * 更新群组基础信息。
     */
    @Transactional
    public GroupChat updateGroupInfo(Long groupId, String groupName, String description, String notice, String avatar,
                                     Boolean allowMemberInvite, Integer joinType) {
        GroupChat group = getGroupById(groupId);
        
        if (groupName != null) {
            group.setGroupName(groupName);
        }
        if (description != null) {
            group.setDescription(description);
        }
        if (notice != null) {
            group.setNotice(notice);
        }
        if (avatar != null) {
            group.setAvatar(avatar);
        }
        if (allowMemberInvite != null) {
            group.setAllowMemberInvite(allowMemberInvite);
        }
        if (joinType != null) {
            group.setJoinType(joinType);
        }
        
        group.setUpdatedAt(new Date());
        return groupChatRepository.save(group);
    }

    /**
     * 转让群主身份。
     */
    @Transactional
    public void transferGroupOwner(Long groupId, Long newOwnerId) {
        GroupChat group = getGroupById(groupId);
        
        GroupMember newOwnerMember = groupMemberRepository.findByGroupIdAndUserId(groupId, newOwnerId)
                .orElseThrow(() -> new RuntimeException("新群主不在群组中"));
        
        GroupMember oldOwnerMember = groupMemberRepository.findByGroupIdAndUserId(groupId, group.getOwnerId())
                .orElseThrow(() -> new RuntimeException("原群主不在群组中"));

        oldOwnerMember.setRole(3);
        newOwnerMember.setRole(1);
        
        group.setOwnerId(newOwnerId);
        group.setUpdatedAt(new Date());
        
        groupMemberRepository.save(oldOwnerMember);
        groupMemberRepository.save(newOwnerMember);
        groupChatRepository.save(group);
    }

    /**
     * 设置群聊静音状态。
     */
    @Transactional
    public void setGroupMute(Long groupId, Boolean isMute) {
        GroupChat group = getGroupById(groupId);
        group.setIsMute(isMute);
        group.setUpdatedAt(new Date());
        groupChatRepository.save(group);
    }

    /**
     * 设置成员在群内的禁言状态。
     */
    @Transactional
    public void setMemberMute(Long groupId, Long userId, Boolean isMute) {
        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new RuntimeException("成员不在群组中"));
        member.setIsMute(isMute);
        groupMemberRepository.save(member);
    }

    /**
     * 分页获取群组列表，支持关键字和状态筛选。
     */
    public Page<GroupChat> getGroupList(String keyword, Integer status, Pageable pageable) {
        Specification<GroupChat> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            
            if (keyword != null && !keyword.isEmpty()) {
                predicates.add(cb.or(
                    cb.like(root.get("groupId"), "%" + keyword + "%"),
                    cb.like(root.get("groupName"), "%" + keyword + "%")
                ));
            }
            
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            
            return cb.and(predicates.toArray(new Predicate[0]));
        };
        
        return groupChatRepository.findAll(spec, pageable);
    }

    /**
     * 获取群组总数。
     */
    public long getTotalGroupCount() {
        return groupChatRepository.count();
    }

    /**
     * 生成 10 位数字的唯一群组号。
     */
    private String generateGroupId() {
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 10; i++) {
            sb.append(random.nextInt(10));
        }
        String groupId = sb.toString();
        
        if (groupChatRepository.existsByGroupId(groupId)) {
            return generateGroupId();
        }
        
        return groupId;
    }
}
