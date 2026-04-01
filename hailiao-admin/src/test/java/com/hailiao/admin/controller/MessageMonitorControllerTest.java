package com.hailiao.admin.controller;

import com.hailiao.common.entity.Message;
import com.hailiao.common.repository.MessageRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MessageMonitorControllerTest {

    @Mock
    private MessageRepository messageRepository;

    @InjectMocks
    private MessageMonitorController messageMonitorController;

    @Test
    void getMessagesReturnsSummaryAndLabels() {
        Message message = new Message();
        message.setId(1L);
        message.setMsgId("msg-1");
        message.setMsgType(2);
        message.setStatus(1);
        message.setIsRead(true);
        message.setIsRecall(true);

        List<Message> messages = new ArrayList<Message>();
        messages.add(message);
        Page<Message> page = new PageImpl<Message>(messages, PageRequest.of(0, 20), 1);
        when(messageRepository.findByMsgType(2, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending())))
                .thenReturn(page);

        ResponseEntity<Map<String, Object>> actual = messageMonitorController.getMessages(0, 20, null, null, 2);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1, summary.get("currentPageCount"));
        assertEquals(1L, summary.get("recalledCount"));
        assertEquals("图片", summary.get("msgTypeLabel"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("图片", first.get("msgTypeLabel"));
        assertEquals("正常", first.get("statusLabel"));
        assertEquals("已读", first.get("readLabel"));
        assertEquals("已撤回", first.get("recallLabel"));
    }
}
