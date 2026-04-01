package com.hailiao.common.service;

import com.alibaba.fastjson2.JSON;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
public class WebSocketNotificationService {

    private static final Logger logger = LoggerFactory.getLogger(WebSocketNotificationService.class);

    private static final String USER_CHANNEL_PREFIX = "user:channel:";
    private static final String USER_ONLINE_PREFIX = "user:online:";

    @Autowired
    private StringRedisTemplate redisTemplate;

    public void sendToUser(Long userId, String eventType, Object data) {
        try {
            Map<String, Object> message = new HashMap<>();
            message.put("type", eventType);
            message.put("data", data);
            message.put("timestamp", System.currentTimeMillis());

            String channelName = USER_CHANNEL_PREFIX + userId;
            String messageJson = JSON.toJSONString(message);

            redisTemplate.convertAndSend(channelName, messageJson);

            logger.debug("发送消息到用户: userId={}, type={}", userId, eventType);
        } catch (Exception e) {
            logger.error("发送消息失败: userId={}, type={}, error={}", userId, eventType, e.getMessage(), e);
        }
    }

    public void sendToUsers(java.util.List<Long> userIds, String eventType, Object data) {
        for (Long userId : userIds) {
            sendToUser(userId, eventType, data);
        }
    }

    public void setUserOnline(Long userId, String serverId) {
        String key = USER_ONLINE_PREFIX + userId;
        redisTemplate.opsForValue().set(key, serverId, 5, TimeUnit.MINUTES);
    }

    public void setUserOffline(Long userId) {
        String key = USER_ONLINE_PREFIX + userId;
        redisTemplate.delete(key);
    }

    public boolean isUserOnline(Long userId) {
        String key = USER_ONLINE_PREFIX + userId;
        return Boolean.TRUE.equals(redisTemplate.hasKey(key));
    }

    public String getUserServer(Long userId) {
        String key = USER_ONLINE_PREFIX + userId;
        return redisTemplate.opsForValue().get(key);
    }

    public void sendCallSignal(Long callId, Long fromUserId, Long toUserId, String signalType, Object signalData) {
        Map<String, Object> data = new HashMap<>();
        data.put("callId", callId);
        data.put("fromUserId", fromUserId);
        data.put("signalType", signalType);
        data.put("signalData", signalData);
        sendToUser(toUserId, "call_signal", data);
    }
}
