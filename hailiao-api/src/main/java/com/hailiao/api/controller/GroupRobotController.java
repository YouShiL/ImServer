package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.GroupRobot;
import com.hailiao.common.entity.RobotCommand;
import com.hailiao.common.service.GroupRobotService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 群机器人控制器
 * 处理群机器人的创建、配置和管理
 * 
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Tag(name = "群机器人管理", description = "群机器人相关接口 - 创建机器人、配置指令、管理机器人")
@RestController
@RequestMapping("/api/robot")
public class GroupRobotController {

    @Autowired
    private GroupRobotService robotService;

    @Operation(summary = "创建群机器人", description = "为指定群组创建一个新的机器人")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "创建成功"),
        @ApiResponse(responseCode = "400", description = "创建失败，参数错误"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/create")
    public ResponseEntity<ResponseDTO<GroupRobot>> createRobot(
            @RequestAttribute("userId") Long userId,
            @Parameter(name = "request", description = "创建机器人请求参数", required = true,
                    example = "{\"groupId\": 1, \"name\": \"小助手\", \"description\": \"群管理助手\"}") 
            @RequestBody Map<String, Object> request) {
        try {
            Long groupId = Long.valueOf(request.get("groupId").toString());
            String name = (String) request.get("name");
            String description = (String) request.get("description");
            
            GroupRobot robot = robotService.createRobot(groupId, name, description);
            return ResponseEntity.ok(ResponseDTO.success(robot));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "添加机器人指令", description = "为机器人添加一个新指令")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "添加成功"),
        @ApiResponse(responseCode = "400", description = "添加失败，参数错误"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/command/add")
    public ResponseEntity<ResponseDTO<RobotCommand>> addCommand(
            @Parameter(name = "request", description = "添加指令请求参数", required = true,
                    example = "{\"robotId\": 1, \"command\": \"/help\", \"description\": \"帮助指令\", \"responseType\": 1, \"responseContent\": \"这是帮助信息\"}") 
            @RequestBody Map<String, Object> request) {
        try {
            Long robotId = Long.valueOf(request.get("robotId").toString());
            String command = (String) request.get("command");
            String description = (String) request.get("description");
            Integer responseType = Integer.valueOf(request.get("responseType").toString());
            String responseContent = (String) request.get("responseContent");
            
            RobotCommand robotCommand = robotService.addCommand(robotId, command, description, responseType, responseContent);
            return ResponseEntity.ok(ResponseDTO.success(robotCommand));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "获取群组机器人列表", description = "获取指定群组的所有机器人")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @GetMapping("/group/{groupId}")
    public ResponseEntity<ResponseDTO<List<GroupRobot>>> getGroupRobots(
            @Parameter(name = "groupId", description = "群组ID", required = true, example = "1") 
            @PathVariable Long groupId) {
        try {
            List<GroupRobot> robots = robotService.getGroupRobots(groupId);
            return ResponseEntity.ok(ResponseDTO.success(robots));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "获取机器人指令列表", description = "获取指定机器人的所有指令")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @GetMapping("/{robotId}/commands")
    public ResponseEntity<ResponseDTO<List<RobotCommand>>> getRobotCommands(
            @Parameter(name = "robotId", description = "机器人ID", required = true, example = "1") 
            @PathVariable Long robotId) {
        try {
            List<RobotCommand> commands = robotService.getRobotCommands(robotId);
            return ResponseEntity.ok(ResponseDTO.success(commands));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "启用/禁用机器人", description = "设置机器人的启用状态")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "设置成功"),
        @ApiResponse(responseCode = "400", description = "设置失败，机器人不存在"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/{robotId}/enabled")
    public ResponseEntity<ResponseDTO<GroupRobot>> setRobotEnabled(
            @Parameter(name = "robotId", description = "机器人ID", required = true, example = "1") 
            @PathVariable Long robotId,
            @Parameter(name = "request", description = "启用状态请求参数", required = true,
                    example = "{\"enabled\": true}") 
            @RequestBody Map<String, Object> request) {
        try {
            Boolean enabled = (Boolean) request.get("enabled");
            GroupRobot robot = robotService.setRobotEnabled(robotId, enabled);
            return ResponseEntity.ok(ResponseDTO.success(robot));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "删除机器人", description = "删除指定的机器人及其所有指令")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "删除成功"),
        @ApiResponse(responseCode = "400", description = "删除失败，机器人不存在"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @DeleteMapping("/{robotId}")
    public ResponseEntity<ResponseDTO<String>> deleteRobot(
            @Parameter(name = "robotId", description = "机器人ID", required = true, example = "1") 
            @PathVariable Long robotId) {
        try {
            robotService.deleteRobot(robotId);
            return ResponseEntity.ok(ResponseDTO.success("删除成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }
}
