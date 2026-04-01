package com.hailiao.common.service;

import com.hailiao.common.entity.UserSession;
import com.hailiao.common.repository.UserSessionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.UUID;

@Service
public class UserSessionService {

    @Autowired
    private UserSessionRepository userSessionRepository;

    @Autowired
    private UserService userService;

    @Transactional
    public UserSession createSession(Long userId, String deviceId, String deviceName, String deviceType,
                                     String loginIp, String userAgent) {
        Date now = new Date();
        UserSession session = userSessionRepository
                .findByUserIdAndDeviceIdAndIsActiveTrue(userId, normalizeDeviceId(deviceId))
                .orElse(new UserSession());

        session.setUserId(userId);
        session.setSessionId(UUID.randomUUID().toString().replace("-", ""));
        session.setDeviceId(normalizeDeviceId(deviceId));
        session.setDeviceName(normalizeDeviceName(deviceName, deviceType));
        session.setDeviceType(normalizeDeviceType(deviceType));
        session.setLoginIp(loginIp);
        session.setUserAgent(trimToNull(userAgent));
        session.setIsActive(true);
        if (session.getCreatedAt() == null) {
            session.setCreatedAt(now);
        }
        session.setLastActiveAt(now);
        session.setRevokedAt(null);
        return userSessionRepository.save(session);
    }

    public boolean hasActiveSessionOnOtherDevice(Long userId, String deviceId) {
        List<UserSession> sessions = userSessionRepository.findByUserIdAndIsActiveTrue(userId);
        String normalizedDeviceId = normalizeDeviceId(deviceId);
        for (UserSession session : sessions) {
            if (session.getDeviceId() == null) {
                return true;
            }
            if (!session.getDeviceId().equals(normalizedDeviceId)) {
                return true;
            }
        }
        return false;
    }

    public boolean isSessionActive(Long userId, String sessionId) {
        return userSessionRepository.findByUserIdAndSessionId(userId, sessionId)
                .map(session -> Boolean.TRUE.equals(session.getIsActive()))
                .orElse(false);
    }

    @Transactional
    public void touchSession(String sessionId) {
        userSessionRepository.findBySessionId(sessionId).ifPresent(session -> {
            session.setLastActiveAt(new Date());
            userSessionRepository.save(session);
        });
    }

    public List<UserSession> getUserSessions(Long userId) {
        return userSessionRepository.findByUserIdOrderByLastActiveAtDesc(userId);
    }

    @Transactional
    public void revokeSession(Long userId, String sessionId) {
        UserSession session = userSessionRepository.findByUserIdAndSessionId(userId, sessionId)
                .orElseThrow(() -> new RuntimeException("\u4f1a\u8bdd\u4e0d\u5b58\u5728"));
        revokeSession(session);
    }

    @Transactional
    public void revokeOtherSessions(Long userId, String currentSessionId) {
        List<UserSession> sessions = userSessionRepository.findByUserIdAndIsActiveTrue(userId);
        for (UserSession session : sessions) {
            if (currentSessionId != null && currentSessionId.equals(session.getSessionId())) {
                continue;
            }
            revokeSession(session);
        }
        refreshUserOnlineStatus(userId);
    }

    @Transactional
    public void revokeCurrentSession(Long userId, String sessionId) {
        if (sessionId == null || sessionId.trim().isEmpty()) {
            userService.updateOnlineStatus(userId, 0);
            return;
        }
        revokeSession(userId, sessionId);
        refreshUserOnlineStatus(userId);
    }

    @Transactional
    public void refreshUserOnlineStatus(Long userId) {
        long activeCount = userSessionRepository.countByUserIdAndIsActiveTrue(userId);
        userService.updateOnlineStatus(userId, activeCount > 0 ? 1 : 0);
    }

    private void revokeSession(UserSession session) {
        if (session == null || !Boolean.TRUE.equals(session.getIsActive())) {
            return;
        }
        session.setIsActive(false);
        session.setRevokedAt(new Date());
        session.setLastActiveAt(new Date());
        userSessionRepository.save(session);
    }

    private String normalizeDeviceId(String deviceId) {
        String normalized = trimToNull(deviceId);
        return normalized != null ? normalized : "unknown-device";
    }

    private String normalizeDeviceName(String deviceName, String deviceType) {
        String normalized = trimToNull(deviceName);
        if (normalized != null) {
            return normalized;
        }
        String type = normalizeDeviceType(deviceType);
        return type.substring(0, 1).toUpperCase() + type.substring(1) + " device";
    }

    private String normalizeDeviceType(String deviceType) {
        String normalized = trimToNull(deviceType);
        return normalized != null ? normalized : "unknown";
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
