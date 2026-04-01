package com.hailiao.api.controller;

import com.hailiao.api.dto.ReportDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.Report;
import com.hailiao.common.service.ReportService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportControllerTest {

    @Mock
    private ReportService reportService;

    @InjectMocks
    private ReportController reportController;

    @Test
    void createReportShouldRejectReportingSelfUser() {
        Map<String, Object> request = new HashMap<String, Object>();
        request.put("targetId", 1L);
        request.put("targetType", 1);
        request.put("reason", "违规");

        ResponseEntity<ResponseDTO<ReportDTO>> response = reportController.createReport(1L, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(400, response.getBody().getCode());
    }

    @Test
    void createReportShouldBuildAndReturnDto() {
        Map<String, Object> request = new HashMap<String, Object>();
        request.put("targetId", 2L);
        request.put("targetType", 2);
        request.put("reason", "违规");
        request.put("evidence", "截图");

        Report saved = new Report();
        saved.setId(10L);
        saved.setReporterId(1L);
        saved.setTargetId(2L);
        saved.setTargetType(2);
        saved.setReason("违规");
        saved.setEvidence("截图");
        saved.setStatus(0);

        when(reportService.createReport(org.mockito.ArgumentMatchers.any(Report.class))).thenReturn(saved);

        ResponseEntity<ResponseDTO<ReportDTO>> response = reportController.createReport(1L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("群组", response.getBody().getData().getTargetTypeLabel());
        assertEquals("待处理", response.getBody().getData().getStatusLabel());

        ArgumentCaptor<Report> captor = ArgumentCaptor.forClass(Report.class);
        verify(reportService).createReport(captor.capture());
        assertEquals(Long.valueOf(1L), captor.getValue().getReporterId());
    }

    @Test
    void getMyReportsShouldReturnLabeledDtos() {
        List<Report> reports = new ArrayList<Report>();
        Report report = new Report();
        report.setId(1L);
        report.setReporterId(1L);
        report.setTargetId(3L);
        report.setTargetType(3);
        report.setStatus(1);
        reports.add(report);

        when(reportService.getReporterReports(1L)).thenReturn(reports);

        ResponseEntity<ResponseDTO<List<ReportDTO>>> response = reportController.getMyReports(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("消息", response.getBody().getData().get(0).getTargetTypeLabel());
        assertEquals("已处理", response.getBody().getData().get(0).getStatusLabel());
    }
}
