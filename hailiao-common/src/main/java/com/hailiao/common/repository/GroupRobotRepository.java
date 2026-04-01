package com.hailiao.common.repository;

import com.hailiao.common.entity.GroupRobot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 群机器人数据访问接口。
 */
@Repository
public interface GroupRobotRepository extends JpaRepository<GroupRobot, Long> {

    /**
     * 根据群组 ID 查询机器人列表。
     */
    List<GroupRobot> findByGroupId(Long groupId);

    /**
     * 根据群组 ID 和启用状态查询机器人。
     */
    List<GroupRobot> findByGroupIdAndIsEnabled(Long groupId, Boolean isEnabled);

    /**
     * 根据 API Key 查询机器人。
     */
    Optional<GroupRobot> findByApiKey(String apiKey);
}
