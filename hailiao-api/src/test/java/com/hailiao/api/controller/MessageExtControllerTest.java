package com.hailiao.api.controller;

import com.hailiao.api.dto.MessageDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.Message;
import com.hailiao.common.service.MessageService;
import com.hailiao.common.service.UserOnlineService;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MessageExtControllerTest {

    @Mock
    private MessageService messageService;

    @Mock
    private UserOnlineService userOnlineService;

    @Mock
    private MessageController messageController;

    @InjectMocks
    private MessageExtController messageExtController;

    @Test
    void replyMessageShouldReturnConvertedDto() {
        Message message = buildMessage(1L, "回复内容");
        MessageDTO dto = buildMessageDTO(1L, "回复内容");

        when(messageService.replyToMessage(1L, 2L, null, 99L, "回复内容", 1, null)).thenReturn(message);
        when(messageController.convertToDTO(message)).thenReturn(dto);

        ResponseEntity<ResponseDTO<MessageDTO>> response =
                messageExtController.replyMessage(1L, 99L, 2L, null, "回复内容", 1, null);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("回复内容", response.getBody().getData().getContent());
    }

    @Test
    void editMessageShouldDelegateAndReturnDto() {
        Message message = buildMessage(2L, "新内容");
        MessageDTO dto = buildMessageDTO(2L, "新内容");

        when(messageService.editMessage(2L, 1L, "新内容")).thenReturn(message);
        when(messageController.convertToDTO(message)).thenReturn(dto);

        ResponseEntity<ResponseDTO<MessageDTO>> response =
                messageExtController.editMessage(1L, 2L, "新内容");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("新内容", response.getBody().getData().getContent());
    }

    @Test
    void getMessageReadStatusShouldReturnServiceResult() {
        Map<String, Object> readStatus = new HashMap<String, Object>();
        readStatus.put("messageId", 5L);
        readStatus.put("readCount", 3);

        when(messageService.getMessageReadStatus(5L)).thenReturn(readStatus);

        ResponseEntity<ResponseDTO<Object>> response = messageExtController.getMessageReadStatus(5L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(readStatus, response.getBody().getData());
    }

    @Test
    void searchMessagesShouldReturnSearchPage() {
        List<Message> messages = new ArrayList<Message>();
        messages.add(buildMessage(1L, "关键词"));
        Page<Message> page = new PageImpl<Message>(messages);

        when(messageService.searchMessages(any(Long.class), any(String.class), any(Pageable.class))).thenReturn(page);

        ResponseEntity<ResponseDTO<Object>> response = messageExtController.searchMessages(1L, "关键", 0, 20);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().getData() instanceof Page);
    }

    @Test
    void heartbeatShouldDelegateToOnlineService() {
        ResponseEntity<ResponseDTO<String>> response = messageExtController.heartbeat(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(userOnlineService).heartbeat(1L);
    }

    private Message buildMessage(Long id, String content) {
        Message message = new Message();
        message.setId(id);
        message.setMsgId("msg-" + id);
        message.setFromUserId(1L);
        message.setContent(content);
        message.setMsgType(1);
        message.setCreatedAt(new Date());
        return message;
    }

    private MessageDTO buildMessageDTO(Long id, String content) {
        MessageDTO dto = new MessageDTO();
        dto.setId(id);
        dto.setContent(content);
        return dto;
    }
}
