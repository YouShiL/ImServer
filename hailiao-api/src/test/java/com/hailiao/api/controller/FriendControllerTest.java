package com.hailiao.api.controller;

import com.hailiao.api.dto.FriendDTO;
import com.hailiao.api.dto.FriendRequestDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.Friend;
import com.hailiao.common.entity.FriendRequest;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.FriendService;
import com.hailiao.common.service.UserService;
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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FriendControllerTest {

    @Mock
    private FriendService friendService;

    @Mock
    private UserService userService;

    @InjectMocks
    private FriendController friendController;

    @Test
    void addFriendShouldReturnAutoAcceptedMessageWhenRequestApprovedImmediately() {
        FriendRequest request = new FriendRequest();
        request.setId(1L);
        request.setStatus(1);

        when(friendService.sendFriendRequest(1L, 2L, "备注", "你好")).thenReturn(request);

        Map<String, Object> body = new HashMap<String, Object>();
        body.put("friendId", 2L);
        body.put("remark", "备注");
        body.put("message", "你好");

        ResponseEntity<ResponseDTO<String>> response = friendController.addFriend(1L, body);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(200, response.getBody().getCode());
        assertEquals("已自动添加为好友", response.getBody().getData());
    }

    @Test
    void getReceivedRequestsShouldReturnConvertedDtos() {
        List<FriendRequest> requests = new ArrayList<FriendRequest>();
        FriendRequest request = new FriendRequest();
        request.setId(10L);
        request.setFromUserId(2L);
        request.setToUserId(1L);
        request.setStatus(0);
        request.setRemark("备注");
        requests.add(request);

        User fromUser = new User();
        fromUser.setId(2L);
        fromUser.setUserId("1000000002");
        fromUser.setNickname("好友");
        fromUser.setAvatar("avatar.png");

        when(friendService.getReceivedFriendRequests(1L)).thenReturn(requests);
        when(userService.getUserById(2L)).thenReturn(fromUser);

        ResponseEntity<ResponseDTO<List<FriendRequestDTO>>> response = friendController.getReceivedRequests(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("好友", response.getBody().getData().get(0).getFromUserInfo().getNickname());
    }

    @Test
    void getFriendListShouldReturnFriendUserInfo() {
        List<Friend> friends = new ArrayList<Friend>();
        Friend friend = new Friend();
        friend.setId(1L);
        friend.setUserId(1L);
        friend.setFriendId(2L);
        friend.setRemark("同学");
        friend.setGroupName("我的好友");
        friend.setStatus(1);
        friends.add(friend);

        User friendUser = new User();
        friendUser.setId(2L);
        friendUser.setUserId("1000000002");
        friendUser.setNickname("好友");
        friendUser.setPhone("13800138001");
        friendUser.setOnlineStatus(1);

        when(friendService.getFriendList(1L)).thenReturn(friends);
        when(userService.getUserById(2L)).thenReturn(friendUser);

        ResponseEntity<ResponseDTO<List<FriendDTO>>> response = friendController.getFriendList(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("好友", response.getBody().getData().get(0).getFriendUserInfo().getNickname());
        assertEquals("13800138001", response.getBody().getData().get(0).getFriendUserInfo().getPhone());
    }

    @Test
    void acceptRequestShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response = friendController.acceptRequest(1L, 10L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(friendService).acceptFriendRequest(10L, 1L);
    }

    @Test
    void deleteFriendShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response = friendController.deleteFriend(1L, 2L);

        assertTrue(response.getBody().getCode() == 200);
        verify(friendService).deleteFriend(1L, 2L);
    }
}
