package com.hailiao.admin.controller;

import com.hailiao.common.entity.Order;
import com.hailiao.common.service.OrderService;
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
class OrderManageControllerTest {

    @Mock
    private OrderService orderService;

    @InjectMocks
    private OrderManageController orderManageController;

    @Test
    void getOrderListReturnsSummaryAndLabels() {
        Order order = new Order();
        order.setId(1L);
        order.setOrderNo("ORD-1");
        order.setProductType(1);
        order.setPayType(2);
        order.setPayStatus(1);
        order.setStatus(1);

        List<Order> orders = new ArrayList<Order>();
        orders.add(order);
        Page<Order> page = new PageImpl<Order>(orders, PageRequest.of(0, 20), 1);
        when(orderService.getOrderList(null, null, 1, 1, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending())))
                .thenReturn(page);

        ResponseEntity<?> actual = orderManageController.getOrderList(null, null, 1, 1, 0, 20);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1L, summary.get("filteredTotal"));
        assertEquals(1L, summary.get("paidCount"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("VIP", first.get("productTypeLabel"));
        assertEquals("支付宝", first.get("payTypeLabel"));
        assertEquals("已支付", first.get("payStatusLabel"));
        assertEquals("已完成", first.get("statusLabel"));
    }

    @Test
    void getOrderStatsReturnsSummaryBlock() {
        when(orderService.getTotalOrderCount()).thenReturn(12L);
        when(orderService.getPaidOrderCount()).thenReturn(9L);
        when(orderService.getTotalRevenue()).thenReturn(new java.math.BigDecimal("1888.00"));

        ResponseEntity<?> actual = orderManageController.getOrderStats();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals(12L, body.get("totalOrders"));
        assertEquals(9L, body.get("paidOrders"));
        assertEquals(3L, body.get("unpaidOrders"));
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals("已支付", summary.get("paidLabel"));
        verify(orderService).getTotalRevenue();
    }
}
