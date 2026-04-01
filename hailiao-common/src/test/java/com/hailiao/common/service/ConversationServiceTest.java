package com.hailiao.common.service;

import com.hailiao.common.entity.Conversation;
import com.hailiao.common.repository.ConversationRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ConversationServiceTest {

    @Mock
    private ConversationRepository conversationRepository;

    @InjectMocks
    private ConversationService conversationService;

    @Test
    void getConversationListShouldDelegateToRepository() {
        Conversation conversation = new Conversation();
        conversation.setId(1L);
        List<Conversation> conversations = Arrays.asList(conversation);

        when(conversationRepository.findByUserIdOrderByIsTopDescUpdatedAtDesc(1L)).thenReturn(conversations);

        List<Conversation> result = conversationService.getConversationList(1L);

        assertEquals(1, result.size());
        verify(conversationRepository).findByUserIdOrderByIsTopDescUpdatedAtDesc(1L);
    }

    @Test
    void setTopShouldUpdateConversation() {
        Conversation conversation = buildConversation();
        when(conversationRepository.findByUserIdAndTargetIdAndType(1L, 2L, 1))
                .thenReturn(Optional.of(conversation));

        conversationService.setTop(1L, 2L, 1, true);

        assertEquals(Boolean.TRUE, conversation.getIsTop());
        verify(conversationRepository).save(conversation);
    }

    @Test
    void setMuteShouldThrowWhenConversationMissing() {
        when(conversationRepository.findByUserIdAndTargetIdAndType(1L, 2L, 1))
                .thenReturn(Optional.<Conversation>empty());

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        conversationService.setMute(1L, 2L, 1, true);
                    }
                });

        assertEquals("会话不存在", error.getMessage());
    }

    @Test
    void deleteConversationShouldDeleteRepositoryEntity() {
        Conversation conversation = buildConversation();
        when(conversationRepository.findByUserIdAndTargetIdAndType(1L, 2L, 1))
                .thenReturn(Optional.of(conversation));

        conversationService.deleteConversation(1L, 2L, 1);

        verify(conversationRepository).delete(conversation);
    }

    @Test
    void getTotalUnreadCountShouldReturnRepositoryCount() {
        when(conversationRepository.countByUserIdAndUnreadCountGreaterThan(1L, 0)).thenReturn(8L);

        long count = conversationService.getTotalUnreadCount(1L);

        assertEquals(8L, count);
    }

    private Conversation buildConversation() {
        Conversation conversation = new Conversation();
        conversation.setId(1L);
        conversation.setUserId(1L);
        conversation.setTargetId(2L);
        conversation.setType(1);
        conversation.setUpdatedAt(new Date());
        return conversation;
    }
}
