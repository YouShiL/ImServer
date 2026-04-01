package com.hailiao.admin.controller;

import com.hailiao.common.entity.Report;
import com.hailiao.common.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 举报管理控制器。
 */
@RestController
@RequestMapping("/admin/report")
public class ReportManageController {

    @Autowired
    private ReportService reportService;

    /**
     * 分页获取举报列表。
     */
    @GetMapping("/list")
    public ResponseEntity<?> getReportList(
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer targetType,
            @RequestParam(required = false) Long handlerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<Report> reports = reportService.getReportList(status, targetType, handlerId, pageable);
            return ResponseEntity.ok(toReportPageResponse(reports));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据 ID 获取举报详情。
     */
    @GetMapping("/{reportId}")
    public ResponseEntity<?> getReportById(@PathVariable Long reportId) {
        try {
            Report report = reportService.getReportById(reportId);
            return ResponseEntity.ok(toReportResponse(report));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 处理举报。
     */
    @PostMapping("/{reportId}/handle")
    public ResponseEntity<?> handleReport(
            @RequestAttribute("adminId") Long adminId,
            @PathVariable Long reportId,
            @RequestBody Map<String, Object> request) {
        try {
            Integer status = Integer.valueOf(request.get("status").toString());
            String handleResult = (String) request.get("handleResult");
            Report report = reportService.handleReport(reportId, adminId, status, handleResult);
            return ResponseEntity.ok(toReportResponse(report));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取举报统计信息。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getReportStats() {
        try {
            Map<String, Long> stats = new HashMap<>();
            stats.put("pendingReports", reportService.getPendingReportCount());
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toReportPageResponse(Page<Report> reports) {
        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        long pendingCount = 0L;
        long handledCount = 0L;
        for (Report report : reports.getContent()) {
            content.add(toReportResponse(report));
            if (report.getStatus() != null && report.getStatus() == 0) {
                pendingCount++;
            } else {
                handledCount++;
            }
        }

        Map<String, Object> summary = new LinkedHashMap<String, Object>();
        summary.put("filteredTotal", reports.getTotalElements());
        summary.put("currentPageCount", reports.getNumberOfElements());
        summary.put("pendingCount", pendingCount);
        summary.put("handledCount", handledCount);

        Map<String, Object> page = new LinkedHashMap<String, Object>();
        page.put("content", content);
        page.put("page", reports.getNumber());
        page.put("size", reports.getSize());
        page.put("totalElements", reports.getTotalElements());
        page.put("totalPages", reports.getTotalPages());
        page.put("first", reports.isFirst());
        page.put("last", reports.isLast());
        page.put("summary", summary);
        return page;
    }

    private Map<String, Object> toReportResponse(Report report) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", report.getId());
        item.put("reporterId", report.getReporterId());
        item.put("targetId", report.getTargetId());
        item.put("targetType", report.getTargetType());
        item.put("targetTypeLabel", getTargetTypeLabel(report.getTargetType()));
        item.put("reason", report.getReason());
        item.put("evidence", report.getEvidence());
        item.put("status", report.getStatus());
        item.put("statusLabel", getReportStatusLabel(report.getStatus()));
        item.put("handlerId", report.getHandlerId());
        item.put("handleResult", report.getHandleResult());
        item.put("createdAt", report.getCreatedAt());
        item.put("handledAt", report.getHandledAt());
        return item;
    }

    private String getTargetTypeLabel(Integer targetType) {
        if (targetType == null) {
            return "\u672a\u77e5\u5bf9\u8c61";
        }
        switch (targetType) {
            case 1:
                return "\u7528\u6237";
            case 2:
                return "\u7fa4\u7ec4";
            case 3:
                return "\u6d88\u606f";
            default:
                return "\u672a\u77e5\u5bf9\u8c61";
        }
    }

    private String getReportStatusLabel(Integer status) {
        if (status == null || status == 0) {
            return "\u5f85\u5904\u7406";
        }
        if (status == 1) {
            return "\u5df2\u5904\u7406";
        }
        if (status == 2) {
            return "\u5df2\u9a73\u56de";
        }
        return "\u672a\u77e5";
    }
}
