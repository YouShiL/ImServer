package com.hailiao.common.repository;

import com.hailiao.common.entity.MessageReadStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MessageReadStatusRepository extends JpaRepository<MessageReadStatus, Long> {
    List<MessageReadStatus> findByMessageId(Long messageId);
    Optional<MessageReadStatus> findByMessageIdAndUserId(Long messageId, Long userId);
    long countByMessageId(Long messageId);
    void deleteByMessageId(Long messageId);
}
