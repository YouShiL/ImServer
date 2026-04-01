package com.hailiao.common.service;

import com.hailiao.common.entity.User;
import com.hailiao.common.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 用户在线状态服务。
 */
@Service
public class UserOnlineService {

    private static final String ONLINE_STATUS_KEY = "user:online:";
    private static final String LAST_ONLINE_KEY = "user:last_online:";
    private static final long ONLINE_TIMEOUT = 5 * 60;

    @Autowired
    private UserRepository userRepository;

    @Autowired(required = false)
    private StringRedisTemplate redisTemplate;

    public void setUserOnline(Long userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user != null) {
            user.setOnlineStatus(1);
            user.setLastOnlineAt(new Date());
            userRepository.save(user);
        }

        if (redisTemplate != null) {
            redisTemplate.opsForValue().set(ONLINE_STATUS_KEY + userId, "1", ONLINE_TIMEOUT, TimeUnit.SECONDS);
            redisTemplate.opsForValue().set(LAST_ONLINE_KEY + userId, String.valueOf(System.currentTimeMillis()));
        }
    }

    public void setUserOffline(Long userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user != null) {
            user.setOnlineStatus(0);
            user.setLastOnlineAt(new Date());
            userRepository.save(user);
        }

        if (redisTemplate != null) {
            redisTemplate.delete(ONLINE_STATUS_KEY + userId);
            redisTemplate.opsForValue().set(LAST_ONLINE_KEY + userId, String.valueOf(System.currentTimeMillis()));
        }
    }

    public void heartbeat(Long userId) {
        if (redisTemplate != null) {
            redisTemplate.opsForValue().set(ONLINE_STATUS_KEY + userId, "1", ONLINE_TIMEOUT, TimeUnit.SECONDS);
        }
    }

    public boolean isUserOnline(Long userId) {
        if (redisTemplate != null) {
            String status = redisTemplate.opsForValue().get(ONLINE_STATUS_KEY + userId);
            if (status != null) {
                return true;
            }
        }

        User user = userRepository.findById(userId).orElse(null);
        return user != null && user.getOnlineStatus() != null && user.getOnlineStatus() == 1;
    }

    public Date getLastOnlineTime(Long userId) {
        if (redisTemplate != null) {
            String timestamp = redisTemplate.opsForValue().get(LAST_ONLINE_KEY + userId);
            if (timestamp != null) {
                return new Date(Long.parseLong(timestamp));
            }
        }

        User user = userRepository.findById(userId).orElse(null);
        return user != null ? user.getLastOnlineAt() : null;
    }

    public Map<String, Object> getUserOnlineInfo(Long currentUserId, Long targetUserId) {
        Map<String, Object> result = new HashMap<>();
        User targetUser = userRepository.findById(targetUserId).orElse(null);
        if (targetUser == null) {
            result.put("exists", false);
            return result;
        }

        result.put("exists", true);
        result.put("userId", targetUserId);

        boolean showOnlineStatus = targetUser.getShowOnlineStatus() == null || targetUser.getShowOnlineStatus();
        boolean showLastOnline = targetUser.getShowLastOnline() == null || targetUser.getShowLastOnline();

        result.put("isOnline", showOnlineStatus ? isUserOnline(targetUserId) : null);
        if (showLastOnline && !isUserOnline(targetUserId)) {
            result.put("lastOnlineAt", getLastOnlineTime(targetUserId));
        } else {
            result.put("lastOnlineAt", null);
        }
        return result;
    }

    public void updateOnlineStatusSetting(Long userId, Boolean showOnlineStatus, Boolean showLastOnline) {
        User user = userRepository.findById(userId).orElse(null);
        if (user != null) {
            if (showOnlineStatus != null) {
                user.setShowOnlineStatus(showOnlineStatus);
            }
            if (showLastOnline != null) {
                user.setShowLastOnline(showLastOnline);
            }
            userRepository.save(user);
        }
    }

    public Map<Long, Boolean> batchGetOnlineStatus(java.util.List<Long> userIds) {
        Map<Long, Boolean> result = new HashMap<>();
        for (Long userId : userIds) {
            result.put(userId, isUserOnline(userId));
        }
        return result;
    }
}
