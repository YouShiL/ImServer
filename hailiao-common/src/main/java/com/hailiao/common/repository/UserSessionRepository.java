package com.hailiao.common.repository;

import com.hailiao.common.entity.UserSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserSessionRepository extends JpaRepository<UserSession, Long> {
    Optional<UserSession> findBySessionId(String sessionId);
    List<UserSession> findByUserIdOrderByLastActiveAtDesc(Long userId);
    List<UserSession> findByUserIdAndIsActiveTrue(Long userId);
    Optional<UserSession> findByUserIdAndSessionId(Long userId, String sessionId);
    Optional<UserSession> findByUserIdAndDeviceIdAndIsActiveTrue(Long userId, String deviceId);
    boolean existsByUserIdAndDeviceIdAndIsActiveTrue(Long userId, String deviceId);
    long countByUserIdAndIsActiveTrue(Long userId);
}
