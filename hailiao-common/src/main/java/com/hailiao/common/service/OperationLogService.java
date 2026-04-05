package com.hailiao.common.service;

import com.hailiao.common.entity.OperationLog;
import com.hailiao.common.repository.OperationLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import javax.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class OperationLogService {

    @Autowired
    private OperationLogRepository operationLogRepository;

    public void saveLog(OperationLog log) {
        log.setCreatedAt(new Date());
        operationLogRepository.save(log);
    }

    public Page<OperationLog> getLogList(
            Long userId,
            String module,
            Integer status,
            Date startAt,
            Date endAt,
            Pageable pageable) {
        Specification<OperationLog> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (userId != null) {
                predicates.add(cb.equal(root.get("userId"), userId));
            }
            if (module != null && !module.isEmpty()) {
                predicates.add(cb.equal(root.get("module"), module));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (startAt != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), startAt));
            }
            if (endAt != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), endAt));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return operationLogRepository.findAll(spec, pageable);
    }

    public List<OperationLog> getUserLogs(Long userId) {
        return operationLogRepository.findByUserId(userId);
    }

    public List<OperationLog> getModuleLogs(String module) {
        return operationLogRepository.findByModule(module);
    }

    public List<String> getModules() {
        return operationLogRepository.findDistinctModules();
    }

    public Map<String, Object> getStats() {
        Map<String, Object> stats = new HashMap<>();
        long total = operationLogRepository.count();
        long success = operationLogRepository.countByStatus(1);
        long failure = operationLogRepository.countByStatus(0);
        List<OperationLog> allLogs = operationLogRepository.findAll();

        stats.put("totalLogs", total);
        stats.put("successLogs", success);
        stats.put("failureLogs", failure);
        stats.put("moduleCount", getModules().size());
        stats.put("moduleStats", buildModuleStats(allLogs));
        stats.put("dailyTrend", buildRecentDailyTrend(allLogs, 7));
        return stats;
    }

    public Map<String, Object> toLogResponse(OperationLog log) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", log.getId());
        item.put("userId", log.getUserId());
        item.put("username", log.getUsername());
        item.put("operationType", log.getOperationType());
        item.put("operationTypeLabel", getOperationTypeLabel(log.getOperationType()));
        item.put("module", log.getModule());
        item.put("moduleLabel", getModuleLabel(log.getModule()));
        item.put("description", log.getDescription());
        item.put("requestMethod", log.getRequestMethod());
        item.put("requestUrl", log.getRequestUrl());
        item.put("requestParams", log.getRequestParams());
        item.put("responseData", log.getResponseData());
        item.put("ip", log.getIp());
        item.put("status", log.getStatus());
        item.put("statusLabel", log.getStatus() != null && log.getStatus() == 1 ? "成功" : "失败");
        item.put("errorMsg", log.getErrorMsg());
        item.put("executeTime", log.getExecuteTime());
        item.put("createdAt", log.getCreatedAt());
        return item;
    }

    public Map<String, Object> toPageResponse(Page<OperationLog> logs) {
        return toPageResponse(logs, null);
    }

    public Map<String, Object> toPageResponse(Page<OperationLog> logs, Map<String, Object> summary) {
        List<Map<String, Object>> content = new ArrayList<>();
        for (OperationLog log : logs.getContent()) {
            content.add(toLogResponse(log));
        }

        Map<String, Object> page = new LinkedHashMap<>();
        page.put("content", content);
        page.put("page", logs.getNumber());
        page.put("size", logs.getSize());
        page.put("totalElements", logs.getTotalElements());
        page.put("totalPages", logs.getTotalPages());
        page.put("first", logs.isFirst());
        page.put("last", logs.isLast());
        if (summary != null) {
            page.put("summary", summary);
        }
        return page;
    }

    public Map<String, Object> getLogListSummary(
            Long userId,
            String module,
            Integer status,
            Date startAt,
            Date endAt) {
        Page<OperationLog> page = getLogList(userId, module, status, startAt, endAt, Pageable.unpaged());
        List<OperationLog> logs = page.getContent();

        LinkedHashMap<String, Object> summary = new LinkedHashMap<>();
        summary.put("filteredTotal", logs.size());
        long successCount = logs.stream().filter(item -> item.getStatus() != null && item.getStatus() == 1).count();
        long failureCount = logs.stream().filter(item -> item.getStatus() != null && item.getStatus() == 0).count();
        summary.put("successCount", successCount);
        summary.put("failureCount", failureCount);
        summary.put("moduleStats", buildModuleStats(logs));
        return summary;
    }

    public String getModuleLabel(String module) {
        if (module == null) {
            return "未知模块";
        }
        switch (module) {
            case "admin-user":
                return "管理员管理";
            case "operation-log":
                return "操作日志";
            case "user":
                return "用户管理";
            case "group":
                return "群组管理";
            case "order":
                return "订单管理";
            case "report":
                return "举报管理";
            case "content-audit":
                return "内容审核";
            case "system-config":
                return "系统配置";
            case "vip":
                return "VIP 管理";
            case "pretty-number":
                return "靓号管理";
            case "message-monitor":
                return "消息监控";
            case "dashboard":
                return "仪表盘";
            case "statistics":
                return "统计分析";
            default:
                return module;
        }
    }

    public String getOperationTypeLabel(String operationType) {
        if (operationType == null) {
            return "未知操作";
        }
        switch (operationType) {
            case "ADMIN_CREATE":
                return "创建管理员";
            case "ADMIN_UPDATE":
                return "更新管理员";
            case "ADMIN_PERMISSION_UPDATE":
                return "更新管理员权限";
            case "ADMIN_PASSWORD_RESET":
                return "重置管理员密码";
            case "ADMIN_DELETE":
                return "删除管理员";
            case "CREATE_OR_ACTION":
                return "创建/执行操作";
            case "UPDATE":
                return "更新";
            case "DELETE":
                return "删除";
            default:
                return operationType;
        }
    }

    private List<Map<String, Object>> buildModuleStats(List<OperationLog> logs) {
        LinkedHashMap<String, Long> counts = new LinkedHashMap<>();
        for (String module : getModules()) {
            counts.put(module, 0L);
        }
        for (OperationLog log : logs) {
            String module = log.getModule() == null ? "unknown" : log.getModule();
            counts.put(module, counts.getOrDefault(module, 0L) + 1);
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (Map.Entry<String, Long> entry : counts.entrySet()) {
            LinkedHashMap<String, Object> item = new LinkedHashMap<>();
            item.put("module", entry.getKey());
            item.put("moduleLabel", getModuleLabel(entry.getKey()));
            item.put("count", entry.getValue());
            result.add(item);
        }
        return result;
    }

    private List<Map<String, Object>> buildRecentDailyTrend(List<OperationLog> logs, int days) {
        LinkedHashMap<String, Long> counts = new LinkedHashMap<>();
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);

        for (int i = days - 1; i >= 0; i--) {
            Calendar cursor = (Calendar) calendar.clone();
            cursor.add(Calendar.DAY_OF_MONTH, -i);
            counts.put(formatDay(cursor.getTime()), 0L);
        }

        for (OperationLog log : logs) {
            if (log.getCreatedAt() == null) {
                continue;
            }
            String key = formatDay(log.getCreatedAt());
            if (counts.containsKey(key)) {
                counts.put(key, counts.get(key) + 1);
            }
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (Map.Entry<String, Long> entry : counts.entrySet()) {
            LinkedHashMap<String, Object> item = new LinkedHashMap<>();
            item.put("date", entry.getKey());
            item.put("count", entry.getValue());
            result.add(item);
        }
        return result;
    }

    private String formatDay(Date date) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTime(date);
        int year = calendar.get(Calendar.YEAR);
        int month = calendar.get(Calendar.MONTH) + 1;
        int day = calendar.get(Calendar.DAY_OF_MONTH);
        return String.format("%04d-%02d-%02d", year, month, day);
    }
}
