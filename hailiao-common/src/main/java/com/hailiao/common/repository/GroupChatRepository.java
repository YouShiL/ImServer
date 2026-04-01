package com.hailiao.common.repository;

import com.hailiao.common.entity.GroupChat;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface GroupChatRepository extends JpaRepository<GroupChat, Long>, JpaSpecificationExecutor<GroupChat> {
    Optional<GroupChat> findByGroupId(String groupId);
    boolean existsByGroupId(String groupId);
    long countByOwnerId(Long ownerId);
    long countByStatus(Integer status);
}