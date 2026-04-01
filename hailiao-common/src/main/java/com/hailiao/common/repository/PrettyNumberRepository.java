package com.hailiao.common.repository;

import com.hailiao.common.entity.PrettyNumber;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PrettyNumberRepository extends JpaRepository<PrettyNumber, Long>, JpaSpecificationExecutor<PrettyNumber> {
    Optional<PrettyNumber> findByNumber(String number);
    List<PrettyNumber> findByStatus(Integer status);
    List<PrettyNumber> findByLevel(Integer level);
    List<PrettyNumber> findByUserId(Long userId);
    long countByStatus(Integer status);
    long countByLevel(Integer level);
}