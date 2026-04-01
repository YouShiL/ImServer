package com.hailiao.common.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hailiao.common.entity.GroupRobot;
import com.hailiao.common.entity.Message;
import com.hailiao.common.entity.RobotCommand;
import com.hailiao.common.repository.GroupRobotRepository;
import com.hailiao.common.repository.RobotCommandRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.Collections;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupRobotServiceTest {

    @Mock
    private GroupRobotRepository robotRepository;

    @Mock
    private RobotCommandRepository commandRepository;

    @Mock
    private MessageService messageService;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private GroupRobotService groupRobotService;

    @Test
    void processGroupMessageShouldReturnFalseWhenNoRobotEnabled() {
        Message message = new Message();
        message.setGroupId(10L);
        message.setContent("/help");

        when(robotRepository.findByGroupIdAndIsEnabled(10L, true)).thenReturn(Collections.<GroupRobot>emptyList());

        assertFalse(groupRobotService.processGroupMessage(message));
    }

    @Test
    void processGroupMessageShouldTriggerTextCommand() {
        GroupRobot robot = new GroupRobot();
        robot.setId(7L);
        robot.setGroupId(10L);
        robot.setIsEnabled(true);

        RobotCommand command = new RobotCommand();
        command.setRobotId(7L);
        command.setCommand("/help");
        command.setResponseType(1);
        command.setResponseContent("robot response");
        command.setIsEnabled(true);

        Message message = new Message();
        message.setGroupId(10L);
        message.setFromUserId(3L);
        message.setContent("/help me");

        when(robotRepository.findByGroupIdAndIsEnabled(10L, true)).thenReturn(Arrays.asList(robot));
        when(commandRepository.findByRobotIdAndIsEnabled(7L, true)).thenReturn(Arrays.asList(command));

        boolean triggered = groupRobotService.processGroupMessage(message);

        assertTrue(triggered);
        verify(messageService).sendGroupMessage(-7L, 10L, "robot response", 1, null);
    }

    @Test
    void createRobotShouldGenerateDefaults() {
        when(robotRepository.save(any(GroupRobot.class))).thenAnswer(new org.mockito.stubbing.Answer<GroupRobot>() {
            @Override
            public GroupRobot answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (GroupRobot) invocation.getArgument(0);
            }
        });

        GroupRobot robot = groupRobotService.createRobot(10L, "helper", "group helper");

        assertEquals(Long.valueOf(10L), robot.getGroupId());
        assertEquals("helper", robot.getName());
        assertEquals("group helper", robot.getDescription());
        assertTrue(robot.getIsEnabled());
        assertNotNull(robot.getApiKey());
        assertFalse(robot.getApiKey().isEmpty());
        assertNotNull(robot.getCreatedAt());
    }

    @Test
    void addCommandShouldApplyEnabledDefaults() {
        when(commandRepository.save(any(RobotCommand.class))).thenAnswer(new org.mockito.stubbing.Answer<RobotCommand>() {
            @Override
            public RobotCommand answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (RobotCommand) invocation.getArgument(0);
            }
        });

        RobotCommand command = groupRobotService.addCommand(7L, "/ping", "ping command", 1, "pong");

        assertEquals(Long.valueOf(7L), command.getRobotId());
        assertEquals("/ping", command.getCommand());
        assertEquals(Integer.valueOf(1), command.getResponseType());
        assertEquals("pong", command.getResponseContent());
        assertTrue(command.getIsEnabled());
        assertNotNull(command.getCreatedAt());
    }

    @Test
    void setRobotEnabledShouldRejectMissingRobot() {
        when(robotRepository.findById(99L)).thenReturn(Optional.<GroupRobot>empty());

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        groupRobotService.setRobotEnabled(99L, false);
                    }
                });

        assertEquals("\u673a\u5668\u4eba\u4e0d\u5b58\u5728", error.getMessage());
    }

    @Test
    void setRobotEnabledShouldPersistUpdatedStatus() {
        GroupRobot robot = new GroupRobot();
        robot.setId(7L);
        robot.setIsEnabled(true);

        when(robotRepository.findById(7L)).thenReturn(Optional.of(robot));
        when(robotRepository.save(any(GroupRobot.class))).thenAnswer(new org.mockito.stubbing.Answer<GroupRobot>() {
            @Override
            public GroupRobot answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (GroupRobot) invocation.getArgument(0);
            }
        });

        GroupRobot saved = groupRobotService.setRobotEnabled(7L, false);

        assertFalse(saved.getIsEnabled());
        assertNotNull(saved.getUpdatedAt());
    }

    @Test
    void deleteRobotShouldDeleteCommandsFirst() {
        RobotCommand one = new RobotCommand();
        RobotCommand two = new RobotCommand();

        when(commandRepository.findByRobotId(7L)).thenReturn(Arrays.asList(one, two));

        groupRobotService.deleteRobot(7L);

        verify(commandRepository).deleteAll(eq(Arrays.asList(one, two)));
        verify(robotRepository).deleteById(7L);
    }
}
