package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.SendGroupMessageRequestDTO;
import com.hailiao.api.dto.SendPrivateMessageRequestDTO;
import com.hailiao.common.entity.Message;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.MessageService;
import com.hailiao.common.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MessageControllerTest {

    @Mock
    private MessageService messageService;

    @Mock
    private UserService userService;

    @InjectMocks
    private MessageController messageController;

    @Test
    void sendPrivateMessageShouldReturnConvertedDto() {
        SendPrivateMessageRequestDTO request = new SendPrivateMessageRequestDTO();
        request.setToUserId(2L);
        request.setContent("你好");
        request.setMsgType(1);
        request.setExtra("{}");

        Message message = buildPrivateMessage();
        User sender = buildUser(1L, "1000000001", "发送者");

        when(messageService.sendPrivateMessage(1L, 2L, "你好", 1, "{}")).thenReturn(message);
        when(userService.getUserById(1L)).thenReturn(sender);

        ResponseEntity<ResponseDTO<com.hailiao.api.dto.MessageDTO>> response =
                messageController.sendPrivateMessage(1L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("发送者", response.getBody().getData().getFromUserInfo().getNickname());
        assertEquals("你好", response.getBody().getData().getContent());
    }

    @Test
    void sendGroupMessageShouldUseDefaultMsgTypeWhenMissing() {
        SendGroupMessageRequestDTO request = new SendGroupMessageRequestDTO();
        request.setGroupId(10L);
        request.setContent("群消息");
        request.setExtra("{}");

        Message message = buildGroupMessage();
        when(messageService.sendGroupMessage(1L, 10L, "群消息", 1, "{}")).thenReturn(message);

        ResponseEntity<ResponseDTO<com.hailiao.api.dto.MessageDTO>> response =
                messageController.sendGroupMessage(1L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(Long.valueOf(10L), response.getBody().getData().getGroupId());
    }

    @Test
    void getPrivateMessagesShouldReturnPagedDtos() {
        List<Message> messages = new ArrayList<Message>();
        messages.add(buildPrivateMessage());
        Page<Message> page = new PageImpl<Message>(messages);

        when(messageService.getPrivateMessages(any(Long.class), any(Long.class), any(Pageable.class))).thenReturn(page);

        ResponseEntity<ResponseDTO<Page<com.hailiao.api.dto.MessageDTO>>> response =
                messageController.getPrivateMessages(1L, 2L, 0, 20);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().getContent().size());
        assertEquals("你好", response.getBody().getData().getContent().get(0).getContent());
    }

    @Test
    void markAsReadShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response = messageController.markAsRead(1L, 2L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(messageService).markAsRead(1L, 2L);
    }

    @Test
    void getUnreadCountShouldReturnServiceValue() {
        when(messageService.getUnreadCount(1L, 2L)).thenReturn(5L);

        ResponseEntity<ResponseDTO<Long>> response = messageController.getUnreadCount(1L, 2L);

        assertTrue(response.getBody().getCode() == 200);
        assertEquals(Long.valueOf(5L), response.getBody().getData());
    }

    private Message buildPrivateMessage() {
        Message message = new Message();
        message.setId(1L);
        message.setMsgId("msg-1");
        message.setFromUserId(1L);
        message.setToUserId(2L);
        message.setContent("你好");
        message.setMsgType(1);
        message.setExtra("{}");
        message.setStatus(1);
        message.setIsRead(false);
        message.setIsRecall(false);
        message.setCreatedAt(new Date());
        return message;
    }

    private Message buildGroupMessage() {
        Message message = buildPrivateMessage();
        message.setGroupId(10L);
        message.setToUserId(null);
        message.setContent("群消息");
        return message;
    }

    private User buildUser(Long id, String userId, String nickname) {
        User user = new User();
        user.setId(id);
        user.setUserId(userId);
        user.setNickname(nickname);
        user.setAvatar("avatar.png");
        return user;
    }
}
