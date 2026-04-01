package com.hailiao.common.service;

import com.alibaba.fastjson2.JSON;
import com.hailiao.common.entity.Message;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Service
public class MessageCacheService {

    private static final Logger logger = LoggerFactory.getLogger(MessageCacheService.class);

    private static final String PRIVATE_MSG_PREFIX = "msg:private:";
    private static final String GROUP_MSG_PREFIX = "msg:group:";
    private static final String USER_UNREAD_PREFIX = "msg:unread:";
    private static final String RECENT_CHATS_PREFIX = "chat:recent:";

    private static final int CACHE_EXPIRE_DAYS = 7;
    private static final int MAX_CACHE_SIZE = 100;

    @Autowired
    private StringRedisTemplate redisTemplate;

    public void cachePrivateMessage(Long userId1, Long userId2, Message message) {
        String key = getPrivateChatKey(userId1, userId2);
        String messageJson = JSON.toJSONString(message);

        redisTemplate.opsForList().leftPush(key, messageJson);
        redisTemplate.opsForList().trim(key, 0, MAX_CACHE_SIZE - 1);
        redisTemplate.expire(key, CACHE_EXPIRE_DAYS, TimeUnit.DAYS);

        updateRecentChats(userId1, userId2, false);
        updateRecentChats(userId2, userId1, false);

        incrementUnreadCount(userId2);

        logger.debug("缓存私聊消息: key={}, msgId={}", key, message.getId());
    }

    public void cacheGroupMessage(Long groupId, Message message) {
        String key = GROUP_MSG_PREFIX + groupId;
        String messageJson = JSON.toJSONString(message);

        redisTemplate.opsForList().leftPush(key, messageJson);
        redisTemplate.opsForList().trim(key, 0, MAX_CACHE_SIZE - 1);
        redisTemplate.expire(key, CACHE_EXPIRE_DAYS, TimeUnit.DAYS);

        logger.debug("缓存群聊消息: key={}, msgId={}", key, message.getId());
    }

    public List<Message> getPrivateMessages(Long userId1, Long userId2, int count) {
        String key = getPrivateChatKey(userId1, userId2);
        List<String> messageJsons = redisTemplate.opsForList().range(key, 0, count - 1);

        if (messageJsons == null || messageJsons.isEmpty()) {
            return new ArrayList<>();
        }

        return messageJsons.stream()
                .map(json -> JSON.parseObject(json, Message.class))
                .collect(Collectors.toList());
    }

    public List<Message> getGroupMessages(Long groupId, int count) {
        String key = GROUP_MSG_PREFIX + groupId;
        List<String> messageJsons = redisTemplate.opsForList().range(key, 0, count - 1);

        if (messageJsons == null || messageJsons.isEmpty()) {
            return new ArrayList<>();
        }

        return messageJsons.stream()
                .map(json -> JSON.parseObject(json, Message.class))
                .collect(Collectors.toList());
    }

    public void incrementUnreadCount(Long userId) {
        String key = USER_UNREAD_PREFIX + userId;
        redisTemplate.opsForValue().increment(key);
        redisTemplate.expire(key, CACHE_EXPIRE_DAYS, TimeUnit.DAYS);
    }

    public void incrementUnreadCount(Long userId, Long fromUserId) {
        String key = USER_UNREAD_PREFIX + userId + ":" + fromUserId;
        redisTemplate.opsForValue().increment(key);
        redisTemplate.expire(key, CACHE_EXPIRE_DAYS, TimeUnit.DAYS);
    }

    public Long getUnreadCount(Long userId) {
        String key = USER_UNREAD_PREFIX + userId;
        String count = redisTemplate.opsForValue().get(key);
        return count != null ? Long.parseLong(count) : 0L;
    }

    public void clearUnreadCount(Long userId) {
        String key = USER_UNREAD_PREFIX + userId;
        redisTemplate.delete(key);

        Set<String> keys = redisTemplate.keys(USER_UNREAD_PREFIX + userId + ":*");
        if (keys != null && !keys.isEmpty()) {
            redisTemplate.delete(keys);
        }
    }

    public void clearUnreadCount(Long userId, Long fromUserId) {
        String key = USER_UNREAD_PREFIX + userId + ":" + fromUserId;
        redisTemplate.delete(key);
    }

    public void updateRecentChats(Long userId, Long targetId, boolean isGroup) {
        String key = RECENT_CHATS_PREFIX + userId;
        String chatKey = (isGroup ? "group:" : "user:") + targetId;
        String timestamp = String.valueOf(System.currentTimeMillis());

        redisTemplate.opsForZSet().add(key, chatKey, System.currentTimeMillis());
        redisTemplate.expire(key, CACHE_EXPIRE_DAYS, TimeUnit.DAYS);
    }

    public List<String> getRecentChats(Long userId, int count) {
        String key = RECENT_CHATS_PREFIX + userId;
        Set<String> chats = redisTemplate.opsForZSet().reverseRange(key, 0, count - 1);
        return chats != null ? new ArrayList<>(chats) : new ArrayList<>();
    }

    public void removeRecentChat(Long userId, Long targetId, boolean isGroup) {
        String key = RECENT_CHATS_PREFIX + userId;
        String chatKey = (isGroup ? "group:" : "user:") + targetId;
        redisTemplate.opsForZSet().remove(key, chatKey);
    }

    public void clearUserCache(Long userId) {
        String unreadKey = USER_UNREAD_PREFIX + userId;
        redisTemplate.delete(unreadKey);

        String recentKey = RECENT_CHATS_PREFIX + userId;
        redisTemplate.delete(recentKey);

        Set<String> unreadKeys = redisTemplate.keys(USER_UNREAD_PREFIX + userId + ":*");
        if (unreadKeys != null && !unreadKeys.isEmpty()) {
            redisTemplate.delete(unreadKeys);
        }

        logger.info("清除用户缓存: userId={}", userId);
    }

    public void clearGroupCache(Long groupId) {
        String key = GROUP_MSG_PREFIX + groupId;
        redisTemplate.delete(key);
        logger.info("清除群组缓存: groupId={}", groupId);
    }

    private String getPrivateChatKey(Long userId1, Long userId2) {
        Long minId = Math.min(userId1, userId2);
        Long maxId = Math.max(userId1, userId2);
        return PRIVATE_MSG_PREFIX + minId + ":" + maxId;
    }
}
