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
            throw new RuntimeException("\u4f60\u5df2\u662f\u7fa4\u6210\u5458");
        }

        GroupChat group = groupChatRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("\u7fa4\u7ec4\u4e0d\u5b58\u5728"));

        if (group.getStatus() == null || group.getStatus() != 1) {
            throw new RuntimeException("\u7fa4\u7ec4\u5f53\u524d\u4e0d\u53ef\u7528");
        }

        if (group.getMemberCount() != null
                && group.getMaxMemberCount() != null
                && group.getMemberCount() >= group.getMaxMemberCount()) {
            throw new RuntimeException("\u7fa4\u6210\u5458\u6570\u91cf\u5df2\u8fbe\u4e0a\u9650");
        }

        groupJoinRequestRepository.findByGroupIdAndUserIdAndStatus(groupId, userId, STATUS_PENDING)
                .ifPresent(existing -> {
                    throw new RuntimeException("\u5165\u7fa4\u7533\u8bf7\u5df2\u63d0\u4ea4\uff0c\u8bf7\u52ff\u91cd\u590d\u7533\u8bf7");
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
            throw new RuntimeException("\u65e0\u6743\u64a4\u56de\u8be5\u5165\u7fa4\u7533\u8bf7");
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
                .orElseThrow(() -> new RuntimeException("\u5165\u7fa4\u7533\u8bf7\u4e0d\u5b58\u5728"));
        if (request.getStatus() == null || request.getStatus() != STATUS_PENDING) {
            throw new RuntimeException("\u5165\u7fa4\u7533\u8bf7\u5df2\u5904\u7406");
        }
        return request;
    }

    private void ensureCanReview(Long groupId, Long operatorId) {
        if (!groupMemberService.isGroupAdmin(groupId, operatorId)) {
            throw new RuntimeException("\u65e0\u6743\u5ba1\u6838\u5165\u7fa4\u7533\u8bf7");
        }
    }
}
