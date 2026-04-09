package com.hailiao.common.service;

import com.hailiao.common.entity.ContentAudit;
import com.hailiao.common.entity.Conversation;
import com.hailiao.common.entity.Message;
import com.hailiao.common.entity.MessageReadStatus;
import com.hailiao.common.repository.ConversationRepository;
import com.hailiao.common.repository.MessageReadStatusRepository;
import com.hailiao.common.repository.MessageRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.stubbing.Answer;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MessageServiceTest {

    @Mock
    private MessageRepository messageRepository;

    @Mock
    private ConversationRepository conversationRepository;

    @Mock
    private MessageReadStatusRepository messageReadStatusRepository;

    @Mock
    private GroupRobotService groupRobotService;

    @Mock
    private MessageCacheService messageCacheService;

    @Mock
    private WebSocketNotificationService notificationService;

    @Mock
    private ContentAuditService contentAuditService;

    @InjectMocks
    private MessageService messageService;

    @Test
    void sendPrivateMessageShouldCacheAndCreateAudit() {
        when(messageRepository.save(any(Message.class))).thenAnswer(new org.mockito.stubbing.Answer<Message>() {
            @Override
            public Message answer(org.mockito.invocation.InvocationOnMock invocation) {
                Message message = (Message) invocation.getArgument(0);
                if (message.getId() == null) {
                    message.setId(1L);
                }
                return message;
            }
        });
        when(conversationRepository.findByUserIdAndTargetIdAndType(1L, 2L, 1)).thenReturn(Optional.<Conversation>empty());
        when(conversationRepository.findByUserIdAndTargetIdAndType(2L, 1L, 1)).thenReturn(Optional.<Conversation>empty());

        Message message = messageService.sendPrivateMessage(1L, 2L, "你好", 1, "{}");

        assertEquals(Long.valueOf(1L), message.getId());
        verify(messageCacheService).cachePrivateMessage(1L, 2L, message);
        verify(conversationRepository, atLeastOnce()).save(any(Conversation.class));

        ArgumentCaptor<ContentAudit> captor = ArgumentCaptor.forClass(ContentAudit.class);
        verify(contentAuditService).createAudit(captor.capture());
        assertEquals(Integer.valueOf(1), captor.getValue().getContentType());
        assertEquals(Long.valueOf(1L), captor.getValue().getUserId());
    }

    @Test
    void shouldReturnExistingWhenClientMsgNoDuplicate() {
        final String cm = "client-dedup-1";
        final Message stored = new Message();
        when(messageRepository.findByClientMsgNo(cm)).thenAnswer(new Answer<Optional<Message>>() {
            @Override
            public Optional<Message> answer(InvocationOnMock invocation) {
                if (stored.getId() == null) {
                    return Optional.empty();
                }
                return Optional.of(stored);
            }
        });
        when(messageRepository.save(any(Message.class))).thenAnswer(new Answer<Message>() {
            @Override
            public Message answer(InvocationOnMock invocation) {
                Message m = invocation.getArgument(0);
                if (stored.getId() == null) {
                    stored.setId(1L);
                    stored.setFromUserId(m.getFromUserId());
                    stored.setToUserId(m.getToUserId());
                    stored.setContent(m.getContent());
                    stored.setClientMsgNo(m.getClientMsgNo());
                    stored.setMsgType(m.getMsgType());
                }
                return stored;
            }
        });
        when(conversationRepository.findByUserIdAndTargetIdAndType(1L, 2L, 1))
                .thenReturn(Optional.<Conversation>empty());
        when(conversationRepository.findByUserIdAndTargetIdAndType(2L, 1L, 1))
                .thenReturn(Optional.<Conversation>empty());

        Message first = messageService.sendPrivateMessage(1L, 2L, "hi", 1, "{}", cm);
        Message second = messageService.sendPrivateMessage(1L, 2L, "hi", 1, "{}", cm);

        assertEquals(first.getId(), second.getId());
        verify(messageRepository, times(1)).save(any(Message.class));
    }

    @Test
    void recallMessageShouldRejectTimeout() {
        Message message = new Message();
        message.setId(1L);
        message.setFromUserId(1L);
        message.setCreatedAt(new Date(System.currentTimeMillis() - 3 * 60 * 1000L));

        when(messageRepository.findById(1L)).thenReturn(Optional.of(message));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        messageService.recallMessage(1L, 1L);
                    }
                });

        assertEquals("消息超过 2 分钟，无法撤回", error.getMessage());
    }

    @Test
    void markAsReadShouldUpdateMessagesAndConversation() {
        List<Message> messages = new ArrayList<Message>();
        Message unread = new Message();
        unread.setId(1L);
        unread.setIsRead(false);
        messages.add(unread);

        Conversation conversation = new Conversation();
        conversation.setId(1L);
        conversation.setUnreadCount(5);

        when(messageRepository.findByFromUserIdAndToUserIdAndCreatedAtAfter(any(Long.class), any(Long.class), any(Date.class)))
                .thenReturn(messages);
        when(conversationRepository.findByUserIdAndTargetIdAndType(1L, 2L, 1)).thenReturn(Optional.of(conversation));

        messageService.markAsRead(1L, 2L);

        assertTrue(unread.getIsRead());
        assertEquals(Integer.valueOf(0), conversation.getUnreadCount());
        verify(messageRepository).save(unread);
        verify(conversationRepository).save(conversation);
    }

    @Test
    void markGroupMessageAsReadShouldCreateStatusAndIncrementCount() {
        Message message = new Message();
        message.setId(1L);
        message.setGroupId(10L);
        message.setReadCount(0);

        when(messageRepository.findById(1L)).thenReturn(Optional.of(message));
        when(messageReadStatusRepository.findByMessageIdAndUserId(1L, 2L))
                .thenReturn(Optional.<MessageReadStatus>empty());

        messageService.markGroupMessageAsRead(1L, 2L);

        assertEquals(Integer.valueOf(1), message.getReadCount());
        verify(messageReadStatusRepository).save(any(MessageReadStatus.class));
        verify(messageRepository).save(message);
    }

    @Test
    void markGroupMessageAsReadShouldSkipDuplicateReadStatus() {
        Message message = new Message();
        message.setId(1L);
        message.setGroupId(10L);
        message.setReadCount(1);

        MessageReadStatus status = new MessageReadStatus();
        status.setMessageId(1L);
        status.setUserId(2L);

        when(messageRepository.findById(1L)).thenReturn(Optional.of(message));
        when(messageReadStatusRepository.findByMessageIdAndUserId(1L, 2L)).thenReturn(Optional.of(status));

        messageService.markGroupMessageAsRead(1L, 2L);

        assertEquals(Integer.valueOf(1), message.getReadCount());
        verify(messageReadStatusRepository, never()).save(any(MessageReadStatus.class));
    }

    @Test
    void getMessageReadStatusShouldReturnCountAndUserIds() {
        Message message = new Message();
        message.setId(1L);
        message.setReadCount(2);

        List<MessageReadStatus> statuses = new ArrayList<MessageReadStatus>();
        MessageReadStatus one = new MessageReadStatus();
        one.setMessageId(1L);
        one.setUserId(2L);
        statuses.add(one);
        MessageReadStatus two = new MessageReadStatus();
        two.setMessageId(1L);
        two.setUserId(3L);
        statuses.add(two);

        when(messageRepository.findById(1L)).thenReturn(Optional.of(message));
        when(messageReadStatusRepository.findByMessageId(1L)).thenReturn(statuses);

        java.util.Map<String, Object> result = messageService.getMessageReadStatus(1L);

        assertEquals(1L, result.get("messageId"));
        assertEquals(2, result.get("readCount"));
        assertNotNull(result.get("readUserIds"));
    }
}
