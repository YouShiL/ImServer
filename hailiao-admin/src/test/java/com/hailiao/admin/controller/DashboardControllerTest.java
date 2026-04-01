package com.hailiao.admin.controller;

import com.hailiao.common.service.ContentAuditService;
import com.hailiao.common.service.GroupChatService;
import com.hailiao.common.service.OrderService;
import com.hailiao.common.service.PrettyNumberService;
import com.hailiao.common.service.ReportService;
import com.hailiao.common.service.UserService;
import com.hailiao.common.service.VipMemberService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DashboardControllerTest {

    @Mock
    private UserService userService;

    @Mock
    private GroupChatService groupChatService;

    @Mock
    private OrderService orderService;

    @Mock
    private ReportService reportService;

    @Mock
    private ContentAuditService contentAuditService;

    @Mock
    private VipMemberService vipMemberService;

    @Mock
    private PrettyNumberService prettyNumberService;

    @InjectMocks
    private DashboardController dashboardController;

    @Test
    void getDashboardStatsReturnsCardsAndSummary() {
        when(userService.getTotalUserCount()).thenReturn(100L);
        when(userService.getActiveUserCount()).thenReturn(40L);
        when(groupChatService.getTotalGroupCount()).thenReturn(12L);
        when(orderService.getTotalOrderCount()).thenReturn(30L);
        when(orderService.getTotalRevenue()).thenReturn(new BigDecimal("5200.00"));
        when(reportService.getPendingReportCount()).thenReturn(5L);
        when(contentAuditService.getPendingAuditCount()).thenReturn(7L);
        when(vipMemberService.getTotalVipCount()).thenReturn(18L);
        when(prettyNumberService.getTotalPrettyNumberCount()).thenReturn(20L);
        when(prettyNumberService.getAvailablePrettyNumberCount()).thenReturn(8L);
        when(prettyNumberService.getSoldPrettyNumberCount()).thenReturn(12L);

        ResponseEntity<?> actual = dashboardController.getDashboardStats();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(12L, summary.get("pendingWorkItems"));
        Map<?, ?> cards = assertInstanceOf(Map.class, body.get("cards"));
        Map<?, ?> userCard = assertInstanceOf(Map.class, cards.get("users"));
        assertEquals("用户", userCard.get("label"));
        assertEquals(100L, userCard.get("value"));
    }

    @Test
    void getRealtimeStatsReturnsSummaryLabels() {
        when(userService.getActiveUserCount()).thenReturn(23L);
        when(orderService.getTotalRevenue()).thenReturn(new BigDecimal("199.00"));

        ResponseEntity<?> actual = dashboardController.getRealtimeStats();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals(23L, body.get("onlineUsers"));
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals("在线用户", summary.get("onlineUsersLabel"));
    }
}
