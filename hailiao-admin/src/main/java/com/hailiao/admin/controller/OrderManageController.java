package com.hailiao.admin.controller;

import com.hailiao.common.entity.Order;
import com.hailiao.common.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 订单管理控制器。
 */
@RestController
@RequestMapping("/admin/order")
public class OrderManageController {

    @Autowired
    private OrderService orderService;

    /**
     * 分页获取订单列表。
     */
    @GetMapping("/list")
    public ResponseEntity<?> getOrderList(
            @RequestParam(required = false) String orderNo,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer payStatus,
            @RequestParam(required = false) Integer productType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<Order> orders = orderService.getOrderList(orderNo, userId, payStatus, productType, pageable);
            return ResponseEntity.ok(toOrderPageResponse(orders));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据 ID 获取订单详情。
     */
    @GetMapping("/{orderId}")
    public ResponseEntity<?> getOrderById(@PathVariable Long orderId) {
        try {
            Order order = orderService.getOrderById(orderId);
            return ResponseEntity.ok(toOrderResponse(order));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据订单号获取订单详情。
     */
    @GetMapping("/by-orderNo/{orderNo}")
    public ResponseEntity<?> getOrderByOrderNo(@PathVariable String orderNo) {
        try {
            Order order = orderService.getOrderByOrderNo(orderNo);
            return ResponseEntity.ok(toOrderResponse(order));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 取消订单。
     */
    @PostMapping("/{orderId}/cancel")
    public ResponseEntity<?> cancelOrder(@PathVariable Long orderId) {
        try {
            orderService.cancelOrder(orderId);
            return ResponseEntity.ok("订单取消成功");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取订单统计信息。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getOrderStats() {
        try {
            long totalOrders = orderService.getTotalOrderCount();
            long paidOrders = orderService.getPaidOrderCount();
            long unpaidOrders = Math.max(0L, totalOrders - paidOrders);
            Map<String, Object> stats = new LinkedHashMap<String, Object>();
            stats.put("totalOrders", totalOrders);
            stats.put("paidOrders", paidOrders);
            stats.put("unpaidOrders", unpaidOrders);
            stats.put("totalRevenue", orderService.getTotalRevenue());
            stats.put("summary", mapOf(
                    "paidLabel", "已支付",
                    "unpaidLabel", "未支付",
                    "paidRatio", totalOrders == 0 ? "0.00%" : String.format("%.2f%%", (paidOrders * 100.0) / totalOrders)
            ));
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toOrderPageResponse(Page<Order> orders) {
        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        long paidCount = 0L;
        long unpaidCount = 0L;
        for (Order order : orders.getContent()) {
            content.add(toOrderResponse(order));
            if (order.getPayStatus() != null && order.getPayStatus() == 1) {
                paidCount++;
            } else {
                unpaidCount++;
            }
        }

        Map<String, Object> summary = new LinkedHashMap<String, Object>();
        summary.put("filteredTotal", orders.getTotalElements());
        summary.put("currentPageCount", orders.getNumberOfElements());
        summary.put("paidCount", paidCount);
        summary.put("unpaidCount", unpaidCount);

        Map<String, Object> page = new LinkedHashMap<String, Object>();
        page.put("content", content);
        page.put("page", orders.getNumber());
        page.put("size", orders.getSize());
        page.put("totalElements", orders.getTotalElements());
        page.put("totalPages", orders.getTotalPages());
        page.put("first", orders.isFirst());
        page.put("last", orders.isLast());
        page.put("summary", summary);
        return page;
    }

    private Map<String, Object> toOrderResponse(Order order) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", order.getId());
        item.put("orderNo", order.getOrderNo());
        item.put("userId", order.getUserId());
        item.put("productType", order.getProductType());
        item.put("productTypeLabel", getProductTypeLabel(order.getProductType()));
        item.put("productName", order.getProductName());
        item.put("amount", order.getAmount());
        item.put("payType", order.getPayType());
        item.put("payTypeLabel", getPayTypeLabel(order.getPayType()));
        item.put("payStatus", order.getPayStatus());
        item.put("payStatusLabel", order.getPayStatus() != null && order.getPayStatus() == 1 ? "已支付" : "未支付");
        item.put("status", order.getStatus());
        item.put("statusLabel", getOrderStatusLabel(order.getStatus()));
        item.put("createdAt", order.getCreatedAt());
        item.put("payTime", order.getPayTime());
        return item;
    }

    private String getProductTypeLabel(Integer productType) {
        if (productType == null) {
            return "未知商品";
        }
        switch (productType) {
            case 1:
                return "VIP";
            case 2:
                return "靓号";
            default:
                return "未知商品";
        }
    }

    private String getPayTypeLabel(Integer payType) {
        if (payType == null) {
            return "未知支付方式";
        }
        switch (payType) {
            case 1:
                return "微信";
            case 2:
                return "支付宝";
            default:
                return "未知支付方式";
        }
    }

    private String getOrderStatusLabel(Integer status) {
        if (status == null || status == 0) {
            return "待处理";
        }
        if (status == 1) {
            return "已完成";
        }
        if (status == 2) {
            return "已取消";
        }
        return "未知";
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
