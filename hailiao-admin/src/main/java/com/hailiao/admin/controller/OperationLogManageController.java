package com.hailiao.admin.controller;

import com.hailiao.common.entity.OperationLog;
import com.hailiao.common.service.OperationLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * 后台操作日志管理控制器。
 */
@RestController
@RequestMapping("/admin/operation-log")
public class OperationLogManageController {

    @Autowired
    private OperationLogService operationLogService;

    /**
     * 分页获取操作日志列表。
     */
    @GetMapping("/list")
    public ResponseEntity<?> getLogList(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String module,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date startAt,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date endAt,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<OperationLog> logs = operationLogService.getLogList(userId, module, status, startAt, endAt, pageable);
            Map<String, Object> summary = operationLogService.getLogListSummary(userId, module, status, startAt, endAt);
            return ResponseEntity.ok(operationLogService.toPageResponse(logs, summary));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 导出操作日志列表。
     */
    @GetMapping("/export")
    public ResponseEntity<?> exportLogList(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String module,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date startAt,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date endAt) {
        try {
            Page<OperationLog> logs = operationLogService.getLogList(userId, module, status, startAt, endAt, Pageable.unpaged());
            String csv = buildLogCsv(logs.getContent());

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("text/csv; charset=UTF-8"));
            headers.set(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=operation-log.csv");
            return ResponseEntity.ok().headers(headers).body(csv);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取操作日志统计信息。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getStats() {
        try {
            return ResponseEntity.ok(operationLogService.getStats());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取已记录的模块列表。
     */
    @GetMapping("/modules")
    public ResponseEntity<?> getModules() {
        try {
            return ResponseEntity.ok(operationLogService.getModules());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private String buildLogCsv(List<OperationLog> logs) {
        StringBuilder builder = new StringBuilder();
        builder.append(csvRow("ID", "管理员", "模块", "操作", "描述", "状态", "IP", "耗时(ms)", "时间"));
        for (OperationLog log : logs) {
            builder.append(csvRow(
                    valueOf(log.getId()),
                    log.getUsername(),
                    operationLogService.getModuleLabel(log.getModule()),
                    operationLogService.getOperationTypeLabel(log.getOperationType()),
                    log.getDescription(),
                    log.getStatus() != null && log.getStatus() == 1 ? "成功" : "失败",
                    log.getIp(),
                    valueOf(log.getExecuteTime()),
                    formatDate(log.getCreatedAt())
            ));
        }
        return builder.toString();
    }

    private String csvRow(String... values) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < values.length; i++) {
            if (i > 0) {
                builder.append(",");
            }
            builder.append("\"").append(escapeCsv(values[i])).append("\"");
        }
        builder.append("\r\n");
        return builder.toString();
    }

    private String escapeCsv(String value) {
        return value == null ? "" : value.replace("\"", "\"\"");
    }

    private String formatDate(Date date) {
        if (date == null) {
            return "";
        }
        return new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(date);
    }

    private String valueOf(Object value) {
        return value == null ? "" : String.valueOf(value);
    }
}
