package com.hailiao.common.repository;

import com.hailiao.common.entity.ContentAudit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContentAuditRepository extends JpaRepository<ContentAudit, Long>, JpaSpecificationExecutor<ContentAudit> {
    List<ContentAudit> findByStatus(Integer status);
    List<ContentAudit> findByContentType(Integer contentType);
    List<ContentAudit> findByUserId(Long userId);
    long countByStatus(Integer status);
    long countByAiResult(Integer aiResult);
}