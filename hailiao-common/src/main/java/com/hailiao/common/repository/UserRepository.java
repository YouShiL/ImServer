package com.hailiao.common.repository;

import com.hailiao.common.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {
    Optional<User> findByPhone(String phone);
    Optional<User> findByUserId(String userId);
    boolean existsByPhone(String phone);
    boolean existsByUserId(String userId);
    long countByStatus(Integer status);
    Page<User> findByUserIdContainingOrNicknameContainingOrPhoneContaining(
            String userId, String nickname, String phone, Pageable pageable);
}