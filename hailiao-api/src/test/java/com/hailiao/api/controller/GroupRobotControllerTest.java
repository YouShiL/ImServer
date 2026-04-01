package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.GroupRobot;
import com.hailiao.common.entity.RobotCommand;
import com.hailiao.common.service.GroupRobotService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupRobotControllerTest {

    @Mock
    private GroupRobotService robotService;

    @InjectMocks
    private GroupRobotController groupRobotController;

    @Test
    void createRobotShouldReturnCreatedRobot() {
        GroupRobot robot = new GroupRobot();
        robot.setId(1L);
        robot.setGroupId(10L);
        robot.setName("小助手");
        robot.setDescription("群管理助手");

        when(robotService.createRobot(10L, "小助手", "群管理助手")).thenReturn(robot);

        Map<String, Object> request = new HashMap<String, Object>();
        request.put("groupId", 10L);
        request.put("name", "小助手");
        request.put("description", "群管理助手");

        ResponseEntity<ResponseDTO<GroupRobot>> response = groupRobotController.createRobot(1L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("小助手", response.getBody().getData().getName());
    }

    @Test
    void addCommandShouldReturnCreatedCommand() {
        RobotCommand command = new RobotCommand();
        command.setId(1L);
        command.setRobotId(1L);
        command.setCommand("/help");
        command.setResponseType(1);

        when(robotService.addCommand(1L, "/help", "帮助指令", 1, "帮助内容")).thenReturn(command);

        Map<String, Object> request = new HashMap<String, Object>();
        request.put("robotId", 1L);
        request.put("command", "/help");
        request.put("description", "帮助指令");
        request.put("responseType", 1);
        request.put("responseContent", "帮助内容");

        ResponseEntity<ResponseDTO<RobotCommand>> response = groupRobotController.addCommand(request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("/help", response.getBody().getData().getCommand());
    }

    @Test
    void getGroupRobotsShouldReturnList() {
        List<GroupRobot> robots = new ArrayList<GroupRobot>();
        GroupRobot robot = new GroupRobot();
        robot.setId(1L);
        robot.setGroupId(10L);
        robot.setName("机器人");
        robots.add(robot);

        when(robotService.getGroupRobots(10L)).thenReturn(robots);

        ResponseEntity<ResponseDTO<List<GroupRobot>>> response = groupRobotController.getGroupRobots(10L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
    }

    @Test
    void getRobotCommandsShouldReturnList() {
        List<RobotCommand> commands = new ArrayList<RobotCommand>();
        RobotCommand command = new RobotCommand();
        command.setId(1L);
        command.setRobotId(1L);
        command.setCommand("/help");
        commands.add(command);

        when(robotService.getRobotCommands(1L)).thenReturn(commands);

        ResponseEntity<ResponseDTO<List<RobotCommand>>> response = groupRobotController.getRobotCommands(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
    }

    @Test
    void setRobotEnabledShouldDelegateToService() {
        GroupRobot robot = new GroupRobot();
        robot.setId(1L);
        robot.setIsEnabled(true);
        when(robotService.setRobotEnabled(1L, true)).thenReturn(robot);

        Map<String, Object> request = new HashMap<String, Object>();
        request.put("enabled", true);

        ResponseEntity<ResponseDTO<GroupRobot>> response = groupRobotController.setRobotEnabled(1L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(robotService).setRobotEnabled(1L, true);
    }

    @Test
    void deleteRobotShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response = groupRobotController.deleteRobot(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(robotService).deleteRobot(1L);
    }
}
