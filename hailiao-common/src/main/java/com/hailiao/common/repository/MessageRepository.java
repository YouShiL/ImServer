package com.hailiao.common.repository;

import com.hailiao.common.entity.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Date;
import java.util.List;
import java.util.Optional;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long>, JpaSpecificationExecutor<Message> {
    Optional<Message> findByMsgId(String msgId);
    Page<Message> findByFromUserIdAndToUserIdOrderByCreatedAtDesc(Long fromUserId, Long toUserId, Pageable pageable);
    Page<Message> findByGroupIdOrderByCreatedAtDesc(Long groupId, Pageable pageable);
    List<Message> findByFromUserIdAndToUserIdAndCreatedAtAfter(Long fromUserId, Long toUserId, Date createdAt);
    List<Message> findByGroupIdAndCreatedAtAfter(Long groupId, Date createdAt);
    long countByFromUserIdAndToUserIdAndIsReadFalse(Long fromUserId, Long toUserId);
    long countByGroupIdAndIsReadFalse(Long groupId);
    long countByFromUserId(Long fromUserId);
    long countByMsgType(Integer msgType);
    long countByGroupId(Long groupId);
    Page<Message> findByFromUserIdOrToUserId(Long fromUserId, Long toUserId, Pageable pageable);
    Page<Message> findByMsgType(Integer msgType, Pageable pageable);

    @Query("SELECT m FROM Message m WHERE (m.fromUserId = :userId OR m.toUserId = :userId) " +
           "AND m.content LIKE %:keyword% AND m.msgType = 1 AND (m.isRecall IS NULL OR m.isRecall = false) " +
           "ORDER BY m.createdAt DESC")
    Page<Message> searchMessages(@Param("userId") Long userId, @Param("keyword") String keyword, Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.groupId = :groupId " +
           "AND m.content LIKE %:keyword% AND m.msgType = 1 AND (m.isRecall IS NULL OR m.isRecall = false) " +
           "ORDER BY m.createdAt DESC")
    Page<Message> searchGroupMessages(@Param("groupId") Long groupId, @Param("keyword") String keyword, Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.replyToMsgId = :messageId ORDER BY m.createdAt DESC")
    Page<Message> findRepliesByMessageId(@Param("messageId") Long messageId, Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.forwardFromMsgId = :messageId ORDER BY m.createdAt DESC")
    List<Message> findForwardsByMessageId(@Param("messageId") Long messageId);

    @Query("SELECT m FROM Message m WHERE m.groupId = :groupId AND m.isPinned = true ORDER BY m.pinTime DESC")
    List<Message> findPinnedMessagesByGroupId(@Param("groupId") Long groupId);

    @Query("SELECT m FROM Message m WHERE (m.fromUserId = :userId OR m.toUserId = :userId) AND m.isPinned = true ORDER BY m.pinTime DESC")
    List<Message> findPinnedMessagesByUserId(@Param("userId") Long userId);
}