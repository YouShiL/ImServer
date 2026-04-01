package com.hailiao.common.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class WebSocketNotificationServiceTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @InjectMocks
    private WebSocketNotificationService webSocketNotificationService;

    @Test
    void sendToUserShouldPublishJsonMessage() {
        webSocketNotificationService.sendToUser(1L, "notice", Collections.singletonMap("text", "hello"));

        verify(redisTemplate).convertAndSend(eq("user:channel:1"), any(String.class));
    }

    @Test
    void setUserOnlineShouldPersistServerId() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        webSocketNotificationService.setUserOnline(1L, "server-1");

        verify(valueOperations).set("user:online:1", "server-1", 5, java.util.concurrent.TimeUnit.MINUTES);
    }

    @Test
    void isUserOnlineShouldRespectRedisKeyPresence() {
        when(redisTemplate.hasKey("user:online:1")).thenReturn(true);
        when(redisTemplate.hasKey("user:online:2")).thenReturn(false);

        assertTrue(webSocketNotificationService.isUserOnline(1L));
        assertFalse(webSocketNotificationService.isUserOnline(2L));
    }

    @Test
    void getUserServerShouldReadFromRedis() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get("user:online:1")).thenReturn("server-2");

        assertEquals("server-2", webSocketNotificationService.getUserServer(1L));
    }

    @Test
    void sendCallSignalShouldDelegateToUserChannel() {
        webSocketNotificationService.sendCallSignal(99L, 1L, 2L, "offer", Collections.singletonMap("sdp", "abc"));

        verify(redisTemplate).convertAndSend(eq("user:channel:2"), any(String.class));
    }
}
