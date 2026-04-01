package com.hailiao.api.controller;

import com.hailiao.api.dto.GroupJoinRequestDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupJoinRequest;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.GroupChatService;
import com.hailiao.common.service.GroupJoinRequestService;
import com.hailiao.common.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupJoinRequestControllerTest {

    @Mock
    private GroupJoinRequestService groupJoinRequestService;

    @Mock
    private UserService userService;

    @Mock
    private GroupChatService groupChatService;

    @InjectMocks
    private GroupJoinRequestController groupJoinRequestController;

    @Test
    void getPendingRequestsShouldReturnRichDtos() {
        List<GroupJoinRequest> requests = new ArrayList<GroupJoinRequest>();
        GroupJoinRequest request = new GroupJoinRequest();
        request.setId(1L);
        request.setGroupId(10L);
        request.setUserId(2L);
        request.setStatus(0);
        request.setMessage("想加入");
        requests.add(request);

        User user = new User();
        user.setId(2L);
        user.setUserId("1000000002");
        user.setNickname("申请人");

        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setGroupId("G100000001");
        group.setGroupName("测试群");
        group.setOwnerId(1L);
        group.setMemberCount(10);
        group.setMaxMemberCount(200);
        group.setAllowMemberInvite(true);
        group.setJoinType(1);
        group.setIsMute(false);
        group.setStatus(1);

        when(groupJoinRequestService.getPendingRequests(10L, 1L)).thenReturn(requests);
        when(userService.getUserById(2L)).thenReturn(user);
        when(groupChatService.getGroupById(10L)).thenReturn(group);

        ResponseEntity<ResponseDTO<List<GroupJoinRequestDTO>>> response =
                groupJoinRequestController.getPendingRequests(1L, 10L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("申请人", response.getBody().getData().get(0).getUserInfo().getNickname());
        assertEquals("测试群", response.getBody().getData().get(0).getGroupInfo().getGroupName());
    }

    @Test
    void getMyRequestsShouldReturnOwnRequests() {
        List<GroupJoinRequest> requests = new ArrayList<GroupJoinRequest>();
        GroupJoinRequest request = new GroupJoinRequest();
        request.setId(1L);
        request.setGroupId(10L);
        request.setUserId(1L);
        request.setStatus(0);
        requests.add(request);

        when(groupJoinRequestService.getUserRequests(1L)).thenReturn(requests);

        ResponseEntity<ResponseDTO<List<GroupJoinRequestDTO>>> response =
                groupJoinRequestController.getMyRequests(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
    }

    @Test
    void approveRequestShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response =
                groupJoinRequestController.approveRequest(1L, 99L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(groupJoinRequestService).approveRequest(99L, 1L);
    }

    @Test
    void withdrawRequestShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response =
                groupJoinRequestController.withdrawRequest(1L, 99L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(groupJoinRequestService).withdrawRequest(99L, 1L);
    }
}
