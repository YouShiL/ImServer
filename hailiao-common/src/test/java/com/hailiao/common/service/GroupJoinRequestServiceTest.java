package com.hailiao.common.service;

import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupJoinRequest;
import com.hailiao.common.repository.GroupChatRepository;
import com.hailiao.common.repository.GroupJoinRequestRepository;
import com.hailiao.common.repository.GroupMemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupJoinRequestServiceTest {

    @Mock
    private GroupJoinRequestRepository groupJoinRequestRepository;

    @Mock
    private GroupChatRepository groupChatRepository;

    @Mock
    private GroupMemberRepository groupMemberRepository;

    @Mock
    private GroupMemberService groupMemberService;

    @Mock
    private GroupChatService groupChatService;

    @InjectMocks
    private GroupJoinRequestService groupJoinRequestService;

    @Test
    void submitJoinRequestShouldRejectExistingMember() {
        when(groupMemberRepository.existsByGroupIdAndUserId(10L, 1L)).thenReturn(true);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        groupJoinRequestService.submitJoinRequest(10L, 1L, "申请");
                    }
                });

        assertEquals("你已是群成员", error.getMessage());
    }

    @Test
    void submitJoinRequestShouldCreatePendingRequest() {
        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setStatus(1);
        group.setMemberCount(10);
        group.setMaxMemberCount(200);

        when(groupMemberRepository.existsByGroupIdAndUserId(10L, 1L)).thenReturn(false);
        when(groupChatRepository.findById(10L)).thenReturn(Optional.of(group));
        when(groupJoinRequestRepository.findByGroupIdAndUserIdAndStatus(10L, 1L, 0))
                .thenReturn(Optional.<GroupJoinRequest>empty());
        when(groupJoinRequestRepository.save(any(GroupJoinRequest.class)))
                .thenAnswer(new org.mockito.stubbing.Answer<GroupJoinRequest>() {
                    @Override
                    public GroupJoinRequest answer(org.mockito.invocation.InvocationOnMock invocation) {
                        return (GroupJoinRequest) invocation.getArgument(0);
                    }
                });

        GroupJoinRequest request = groupJoinRequestService.submitJoinRequest(10L, 1L, "想加入");

        assertEquals(Integer.valueOf(GroupJoinRequestService.STATUS_PENDING), request.getStatus());
        assertEquals("想加入", request.getMessage());
        assertNotNull(request.getCreatedAt());
    }

    @Test
    void withdrawRequestShouldSetWithdrawnStatus() {
        GroupJoinRequest request = new GroupJoinRequest();
        request.setId(1L);
        request.setGroupId(10L);
        request.setUserId(1L);
        request.setStatus(GroupJoinRequestService.STATUS_PENDING);

        when(groupJoinRequestRepository.findById(1L)).thenReturn(Optional.of(request));
        when(groupJoinRequestRepository.save(any(GroupJoinRequest.class)))
                .thenAnswer(new org.mockito.stubbing.Answer<GroupJoinRequest>() {
                    @Override
                    public GroupJoinRequest answer(org.mockito.invocation.InvocationOnMock invocation) {
                        return (GroupJoinRequest) invocation.getArgument(0);
                    }
                });

        GroupJoinRequest saved = groupJoinRequestService.withdrawRequest(1L, 1L);

        assertEquals(Integer.valueOf(GroupJoinRequestService.STATUS_WITHDRAWN), saved.getStatus());
        assertEquals(Long.valueOf(1L), saved.getHandledBy());
        assertNotNull(saved.getHandledAt());
    }

    @Test
    void approveRequestShouldAddMemberAndSetApprovedStatus() {
        GroupJoinRequest request = new GroupJoinRequest();
        request.setId(1L);
        request.setGroupId(10L);
        request.setUserId(2L);
        request.setStatus(GroupJoinRequestService.STATUS_PENDING);

        when(groupJoinRequestRepository.findById(1L)).thenReturn(Optional.of(request));
        when(groupMemberService.isGroupAdmin(10L, 1L)).thenReturn(true);
        when(groupMemberRepository.existsByGroupIdAndUserId(10L, 2L)).thenReturn(false);
        when(groupJoinRequestRepository.save(any(GroupJoinRequest.class)))
                .thenAnswer(new org.mockito.stubbing.Answer<GroupJoinRequest>() {
                    @Override
                    public GroupJoinRequest answer(org.mockito.invocation.InvocationOnMock invocation) {
                        return (GroupJoinRequest) invocation.getArgument(0);
                    }
                });

        GroupJoinRequest saved = groupJoinRequestService.approveRequest(1L, 1L);

        assertEquals(Integer.valueOf(GroupJoinRequestService.STATUS_APPROVED), saved.getStatus());
        verify(groupChatService).addGroupMember(10L, 2L, GroupMemberService.ROLE_MEMBER, 1L);
    }

    @Test
    void rejectRequestShouldRequireAdminPermission() {
        GroupJoinRequest request = new GroupJoinRequest();
        request.setId(1L);
        request.setGroupId(10L);
        request.setUserId(2L);
        request.setStatus(GroupJoinRequestService.STATUS_PENDING);

        when(groupJoinRequestRepository.findById(1L)).thenReturn(Optional.of(request));
        when(groupMemberService.isGroupAdmin(10L, 1L)).thenReturn(false);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        groupJoinRequestService.rejectRequest(1L, 1L);
                    }
                });

        assertEquals("无权审核入群申请", error.getMessage());
    }
}
