package com.hailiao.common.service;

import com.hailiao.common.entity.UserSession;
import com.hailiao.common.repository.UserSessionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.Collections;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserSessionServiceTest {

    @Mock
    private UserSessionRepository userSessionRepository;

    @Mock
    private UserService userService;

    @InjectMocks
    private UserSessionService userSessionService;

    @Test
    void createSessionShouldNormalizeDeviceAndReuseCreatedAt() {
        UserSession existing = new UserSession();
        existing.setId(1L);
        existing.setCreatedAt(new java.util.Date(System.currentTimeMillis() - 10000));

        when(userSessionRepository.findByUserIdAndDeviceIdAndIsActiveTrue(1L, "device-1"))
                .thenReturn(Optional.of(existing));
        when(userSessionRepository.save(any(UserSession.class))).thenAnswer(new org.mockito.stubbing.Answer<UserSession>() {
            @Override
            public UserSession answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (UserSession) invocation.getArgument(0);
            }
        });

        UserSession session = userSessionService.createSession(1L, " device-1 ", null, "android", "127.0.0.1", "UA");

        assertEquals(Long.valueOf(1L), session.getUserId());
        assertEquals("device-1", session.getDeviceId());
        assertEquals("Android device", session.getDeviceName());
        assertEquals("android", session.getDeviceType());
        assertEquals("127.0.0.1", session.getLoginIp());
        assertEquals("UA", session.getUserAgent());
        assertTrue(session.getIsActive());
        assertNotNull(session.getSessionId());
        assertNotNull(session.getLastActiveAt());
        assertNotNull(session.getCreatedAt());
    }

    @Test
    void hasActiveSessionOnOtherDeviceShouldReturnTrueWhenAnotherDeviceExists() {
        UserSession same = new UserSession();
        same.setDeviceId("device-1");
        UserSession other = new UserSession();
        other.setDeviceId("device-2");

        when(userSessionRepository.findByUserIdAndIsActiveTrue(1L)).thenReturn(Arrays.asList(same, other));

        assertTrue(userSessionService.hasActiveSessionOnOtherDevice(1L, "device-1"));
    }

    @Test
    void hasActiveSessionOnOtherDeviceShouldReturnFalseWhenOnlySameDeviceExists() {
        UserSession same = new UserSession();
        same.setDeviceId("device-1");

        when(userSessionRepository.findByUserIdAndIsActiveTrue(1L)).thenReturn(Collections.singletonList(same));

        assertFalse(userSessionService.hasActiveSessionOnOtherDevice(1L, "device-1"));
    }

    @Test
    void revokeSessionShouldRejectMissingSession() {
        when(userSessionRepository.findByUserIdAndSessionId(1L, "missing")).thenReturn(Optional.<UserSession>empty());

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        userSessionService.revokeSession(1L, "missing");
                    }
                });

        assertEquals("\u4f1a\u8bdd\u4e0d\u5b58\u5728", error.getMessage());
    }

    @Test
    void revokeOtherSessionsShouldSkipCurrentSessionAndRefreshOnlineStatus() {
        UserSession current = new UserSession();
        current.setSessionId("current");
        current.setIsActive(true);

        UserSession other = new UserSession();
        other.setSessionId("other");
        other.setIsActive(true);

        when(userSessionRepository.findByUserIdAndIsActiveTrue(1L)).thenReturn(Arrays.asList(current, other));
        when(userSessionRepository.countByUserIdAndIsActiveTrue(1L)).thenReturn(1L);

        userSessionService.revokeOtherSessions(1L, "current");

        assertFalse(other.getIsActive());
        assertNotNull(other.getRevokedAt());
        verify(userSessionRepository).save(other);
        verify(userService).updateOnlineStatus(1L, 1);
    }

    @Test
    void revokeCurrentSessionShouldSetOfflineWhenSessionIdMissing() {
        userSessionService.revokeCurrentSession(1L, " ");

        verify(userService).updateOnlineStatus(1L, 0);
    }

    @Test
    void touchSessionShouldUpdateLastActiveTime() {
        UserSession session = new UserSession();
        session.setSessionId("session-1");
        session.setLastActiveAt(new java.util.Date(System.currentTimeMillis() - 10000));

        when(userSessionRepository.findBySessionId("session-1")).thenReturn(Optional.of(session));

        userSessionService.touchSession("session-1");

        verify(userSessionRepository).save(session);
        assertNotNull(session.getLastActiveAt());
    }
}
