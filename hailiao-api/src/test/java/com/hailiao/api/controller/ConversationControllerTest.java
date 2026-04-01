package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.SetMuteRequestDTO;
import com.hailiao.api.dto.SetTopRequestDTO;
import com.hailiao.common.entity.Conversation;
import com.hailiao.common.service.ConversationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ConversationControllerTest {

    @Mock
    private ConversationService conversationService;

    @InjectMocks
    private ConversationController conversationController;

    @Test
    void getConversationListShouldReturnConvertedDtos() {
        List<Conversation> conversations = new ArrayList<Conversation>();
        Conversation conversation = new Conversation();
        conversation.setId(1L);
        conversation.setUserId(1L);
        conversation.setTargetId(2L);
        conversation.setType(1);
        conversation.setLastMsgContent("最近一条");
        conversation.setUnreadCount(3);
        conversation.setIsTop(true);
        conversation.setIsMute(false);
        conversation.setUpdatedAt(new Date());
        conversations.add(conversation);

        when(conversationService.getConversationList(1L)).thenReturn(conversations);

        ResponseEntity<ResponseDTO<List<com.hailiao.api.dto.ConversationDTO>>> response =
                conversationController.getConversationList(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("最近一条", response.getBody().getData().get(0).getLastMessage());
        assertTrue(response.getBody().getData().get(0).getIsTop());
    }

    @Test
    void setTopShouldDelegateToService() {
        SetTopRequestDTO request = new SetTopRequestDTO();
        request.setType(1);
        request.setIsTop(true);

        ResponseEntity<ResponseDTO<String>> response = conversationController.setTop(1L, 2L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(conversationService).setTop(1L, 2L, 1, true);
    }

    @Test
    void setMuteShouldDelegateToService() {
        SetMuteRequestDTO request = new SetMuteRequestDTO();
        request.setType(2);
        request.setIsMute(true);

        ResponseEntity<ResponseDTO<String>> response = conversationController.setMute(1L, 10L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(conversationService).setMute(1L, 10L, 2, true);
    }

    @Test
    void deleteConversationShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response = conversationController.deleteConversation(1L, 2L, 1);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(conversationService).deleteConversation(1L, 2L, 1);
    }

    @Test
    void getTotalUnreadCountShouldReturnServiceValue() {
        when(conversationService.getTotalUnreadCount(1L)).thenReturn(9L);

        ResponseEntity<ResponseDTO<Long>> response = conversationController.getTotalUnreadCount(1L);

        assertEquals(Long.valueOf(9L), response.getBody().getData());
    }
}
