package com.hailiao.common.repository;

import com.hailiao.common.entity.Friend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRepository extends JpaRepository<Friend, Long>, JpaSpecificationExecutor<Friend> {
    List<Friend> findByUserId(Long userId);
    List<Friend> findByUserIdAndStatus(Long userId, Integer status);
    Optional<Friend> findByUserIdAndFriendId(Long userId, Long friendId);
    boolean existsByUserIdAndFriendId(Long userId, Long friendId);
    long countByUserIdAndStatus(Long userId, Integer status);
}