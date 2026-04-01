package com.hailiao.common.service;

import com.hailiao.common.entity.Report;
import com.hailiao.common.repository.ReportRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Service
public class ReportService {

    @Autowired
    private ReportRepository reportRepository;

    @Transactional
    public Report createReport(Report report) {
        report.setStatus(0);
        report.setCreatedAt(new Date());
        return reportRepository.save(report);
    }

    public Report getReportById(Long id) {
        return reportRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("\u4e3e\u62a5\u4e0d\u5b58\u5728"));
    }

    public Page<Report> getReportList(Integer status, Integer targetType, Long handlerId, Pageable pageable) {
        Specification<Report> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (targetType != null) {
                predicates.add(cb.equal(root.get("targetType"), targetType));
            }

            if (handlerId != null) {
                predicates.add(cb.equal(root.get("handlerId"), handlerId));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return reportRepository.findAll(spec, pageable);
    }

    @Transactional
    public Report handleReport(Long reportId, Long handlerId, Integer status, String handleResult) {
        Report report = getReportById(reportId);
        report.setHandlerId(handlerId);
        report.setStatus(status);
        report.setHandleResult(handleResult);
        report.setHandledAt(new Date());
        return reportRepository.save(report);
    }

    public long getPendingReportCount() {
        return reportRepository.countByStatus(0);
    }

    public List<Report> getReporterReports(Long reporterId) {
        return reportRepository.findByReporterId(reporterId);
    }
}
