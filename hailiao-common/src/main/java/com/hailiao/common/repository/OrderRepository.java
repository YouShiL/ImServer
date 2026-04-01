package com.hailiao.common.repository;

import com.hailiao.common.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long>, JpaSpecificationExecutor<Order> {
    Optional<Order> findByOrderNo(String orderNo);
    List<Order> findByUserId(Long userId);
    List<Order> findByUserIdAndPayStatus(Long userId, Integer payStatus);
    List<Order> findByPayStatus(Integer payStatus);
    long countByPayStatus(Integer payStatus);
}