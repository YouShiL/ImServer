package com.hailiao.admin.controller;

import com.hailiao.common.entity.OperationLog;
import com.hailiao.common.service.OperationLogService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OperationLogManageControllerTest {

    @Mock
    private OperationLogService operationLogService;

    @InjectMocks
    private OperationLogManageController operationLogManageController;

    @Test
    void getLogListReturnsLabeledPageResponse() {
        OperationLog log = new OperationLog();
        log.setId(1L);

        List<OperationLog> logs = new ArrayList<OperationLog>();
        logs.add(log);
        Page<OperationLog> page = new PageImpl<OperationLog>(
                logs,
                PageRequest.of(0, 20, Sort.by("createdAt").descending()),
                1
        );

        Map<String, Object> summary = mapOf(
                "filteredTotal", 1,
                "successCount", 1,
                "failureCount", 0
        );

        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        content.add(mapOf("id", 1L, "moduleLabel", "\u7ba1\u7406\u5458\u7ba1\u7406"));

        Map<String, Object> response = new LinkedHashMap<String, Object>();
        response.put("content", content);
        response.put("page", 0);
        response.put("summary", summary);

        when(operationLogService.getLogList(null, "admin-user", 1, null, null,
                PageRequest.of(0, 20, Sort.by("createdAt").descending()))).thenReturn(page);
        when(operationLogService.getLogListSummary(null, "admin-user", 1, null, null)).thenReturn(summary);
        when(operationLogService.toPageResponse(page, summary)).thenReturn(response);

        ResponseEntity<?> actual = operationLogManageController.getLogList(null, "admin-user", 1, null, null, 0, 20);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertSame(response.get("content"), body.get("content"));
        assertSame(summary, body.get("summary"));
        verify(operationLogService).getLogListSummary(null, "admin-user", 1, null, null);
        verify(operationLogService).toPageResponse(page, summary);
    }

    @Test
    void exportLogListReturnsCsvAttachment() {
        OperationLog log = new OperationLog();
        log.setId(2L);
        log.setUsername("root");
        log.setModule("admin-user");
        log.setOperationType("ADMIN_UPDATE");
        log.setDescription("\u66f4\u65b0\u7ba1\u7406\u5458\u4fe1\u606f");
        log.setStatus(1);

        List<OperationLog> logs = new ArrayList<OperationLog>();
        logs.add(log);
        Page<OperationLog> page = new PageImpl<OperationLog>(logs);

        when(operationLogService.getLogList(null, null, null, null, null, org.springframework.data.domain.Pageable.unpaged()))
                .thenReturn(page);
        when(operationLogService.getModuleLabel("admin-user")).thenReturn("\u7ba1\u7406\u5458\u7ba1\u7406");
        when(operationLogService.getOperationTypeLabel("ADMIN_UPDATE")).thenReturn("\u66f4\u65b0\u7ba1\u7406\u5458");

        ResponseEntity<?> actual = operationLogManageController.exportLogList(null, null, null, null, null);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION)).contains("operation-log.csv"));
        assertTrue(String.valueOf(actual.getBody()).contains("\u66f4\u65b0\u7ba1\u7406\u5458\u4fe1\u606f"));
    }

    @Test
    void getStatsReturnsDashboardBreakdown() {
        List<Map<String, Object>> moduleStats = new ArrayList<Map<String, Object>>();
        moduleStats.add(mapOf("module", "admin-user", "count", 4));

        List<Map<String, Object>> dailyTrend = new ArrayList<Map<String, Object>>();
        dailyTrend.add(mapOf("date", "2026-03-30", "count", 2));

        Map<String, Object> stats = new LinkedHashMap<String, Object>();
        stats.put("totalLogs", 10L);
        stats.put("successLogs", 8L);
        stats.put("failureLogs", 2L);
        stats.put("moduleCount", 3);
        stats.put("moduleStats", moduleStats);
        stats.put("dailyTrend", dailyTrend);

        when(operationLogService.getStats()).thenReturn(stats);

        ResponseEntity<?> actual = operationLogManageController.getStats();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertSame(stats, actual.getBody());
        verify(operationLogService).getStats();
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
