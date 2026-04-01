package com.hailiao.admin.controller;

import com.hailiao.common.entity.ContentAudit;
import com.hailiao.common.service.ContentAuditService;
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
 * 内容审核管理控制器。
 */
@RestController
@RequestMapping("/admin/content-audit")
public class ContentAuditManageController {

    @Autowired
    private ContentAuditService contentAuditService;

    /**
     * 分页获取审核列表。
     */
    @GetMapping("/list")
    public ResponseEntity<?> getAuditList(
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer contentType,
            @RequestParam(required = false) Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<ContentAudit> audits = contentAuditService.getAuditList(status, contentType, userId, pageable);
            return ResponseEntity.ok(toAuditPageResponse(audits));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据 ID 获取审核详情。
     */
    @GetMapping("/{auditId}")
    public ResponseEntity<?> getAuditById(@PathVariable Long auditId) {
        try {
            ContentAudit audit = contentAuditService.getAuditById(auditId);
            return ResponseEntity.ok(toAuditResponse(audit));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 手动处理审核结果。
     */
    @PostMapping("/{auditId}/handle")
    public ResponseEntity<?> handleAudit(
            @RequestAttribute("adminId") Long adminId,
            @PathVariable Long auditId,
            @RequestBody Map<String, Object> request) {
        try {
            Integer manualResult = Integer.valueOf(request.get("manualResult").toString());
            String handleNote = (String) request.get("handleNote");
            ContentAudit audit = contentAuditService.manualAudit(auditId, adminId, manualResult, handleNote);
            return ResponseEntity.ok(toAuditResponse(audit));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取审核统计信息。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getAuditStats() {
        try {
            Map<String, Long> stats = new HashMap<>();
            stats.put("pendingAudits", contentAuditService.getPendingAuditCount());
            stats.put("aiBlocked", contentAuditService.getAiBlockedCount());
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toAuditPageResponse(Page<ContentAudit> audits) {
        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        long pendingCount = 0L;
        long handledCount = 0L;
        for (ContentAudit audit : audits.getContent()) {
            content.add(toAuditResponse(audit));
            if (audit.getStatus() != null && audit.getStatus() == 0) {
                pendingCount++;
            } else {
                handledCount++;
            }
        }

        Map<String, Object> summary = new LinkedHashMap<String, Object>();
        summary.put("filteredTotal", audits.getTotalElements());
        summary.put("currentPageCount", audits.getNumberOfElements());
        summary.put("pendingCount", pendingCount);
        summary.put("handledCount", handledCount);

        Map<String, Object> page = new LinkedHashMap<String, Object>();
        page.put("content", content);
        page.put("page", audits.getNumber());
        page.put("size", audits.getSize());
        page.put("totalElements", audits.getTotalElements());
        page.put("totalPages", audits.getTotalPages());
        page.put("first", audits.isFirst());
        page.put("last", audits.isLast());
        page.put("summary", summary);
        return page;
    }

    private Map<String, Object> toAuditResponse(ContentAudit audit) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", audit.getId());
        item.put("contentType", audit.getContentType());
        item.put("contentTypeLabel", getContentTypeLabel(audit.getContentType()));
        item.put("targetId", audit.getTargetId());
        item.put("content", audit.getContent());
        item.put("userId", audit.getUserId());
        item.put("aiResult", audit.getAiResult());
        item.put("aiResultLabel", getAuditResultLabel(audit.getAiResult()));
        item.put("aiScore", audit.getAiScore());
        item.put("manualResult", audit.getManualResult());
        item.put("manualResultLabel", getAuditResultLabel(audit.getManualResult()));
        item.put("handlerId", audit.getHandlerId());
        item.put("handleNote", audit.getHandleNote());
        item.put("status", audit.getStatus());
        item.put("statusLabel", audit.getStatus() != null && audit.getStatus() == 1 ? "\u5df2\u5904\u7406" : "\u5f85\u5904\u7406");
        item.put("createdAt", audit.getCreatedAt());
        item.put("handledAt", audit.getHandledAt());
        return item;
    }

    private String getContentTypeLabel(Integer contentType) {
        if (contentType == null) {
            return "\u672a\u77e5\u5185\u5bb9";
        }
        switch (contentType) {
            case 1:
                return "\u6587\u672c";
            case 2:
                return "\u56fe\u7247";
            case 3:
                return "\u97f3\u9891";
            case 4:
                return "\u89c6\u9891";
            default:
                return "\u672a\u77e5\u5185\u5bb9";
        }
    }

    private String getAuditResultLabel(Integer result) {
        if (result == null) {
            return "\u672a\u5904\u7406";
        }
        switch (result) {
            case 1:
                return "\u901a\u8fc7";
            case 2:
                return "\u62e6\u622a";
            default:
                return "\u5f85\u5b9a";
        }
    }
}
