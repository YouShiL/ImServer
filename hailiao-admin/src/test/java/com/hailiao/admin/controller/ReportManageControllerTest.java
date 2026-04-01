package com.hailiao.admin.controller;

import com.hailiao.common.entity.Report;
import com.hailiao.common.service.ReportService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportManageControllerTest {

    @Mock
    private ReportService reportService;

    @InjectMocks
    private ReportManageController reportManageController;

    @Test
    void getReportListReturnsSummaryAndLabels() {
        Report report = new Report();
        report.setId(3L);
        report.setTargetType(2);
        report.setStatus(0);

        List<Report> reports = new ArrayList<Report>();
        reports.add(report);
        Page<Report> page = new PageImpl<Report>(reports, PageRequest.of(0, 20), 1);
        when(reportService.getReportList(0, 2, null, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending())))
                .thenReturn(page);

        ResponseEntity<?> actual = reportManageController.getReportList(0, 2, null, 0, 20);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1L, summary.get("filteredTotal"));
        assertEquals(1L, summary.get("pendingCount"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("群组", first.get("targetTypeLabel"));
        assertEquals("待处理", first.get("statusLabel"));
    }

    @Test
    void handleReportReturnsLabeledResponse() {
        Report report = new Report();
        report.setId(5L);
        report.setTargetType(3);
        report.setStatus(1);
        report.setHandleResult("已处理");
        when(reportService.handleReport(5L, 9L, 1, "已处理")).thenReturn(report);

        ResponseEntity<?> actual = reportManageController.handleReport(9L, 5L, mapOf("status", 1, "handleResult", "已处理"));

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals("消息", body.get("targetTypeLabel"));
        assertEquals("已处理", body.get("statusLabel"));
        verify(reportService).handleReport(5L, 9L, 1, "已处理");
    }

    private Map<String, Object> mapOf(Object... values) {
        java.util.LinkedHashMap<String, Object> map = new java.util.LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
