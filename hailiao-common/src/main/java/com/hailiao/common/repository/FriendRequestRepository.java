package com.hailiao.common.repository;

import com.hailiao.common.entity.FriendRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRequestRepository extends JpaRepository<FriendRequest, Long> {
    Optional<FriendRequest> findByFromUserIdAndToUserIdAndStatus(Long fromUserId, Long toUserId, Integer status);
    List<FriendRequest> findByToUserIdAndStatusOrderByCreatedAtDesc(Long toUserId, Integer status);
    List<FriendRequest> findByFromUserIdOrderByCreatedAtDesc(Long fromUserId);
}
