package com.hailiao.common.service;

import com.hailiao.common.entity.OperationLog;
import com.hailiao.common.repository.OperationLogRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OperationLogServiceTest {

    @Mock
    private OperationLogRepository operationLogRepository;

    @InjectMocks
    private OperationLogService operationLogService;

    @Test
    void saveLogShouldSetCreatedAtBeforePersisting() {
        OperationLog log = new OperationLog();
        log.setModule("admin-user");
        log.setOperationType("ADMIN_CREATE");

        operationLogService.saveLog(log);

        ArgumentCaptor<OperationLog> captor = ArgumentCaptor.forClass(OperationLog.class);
        verify(operationLogRepository).save(captor.capture());
        assertNotNull(captor.getValue().getCreatedAt());
    }

    @Test
    void getStatsShouldBuildModuleStatsAndDailyTrend() {
        OperationLog first = new OperationLog();
        first.setModule("admin-user");
        first.setStatus(1);
        first.setCreatedAt(new Date());

        OperationLog second = new OperationLog();
        second.setModule("report");
        second.setStatus(0);
        second.setCreatedAt(new Date());

        when(operationLogRepository.count()).thenReturn(2L);
        when(operationLogRepository.countByStatus(1)).thenReturn(1L);
        when(operationLogRepository.countByStatus(0)).thenReturn(1L);
        when(operationLogRepository.findAll()).thenReturn(Arrays.asList(first, second));
        when(operationLogRepository.findDistinctModules()).thenReturn(Arrays.asList("admin-user", "report"));

        Map<String, Object> stats = operationLogService.getStats();

        assertEquals(2L, stats.get("totalLogs"));
        assertEquals(1L, stats.get("successLogs"));
        assertEquals(1L, stats.get("failureLogs"));
        assertEquals(2, stats.get("moduleCount"));
        assertTrue(((List<?>) stats.get("moduleStats")).size() >= 2);
        assertEquals(7, ((List<?>) stats.get("dailyTrend")).size());
    }

    @Test
    void toLogResponseShouldIncludeChineseLabels() {
        OperationLog log = new OperationLog();
        log.setId(1L);
        log.setUserId(2L);
        log.setUsername("admin");
        log.setOperationType("ADMIN_PERMISSION_UPDATE");
        log.setModule("admin-user");
        log.setDescription("update permissions");
        log.setStatus(1);
        log.setCreatedAt(new Date());

        Map<String, Object> response = operationLogService.toLogResponse(log);

        assertEquals("\u66f4\u65b0\u7ba1\u7406\u5458\u6743\u9650", response.get("operationTypeLabel"));
        assertEquals("\u7ba1\u7406\u5458\u7ba1\u7406", response.get("moduleLabel"));
        assertEquals("\u6210\u529f", response.get("statusLabel"));
    }

    @Test
    void toPageResponseShouldKeepSummaryAndContent() {
        OperationLog log = new OperationLog();
        log.setId(1L);
        log.setModule("report");
        log.setOperationType("UPDATE");
        log.setStatus(0);

        List<OperationLog> logs = new ArrayList<OperationLog>();
        logs.add(log);
        Page<OperationLog> page = new PageImpl<OperationLog>(logs, PageRequest.of(0, 10), 1);

        Map<String, Object> summary = new LinkedHashMap<String, Object>();
        summary.put("filteredTotal", 1);

        Map<String, Object> response = operationLogService.toPageResponse(page, summary);

        assertEquals(1L, response.get("totalElements"));
        assertEquals(summary, response.get("summary"));
        assertEquals(1, ((List<?>) response.get("content")).size());
    }
}
