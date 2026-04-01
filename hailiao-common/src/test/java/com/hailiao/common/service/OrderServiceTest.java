package com.hailiao.common.service;

import com.hailiao.common.entity.Order;
import com.hailiao.common.repository.OrderRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Date;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderService orderService;

    @Test
    void createOrderShouldApplyDefaultStatusValues() {
        when(orderRepository.save(any(Order.class))).thenAnswer(new org.mockito.stubbing.Answer<Order>() {
            @Override
            public Order answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (Order) invocation.getArgument(0);
            }
        });

        Order order = orderService.createOrder(1L, 2, 3L, "VIP", new BigDecimal("88.00"));

        assertNotNull(order.getOrderNo());
        assertEquals(Integer.valueOf(0), order.getPayType());
        assertEquals(Integer.valueOf(0), order.getPayStatus());
        assertEquals(Integer.valueOf(1), order.getStatus());
        assertNotNull(order.getCreatedAt());
    }

    @Test
    void payOrderShouldRejectAlreadyPaidOrder() {
        Order order = new Order();
        order.setId(1L);
        order.setPayStatus(1);

        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        orderService.payOrder(1L, 2, "PAY001");
                    }
                });

        assertEquals("\u8ba2\u5355\u5df2\u652f\u4ed8", error.getMessage());
    }

    @Test
    void cancelOrderShouldRejectPaidOrder() {
        Order order = new Order();
        order.setId(1L);
        order.setPayStatus(1);

        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        orderService.cancelOrder(1L);
                    }
                });

        assertEquals("\u5df2\u652f\u4ed8\u8ba2\u5355\u4e0d\u80fd\u53d6\u6d88", error.getMessage());
    }

    @Test
    void getTotalRevenueShouldSumPaidOrders() {
        Order one = new Order();
        one.setAmount(new BigDecimal("12.50"));
        Order two = new Order();
        two.setAmount(new BigDecimal("87.50"));

        when(orderRepository.findByPayStatus(1)).thenReturn(Arrays.asList(one, two));

        BigDecimal revenue = orderService.getTotalRevenue();

        assertEquals(new BigDecimal("100.00"), revenue);
    }
}
