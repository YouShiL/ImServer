package com.hailiao.common.repository;

import com.hailiao.common.entity.RobotCommand;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 机器人指令数据访问接口。
 */
@Repository
public interface RobotCommandRepository extends JpaRepository<RobotCommand, Long> {

    /**
     * 根据机器人 ID 查询全部指令。
     */
    List<RobotCommand> findByRobotId(Long robotId);

    /**
     * 根据机器人 ID 和启用状态查询指令。
     */
    List<RobotCommand> findByRobotIdAndIsEnabled(Long robotId, Boolean isEnabled);

    /**
     * 根据机器人 ID 和指令名称查询指令。
     */
    Optional<RobotCommand> findByRobotIdAndCommand(Long robotId, String command);
}
