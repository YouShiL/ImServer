package com.hailiao.common.repository;

import com.hailiao.common.entity.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, Long> {
    List<Conversation> findByUserIdOrderByIsTopDescUpdatedAtDesc(Long userId);
    Optional<Conversation> findByUserIdAndTargetIdAndType(Long userId, Long targetId, Integer type);
    long countByUserIdAndUnreadCountGreaterThan(Long userId, Integer unreadCount);
}