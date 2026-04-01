package com.hailiao.admin.controller;

import com.hailiao.common.service.StatisticsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 统计数据控制器。
 */
@RestController
@RequestMapping("/admin/statistics")
public class StatisticsController {

    @Autowired
    private StatisticsService statisticsService;

    /**
     * 获取系统统计数据。
     */
    @GetMapping("/system")
    public ResponseEntity<Map<String, Object>> getSystemStatistics() {
        Map<String, Object> stats = statisticsService.getSystemStatistics();
        return ResponseEntity.ok(stats);
    }

    /**
     * 获取用户统计数据。
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<Map<String, Object>> getUserStatistics(@PathVariable Long userId) {
        Map<String, Object> stats = statisticsService.getUserStatistics(userId);
        return ResponseEntity.ok(stats);
    }

    /**
     * 获取消息统计数据。
     */
    @GetMapping("/messages")
    public ResponseEntity<Map<String, Object>> getMessageStatistics() {
        Map<String, Object> stats = statisticsService.getMessageStatistics();
        return ResponseEntity.ok(stats);
    }

    /**
     * 获取群组统计数据。
     */
    @GetMapping("/group/{groupId}")
    public ResponseEntity<Map<String, Object>> getGroupStatistics(@PathVariable Long groupId) {
        Map<String, Object> stats = statisticsService.getGroupStatistics(groupId);
        return ResponseEntity.ok(stats);
    }
}
