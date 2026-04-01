package com.hailiao.common.service;

import com.hailiao.common.entity.Report;
import com.hailiao.common.repository.ReportRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportServiceTest {

    @Mock
    private ReportRepository reportRepository;

    @InjectMocks
    private ReportService reportService;

    @Test
    void createReportShouldApplyPendingStatusAndCreatedAt() {
        when(reportRepository.save(any(Report.class))).thenAnswer(new org.mockito.stubbing.Answer<Report>() {
            @Override
            public Report answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (Report) invocation.getArgument(0);
            }
        });

        Report report = new Report();
        report.setReporterId(1L);
        report.setTargetId(2L);
        report.setTargetType(1);

        Report saved = reportService.createReport(report);

        assertEquals(Integer.valueOf(0), saved.getStatus());
        assertNotNull(saved.getCreatedAt());
    }

    @Test
    void getReportByIdShouldThrowWhenMissing() {
        when(reportRepository.findById(1L)).thenReturn(Optional.<Report>empty());

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        reportService.getReportById(1L);
                    }
                });

        assertEquals("举报不存在", error.getMessage());
    }

    @Test
    void handleReportShouldUpdateHandlerStatusAndResult() {
        Report report = new Report();
        report.setId(1L);
        report.setStatus(0);

        when(reportRepository.findById(1L)).thenReturn(Optional.of(report));
        when(reportRepository.save(any(Report.class))).thenAnswer(new org.mockito.stubbing.Answer<Report>() {
            @Override
            public Report answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (Report) invocation.getArgument(0);
            }
        });

        Report saved = reportService.handleReport(1L, 9L, 1, "已处理");

        assertEquals(Long.valueOf(9L), saved.getHandlerId());
        assertEquals(Integer.valueOf(1), saved.getStatus());
        assertEquals("已处理", saved.getHandleResult());
        assertNotNull(saved.getHandledAt());
    }

    @Test
    void getReporterReportsShouldDelegateToRepository() {
        List<Report> reports = Arrays.asList(new Report());
        when(reportRepository.findByReporterId(1L)).thenReturn(reports);

        List<Report> result = reportService.getReporterReports(1L);

        assertEquals(1, result.size());
        verify(reportRepository).findByReporterId(1L);
    }
}
