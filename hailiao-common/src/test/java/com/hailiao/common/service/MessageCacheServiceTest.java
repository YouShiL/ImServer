package com.hailiao.common.service;

import com.alibaba.fastjson2.JSON;
import com.hailiao.common.entity.Message;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.ListOperations;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.data.redis.core.ZSetOperations;

import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MessageCacheServiceTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ListOperations<String, String> listOperations;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @Mock
    private ZSetOperations<String, String> zSetOperations;

    @InjectMocks
    private MessageCacheService messageCacheService;

    @Test
    void cachePrivateMessageShouldUseSortedConversationKeyAndIncrementUnread() {
        Message message = new Message();
        message.setId(1L);
        message.setFromUserId(5L);
        message.setToUserId(2L);
        message.setContent("hello");

        when(redisTemplate.opsForList()).thenReturn(listOperations);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(redisTemplate.opsForZSet()).thenReturn(zSetOperations);

        messageCacheService.cachePrivateMessage(5L, 2L, message);

        verify(listOperations).leftPush(eq("msg:private:2:5"), any(String.class));
        verify(listOperations).trim("msg:private:2:5", 0, 99);
        verify(valueOperations).increment("msg:unread:2");
        verify(zSetOperations).add(eq("chat:recent:5"), eq("user:2"), any(Double.class));
        verify(zSetOperations).add(eq("chat:recent:2"), eq("user:5"), any(Double.class));
    }

    @Test
    void getPrivateMessagesShouldDeserializeCachedMessages() {
        Message one = new Message();
        one.setId(1L);
        one.setContent("one");
        Message two = new Message();
        two.setId(2L);
        two.setContent("two");

        when(redisTemplate.opsForList()).thenReturn(listOperations);
        when(listOperations.range("msg:private:1:2", 0, 1))
                .thenReturn(Arrays.asList(JSON.toJSONString(one), JSON.toJSONString(two)));

        List<Message> messages = messageCacheService.getPrivateMessages(2L, 1L, 2);

        assertEquals(2, messages.size());
        assertEquals(Long.valueOf(1L), messages.get(0).getId());
        assertEquals("two", messages.get(1).getContent());
    }

    @Test
    void getUnreadCountShouldFallbackToZero() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get("msg:unread:9")).thenReturn(null);

        assertEquals(0L, messageCacheService.getUnreadCount(9L));
    }

    @Test
    void getRecentChatsShouldReturnOrderedListFromZSet() {
        when(redisTemplate.opsForZSet()).thenReturn(zSetOperations);
        when(zSetOperations.reverseRange("chat:recent:1", 0, 1))
                .thenReturn(new LinkedHashSet<String>(Arrays.asList("group:10", "user:2")));

        List<String> chats = messageCacheService.getRecentChats(1L, 2);

        assertEquals(Arrays.asList("group:10", "user:2"), chats);
    }

    @Test
    void clearUnreadCountShouldDeleteAggregateAndPeerKeys() {
        when(redisTemplate.keys("msg:unread:3:*")).thenReturn(new LinkedHashSet<String>(Collections.singletonList("msg:unread:3:8")));

        messageCacheService.clearUnreadCount(3L);

        verify(redisTemplate).delete("msg:unread:3");
        verify(redisTemplate).delete(new LinkedHashSet<String>(Collections.singletonList("msg:unread:3:8")));
    }

    @Test
    void clearUserCacheShouldDeleteUnreadAndRecentKeys() {
        when(redisTemplate.keys("msg:unread:4:*")).thenReturn(new LinkedHashSet<String>(Collections.singletonList("msg:unread:4:9")));

        messageCacheService.clearUserCache(4L);

        verify(redisTemplate).delete("msg:unread:4");
        verify(redisTemplate).delete("chat:recent:4");
        verify(redisTemplate).delete(new LinkedHashSet<String>(Collections.singletonList("msg:unread:4:9")));
    }

    @Test
    void clearGroupCacheShouldDeleteGroupKey() {
        messageCacheService.clearGroupCache(12L);

        verify(redisTemplate).delete("msg:group:12");
    }
}
