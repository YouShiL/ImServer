package com.hailiao.common.repository;

import com.hailiao.common.entity.OperationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OperationLogRepository extends JpaRepository<OperationLog, Long>, JpaSpecificationExecutor<OperationLog> {
    List<OperationLog> findByUserId(Long userId);
    List<OperationLog> findByModule(String module);
    List<OperationLog> findByStatus(Integer status);
    long countByStatus(Integer status);

    @Query("select distinct o.module from OperationLog o where o.module is not null and o.module <> '' order by o.module")
    List<String> findDistinctModules();
}
