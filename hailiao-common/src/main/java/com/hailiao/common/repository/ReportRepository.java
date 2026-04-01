package com.hailiao.common.repository;

import com.hailiao.common.entity.Report;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReportRepository extends JpaRepository<Report, Long>, JpaSpecificationExecutor<Report> {
    List<Report> findByReporterId(Long reporterId);
    List<Report> findByTargetId(Long targetId);
    List<Report> findByStatus(Integer status);
    long countByStatus(Integer status);
}