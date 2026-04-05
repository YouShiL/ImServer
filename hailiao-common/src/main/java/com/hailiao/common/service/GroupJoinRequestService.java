package com.hailiao.common.service;

import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupJoinRequest;
import com.hailiao.common.repository.GroupChatRepository;
import com.hailiao.common.repository.GroupJoinRequestRepository;
import com.hailiao.common.repository.GroupMemberRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

@Service
public class GroupJoinRequestService {

    public static final int STATUS_PENDING = 0;
    public static final int STATUS_APPROVED = 1;
    public static final int STATUS_REJECTED = 2;
    public static final int STATUS_WITHDRAWN = 3;

    @Autowired
    private GroupJoinRequestRepository groupJoinRequestRepository;

    @Autowired
    private GroupChatRepository groupChatRepository;

    @Autowired
    private GroupMemberRepository groupMemberRepository;

    @Autowired
    private GroupMemberService groupMemberService;

    @Autowired
    private GroupChatService groupChatService;

    @Transactional
    public GroupJoinRequest submitJoinRequest(Long groupId, Long userId, String message) {
        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            throw new RuntimeException("你已是群成员");
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("群组不存在"));

        if (group.getStatus() == null || group.getStatus() != 1) {
            throw new RuntimeException("群组当前不可用");
        }

        if (group.getMemberCount() != null
                && group.getMaxMemberCount() != null
                && group.getMemberCount() >= group.getMaxMemberCount()) {
            throw new RuntimeException("群成员数量已达上限");
        }

        groupJoinRequestRepository.findByGroupIdAndUserIdAndStatus(groupId, userId, STATUS_PENDING)
                .ifPresent(existing -> {
                    throw new RuntimeException("入群申请已提交，请勿重复申请");
                });

        GroupJoinRequest request = new GroupJoinRequest();
        request.setGroupId(groupId);
        request.setUserId(userId);
        request.setMessage(message);
        request.setStatus(STATUS_PENDING);
        request.setCreatedAt(new Date());
        request.setUpdatedAt(new Date());
        return groupJoinRequestRepository.save(request);
    }

    public List<GroupJoinRequest> getPendingRequests(Long groupId, Long operatorId) {
        ensureCanReview(groupId, operatorId);
        return groupJoinRequestRepository.findByGroupIdAndStatusOrderByCreatedAtDesc(groupId, STATUS_PENDING);
    }

    public List<GroupJoinRequest> getUserRequests(Long userId) {
        return groupJoinRequestRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional
    public GroupJoinRequest withdrawRequest(Long requestId, Long userId) {
        GroupJoinRequest request = getPendingRequest(requestId);
        if (!request.getUserId().equals(userId)) {
            throw new RuntimeException("无权撤回该入群申请");
        }

        request.setStatus(STATUS_WITHDRAWN);
        request.setHandledBy(userId);
        request.setHandledAt(new Date());
        request.setUpdatedAt(new Date());
        return groupJoinRequestRepository.save(request);
    }

    @Transactional
    public GroupJoinRequest approveRequest(Long requestId, Long operatorId) {
        GroupJoinRequest request = getPendingRequest(requestId);
        ensureCanReview(request.getGroupId(), operatorId);

        if (!groupMemberRepository.existsByGroupIdAndUserId(request.getGroupId(), request.getUserId())) {
            groupChatService.addGroupMember(
                    request.getGroupId(),
                    request.getUserId(),
                    GroupMemberService.ROLE_MEMBER,
                    operatorId);
        }

        request.setStatus(STATUS_APPROVED);
        request.setHandledBy(operatorId);
        request.setHandledAt(new Date());
        request.setUpdatedAt(new Date());
        return groupJoinRequestRepository.save(request);
    }

    @Transactional
    public GroupJoinRequest rejectRequest(Long requestId, Long operatorId) {
        GroupJoinRequest request = getPendingRequest(requestId);
        ensureCanReview(request.getGroupId(), operatorId);

        request.setStatus(STATUS_REJECTED);
        request.setHandledBy(operatorId);
        request.setHandledAt(new Date());
        request.setUpdatedAt(new Date());
        return groupJoinRequestRepository.save(request);
    }

    private GroupJoinRequest getPendingRequest(Long requestId) {
        GroupJoinRequest request = groupJoinRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("入群申请不存在"));
        if (request.getStatus() == null || request.getStatus() != STATUS_PENDING) {
            throw new RuntimeException("入群申请已处理");
        }
        return request;
    }

    private void ensureCanReview(Long groupId, Long operatorId) {
        if (!groupMemberService.isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("无权审核入群申请");
        }
    }
}
