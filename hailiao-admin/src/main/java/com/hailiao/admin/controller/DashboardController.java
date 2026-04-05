package com.hailiao.admin.controller;

import com.hailiao.common.service.ContentAuditService;
import com.hailiao.common.service.GroupChatService;
import com.hailiao.common.service.OrderService;
import com.hailiao.common.service.PrettyNumberService;
import com.hailiao.common.service.ReportService;
import com.hailiao.common.service.UserService;
import com.hailiao.common.service.VipMemberService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 仪表盘控制器。
 */
@RestController
@RequestMapping("/admin/dashboard")
public class DashboardController {

    @Autowired
    private UserService userService;

    @Autowired
    private GroupChatService groupChatService;

    @Autowired
    private OrderService orderService;

    @Autowired
    private ReportService reportService;

    @Autowired
    private ContentAuditService contentAuditService;

    @Autowired
    private VipMemberService vipMemberService;

    @Autowired
    private PrettyNumberService prettyNumberService;

    /**
     * 获取仪表盘统计数据。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getDashboardStats() {
        try {
            long totalUsers = userService.getTotalUserCount();
            long activeUsers = userService.getActiveUserCount();
            long totalGroups = groupChatService.getTotalGroupCount();
            long totalOrders = orderService.getTotalOrderCount();
            long pendingReports = reportService.getPendingReportCount();
            long pendingAudits = contentAuditService.getPendingAuditCount();
            long totalVips = vipMemberService.getTotalVipCount();
            long totalPrettyNumbers = prettyNumberService.getTotalPrettyNumberCount();
            long availablePrettyNumbers = prettyNumberService.getAvailablePrettyNumberCount();
            long soldPrettyNumbers = prettyNumberService.getSoldPrettyNumberCount();

            Map<String, Object> stats = new LinkedHashMap<String, Object>();
            stats.put("totalUsers", totalUsers);
            stats.put("activeUsers", activeUsers);
            stats.put("totalGroups", totalGroups);
            stats.put("totalOrders", totalOrders);
            stats.put("totalRevenue", orderService.getTotalRevenue());
            stats.put("pendingReports", pendingReports);
            stats.put("pendingAudits", pendingAudits);
            stats.put("totalVips", totalVips);
            stats.put("totalPrettyNumbers", totalPrettyNumbers);
            stats.put("availablePrettyNumbers", availablePrettyNumbers);
            stats.put("soldPrettyNumbers", soldPrettyNumbers);
            stats.put("summary", mapOf(
                    "userActivityRatio", totalUsers == 0 ? "0.00%" : String.format("%.2f%%", (activeUsers * 100.0) / totalUsers),
                    "prettyNumberSoldRatio", totalPrettyNumbers == 0 ? "0.00%" : String.format("%.2f%%", (soldPrettyNumbers * 100.0) / totalPrettyNumbers),
                    "pendingWorkItems", pendingReports + pendingAudits
            ));
            stats.put("cards", mapOf(
                    "users", mapOf("label", "用户", "value", totalUsers, "secondaryLabel", "活跃用户", "secondaryValue", activeUsers),
                    "groups", mapOf("label", "群组", "value", totalGroups, "secondaryLabel", "订单", "secondaryValue", totalOrders),
                    "compliance", mapOf("label", "待处理举报", "value", pendingReports, "secondaryLabel", "待审核内容", "secondaryValue", pendingAudits),
                    "commercial", mapOf("label", "VIP", "value", totalVips, "secondaryLabel", "已售靓号", "secondaryValue", soldPrettyNumbers)
            ));
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取实时统计数据。
     */
    @GetMapping("/realtime")
    public ResponseEntity<?> getRealtimeStats() {
        try {
            long onlineUsers = userService.getActiveUserCount();
            Map<String, Object> stats = new LinkedHashMap<String, Object>();
            stats.put("onlineUsers", onlineUsers);
            stats.put("newUsersToday", 0);
            stats.put("messagesToday", 0);
            stats.put("revenueToday", orderService.getTotalRevenue());
            stats.put("summary", mapOf(
                    "onlineUsersLabel", "在线用户",
                    "newUsersTodayLabel", "今日新增用户",
                    "messagesTodayLabel", "今日消息量",
                    "revenueTodayLabel", "今日收入"
            ));
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
