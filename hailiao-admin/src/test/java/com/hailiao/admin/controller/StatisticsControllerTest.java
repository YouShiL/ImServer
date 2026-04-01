package com.hailiao.admin.controller;

import com.hailiao.common.service.StatisticsService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StatisticsControllerTest {

    @Mock
    private StatisticsService statisticsService;

    @InjectMocks
    private StatisticsController statisticsController;

    @Test
    void getSystemStatisticsReturnsServicePayload() {
        Map<String, Object> stats = new LinkedHashMap<String, Object>();
        stats.put("totalUsers", 100L);
        stats.put("summary", new LinkedHashMap<String, Object>());
        when(statisticsService.getSystemStatistics()).thenReturn(stats);

        ResponseEntity<Map<String, Object>> actual = statisticsController.getSystemStatistics();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertSame(stats, actual.getBody());
        verify(statisticsService).getSystemStatistics();
    }

    @Test
    void getMessageStatisticsReturnsDistributionPayload() {
        Map<String, Object> stats = new LinkedHashMap<String, Object>();
        stats.put("totalMessages", 50L);
        stats.put("distribution", new LinkedHashMap<String, Object>());
        when(statisticsService.getMessageStatistics()).thenReturn(stats);

        ResponseEntity<Map<String, Object>> actual = statisticsController.getMessageStatistics();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertSame(stats, actual.getBody());
        verify(statisticsService).getMessageStatistics();
    }
}
