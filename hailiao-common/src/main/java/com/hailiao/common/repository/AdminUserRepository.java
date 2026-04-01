package com.hailiao.common.repository;

import com.hailiao.common.entity.AdminUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AdminUserRepository extends JpaRepository<AdminUser, Long>, JpaSpecificationExecutor<AdminUser> {
    Optional<AdminUser> findByUsername(String username);
    boolean existsByUsername(String username);
    long countByStatus(Integer status);
    long countByRole(Integer role);
}