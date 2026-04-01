package com.hailiao.common.service;

import com.hailiao.common.entity.Order;
import com.hailiao.common.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.criteria.Predicate;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.UUID;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Transactional
    public Order createOrder(Long userId, Integer productType, Long productId, String productName, BigDecimal amount) {
        Order order = new Order();
        order.setOrderNo(generateOrderNo());
        order.setUserId(userId);
        order.setProductType(productType);
        order.setProductId(productId);
        order.setProductName(productName);
        order.setAmount(amount);
        order.setPayType(0);
        order.setPayStatus(0);
        order.setStatus(1);
        order.setCreatedAt(new Date());
        order.setUpdatedAt(new Date());

        return orderRepository.save(order);
    }

    public Order getOrderById(Long id) {
        return orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("\u8ba2\u5355\u4e0d\u5b58\u5728"));
    }

    public Order getOrderByOrderNo(String orderNo) {
        return orderRepository.findByOrderNo(orderNo)
                .orElseThrow(() -> new RuntimeException("\u8ba2\u5355\u4e0d\u5b58\u5728"));
    }

    public List<Order> getUserOrders(Long userId) {
        return orderRepository.findByUserId(userId);
    }

    public Page<Order> getOrderList(String orderNo, Long userId, Integer payStatus, Integer productType, Pageable pageable) {
        Specification<Order> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (orderNo != null && !orderNo.isEmpty()) {
                predicates.add(cb.like(root.get("orderNo"), "%" + orderNo + "%"));
            }

            if (userId != null) {
                predicates.add(cb.equal(root.get("userId"), userId));
            }

            if (payStatus != null) {
                predicates.add(cb.equal(root.get("payStatus"), payStatus));
            }

            if (productType != null) {
                predicates.add(cb.equal(root.get("productType"), productType));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return orderRepository.findAll(spec, pageable);
    }

    @Transactional
    public Order payOrder(Long orderId, Integer payType, String payNo) {
        Order order = getOrderById(orderId);
        if (order.getPayStatus() == 1) {
            throw new RuntimeException("\u8ba2\u5355\u5df2\u652f\u4ed8");
        }

        order.setPayType(payType);
        order.setPayStatus(1);
        order.setPayTime(new Date());
        order.setPayNo(payNo);
        order.setUpdatedAt(new Date());

        return orderRepository.save(order);
    }

    @Transactional
    public void cancelOrder(Long orderId) {
        Order order = getOrderById(orderId);
        if (order.getPayStatus() == 1) {
            throw new RuntimeException("\u5df2\u652f\u4ed8\u8ba2\u5355\u4e0d\u80fd\u53d6\u6d88");
        }
        order.setStatus(0);
        order.setUpdatedAt(new Date());
        orderRepository.save(order);
    }

    public BigDecimal getTotalRevenue() {
        List<Order> paidOrders = orderRepository.findByPayStatus(1);
        return paidOrders.stream()
                .map(Order::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public long getTotalOrderCount() {
        return orderRepository.count();
    }

    public long getPaidOrderCount() {
        return orderRepository.countByPayStatus(1);
    }

    private String generateOrderNo() {
        return "HL" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
