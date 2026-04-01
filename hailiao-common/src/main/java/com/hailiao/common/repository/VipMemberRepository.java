package com.hailiao.common.repository;

import com.hailiao.common.entity.VipMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Date;
import java.util.List;
import java.util.Optional;

@Repository
public interface VipMemberRepository extends JpaRepository<VipMember, Long> {
    Optional<VipMember> findByUserId(Long userId);
    List<VipMember> findByStatus(Integer status);
    List<VipMember> findByExpireTimeBefore(Date expireTime);
    long countByStatus(Integer status);
    long countByVipLevel(Integer vipLevel);
}