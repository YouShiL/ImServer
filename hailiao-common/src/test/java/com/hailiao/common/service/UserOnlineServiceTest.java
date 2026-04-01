package com.hailiao.common.service;

import com.hailiao.common.entity.User;
import com.hailiao.common.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserOnlineServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @InjectMocks
    private UserOnlineService userOnlineService;

    @Test
    void setUserOnlineShouldUpdateUserAndCache() {
        User user = buildUser(1L);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        userOnlineService.setUserOnline(1L);

        assertEquals(Integer.valueOf(1), user.getOnlineStatus());
        assertNotNull(user.getLastOnlineAt());
        verify(userRepository).save(user);
        verify(valueOperations).set("user:online:1", "1", 300L, TimeUnit.SECONDS);
    }

    @Test
    void setUserOfflineShouldClearOnlineKeyAndUpdateLastOnline() {
        User user = buildUser(1L);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        userOnlineService.setUserOffline(1L);

        assertEquals(Integer.valueOf(0), user.getOnlineStatus());
        verify(redisTemplate).delete("user:online:1");
        verify(userRepository).save(user);
    }

    @Test
    void isUserOnlineShouldUseRedisFirst() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get("user:online:1")).thenReturn("1");

        boolean result = userOnlineService.isUserOnline(1L);

        assertTrue(result);
        verify(userRepository, never()).findById(anyLong());
    }

    @Test
    void getUserOnlineInfoShouldHideStatusWhenTargetDisablesIt() {
        User target = buildUser(2L);
        target.setShowOnlineStatus(false);
        target.setShowLastOnline(false);
        when(userRepository.findById(2L)).thenReturn(Optional.of(target));

        Map<String, Object> result = userOnlineService.getUserOnlineInfo(1L, 2L);

        assertEquals(Boolean.TRUE, result.get("exists"));
        assertNull(result.get("isOnline"));
        assertNull(result.get("lastOnlineAt"));
    }

    @Test
    void updateOnlineStatusSettingShouldPersistFlags() {
        User user = buildUser(1L);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        userOnlineService.updateOnlineStatusSetting(1L, false, true);

        assertFalse(user.getShowOnlineStatus());
        assertTrue(user.getShowLastOnline());
        verify(userRepository).save(user);
    }

    @Test
    void batchGetOnlineStatusShouldReturnStatusesForEachUser() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get("user:online:1")).thenReturn("1");
        when(valueOperations.get("user:online:2")).thenReturn(null);
        User offlineUser = buildUser(2L);
        offlineUser.setOnlineStatus(0);
        when(userRepository.findById(2L)).thenReturn(Optional.of(offlineUser));

        List<Long> ids = Arrays.asList(1L, 2L);
        Map<Long, Boolean> result = userOnlineService.batchGetOnlineStatus(ids);

        assertEquals(Boolean.TRUE, result.get(1L));
        assertEquals(Boolean.FALSE, result.get(2L));
    }

    private User buildUser(Long id) {
        User user = new User();
        user.setId(id);
        user.setOnlineStatus(0);
        user.setShowOnlineStatus(true);
        user.setShowLastOnline(true);
        user.setLastOnlineAt(new Date());
        return user;
    }
}
