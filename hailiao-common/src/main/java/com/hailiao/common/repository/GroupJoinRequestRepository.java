package com.hailiao.common.repository;

import com.hailiao.common.entity.GroupJoinRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GroupJoinRequestRepository extends JpaRepository<GroupJoinRequest, Long> {
    Optional<GroupJoinRequest> findByGroupIdAndUserIdAndStatus(Long groupId, Long userId, Integer status);
    List<GroupJoinRequest> findByGroupIdAndStatusOrderByCreatedAtDesc(Long groupId, Integer status);
    List<GroupJoinRequest> findByUserIdOrderByCreatedAtDesc(Long userId);
}
