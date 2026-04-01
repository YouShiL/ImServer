package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupMember;
import com.hailiao.common.service.GroupChatService;
import com.hailiao.common.service.GroupJoinRequestService;
import com.hailiao.common.service.GroupMemberService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupMemberControllerTest {

    @Mock
    private GroupMemberService groupMemberService;

    @Mock
    private GroupChatService groupChatService;

    @Mock
    private GroupJoinRequestService groupJoinRequestService;

    @InjectMocks
    private GroupMemberController groupMemberController;

    @Test
    void joinGroupShouldSubmitRequestWhenJoinTypeRequiresVerification() {
        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setJoinType(1);
        when(groupChatService.getGroupById(10L)).thenReturn(group);

        Map<String, Object> request = new HashMap<String, Object>();
        request.put("message", "申请入群");

        ResponseEntity<ResponseDTO<String>> response = groupMemberController.joinGroup(1L, 10L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(groupJoinRequestService).submitJoinRequest(10L, 1L, "申请入群");
    }

    @Test
    void joinGroupShouldJoinDirectlyWhenNoVerificationNeeded() {
        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setJoinType(0);
        when(groupChatService.getGroupById(10L)).thenReturn(group);

        ResponseEntity<ResponseDTO<String>> response = groupMemberController.joinGroup(1L, 10L, null);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(groupMemberService).joinGroup(10L, 1L);
    }

    @Test
    void muteAllShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response = groupMemberController.muteAll(1L, 10L, true);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(groupMemberService).muteAll(10L, 1L, true);
    }

    @Test
    void getMembersShouldReturnList() {
        List<GroupMember> members = new ArrayList<GroupMember>();
        GroupMember member = new GroupMember();
        member.setId(1L);
        member.setGroupId(10L);
        member.setUserId(2L);
        members.add(member);

        when(groupMemberService.getGroupMembers(10L)).thenReturn(members);

        ResponseEntity<ResponseDTO<List<GroupMember>>> response = groupMemberController.getMembers(10L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
    }

    @Test
    void getMemberShouldReturnOptionalValue() {
        GroupMember member = new GroupMember();
        member.setId(1L);
        member.setGroupId(10L);
        member.setUserId(2L);

        when(groupMemberService.getGroupMember(10L, 2L)).thenReturn(Optional.of(member));

        ResponseEntity<ResponseDTO<GroupMember>> response = groupMemberController.getMember(10L, 2L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(Long.valueOf(2L), response.getBody().getData().getUserId());
    }

    @Test
    void canSendMessageShouldReturnServiceValue() {
        when(groupMemberService.canSendGroupMessage(10L, 1L)).thenReturn(true);

        ResponseEntity<ResponseDTO<Boolean>> response = groupMemberController.canSendMessage(1L, 10L);

        assertTrue(response.getBody().getData());
    }
}
