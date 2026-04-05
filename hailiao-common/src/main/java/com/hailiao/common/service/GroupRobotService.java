package com.hailiao.common.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hailiao.common.entity.GroupRobot;
import com.hailiao.common.entity.Message;
import com.hailiao.common.entity.RobotCommand;
import com.hailiao.common.repository.GroupRobotRepository;
import com.hailiao.common.repository.RobotCommandRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class GroupRobotService {

    private static final Logger logger = LoggerFactory.getLogger(GroupRobotService.class);

    @Autowired
    private GroupRobotRepository robotRepository;

    @Autowired
    private RobotCommandRepository commandRepository;

    @Autowired
    @Lazy
    private MessageService messageService;

    @Autowired
    private RestTemplate restTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @Transactional
    public boolean processGroupMessage(Message message) {
        if (message.getGroupId() == null || message.getContent() == null) {
            return false;
        }

        List<GroupRobot> robots = robotRepository.findByGroupIdAndIsEnabled(message.getGroupId(), true);
        if (robots.isEmpty()) {
            return false;
        }

        String content = message.getContent().trim();
        boolean triggered = false;

        for (GroupRobot robot : robots) {
            List<RobotCommand> commands = commandRepository.findByRobotIdAndIsEnabled(robot.getId(), true);
            for (RobotCommand command : commands) {
                if (content.startsWith(command.getCommand())) {
                    try {
                        handleCommand(robot, command, message);
                        triggered = true;
                    } catch (Exception e) {
                        logger.error("处理机器人指令失败: robotId={}, command={}, error={}",
                                robot.getId(), command.getCommand(), e.getMessage(), e);
                    }
                }
            }
        }

        return triggered;
    }

    private void handleCommand(GroupRobot robot, RobotCommand command, Message message) {
        String responseContent = null;
        Integer msgType = 1;

        switch (command.getResponseType()) {
            case 1:
                responseContent = command.getResponseContent();
                break;
            case 2:
                responseContent = command.getResponseContent();
                msgType = 2;
                break;
            case 3:
                responseContent = command.getResponseContent();
                break;
            case 4:
                responseContent = callExternalApi(robot, command, message);
                break;
            default:
                logger.warn("未知的响应类型: {}", command.getResponseType());
                return;
        }

        if (responseContent != null && !responseContent.isEmpty()) {
            sendRobotMessage(robot, message.getGroupId(), responseContent, msgType);
        }
    }

    private String callExternalApi(GroupRobot robot, RobotCommand command, Message message) {
        try {
            String url = command.getApiUrl();
            String method = command.getApiMethod();
            String paramsTemplate = command.getApiParams();

            Map<String, Object> params = new HashMap<>();
            if (paramsTemplate != null && !paramsTemplate.isEmpty()) {
                params = objectMapper.readValue(paramsTemplate, Map.class);
                params.put("groupId", message.getGroupId());
                params.put("userId", message.getFromUserId());
                params.put("content", message.getContent());
                params.put("command", command.getCommand());
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("X-Robot-Key", robot.getApiKey());

            HttpEntity<String> entity;
            if ("POST".equalsIgnoreCase(method)) {
                String requestBody = objectMapper.writeValueAsString(params);
                entity = new HttpEntity<>(requestBody, headers);
            } else {
                entity = new HttpEntity<>(headers);
            }

            ResponseEntity<String> response;
            if ("POST".equalsIgnoreCase(method)) {
                response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);
            } else {
                response = restTemplate.exchange(url + "?" + buildQueryString(params), HttpMethod.GET, entity, String.class);
            }

            if (response.getStatusCode() == HttpStatus.OK) {
                return response.getBody();
            } else {
                logger.error("API 调用失败: status={}", response.getStatusCode());
                return null;
            }
        } catch (Exception e) {
            logger.error("调用外部 API 失败: {}", e.getMessage(), e);
            return null;
        }
    }

    private String buildQueryString(Map<String, Object> params) {
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Object> entry : params.entrySet()) {
            if (sb.length() > 0) {
                sb.append("&");
            }
            sb.append(entry.getKey()).append("=").append(entry.getValue());
        }
        return sb.toString();
    }

    private void sendRobotMessage(GroupRobot robot, Long groupId, String content, Integer msgType) {
        try {
            messageService.sendGroupMessage(-robot.getId(), groupId, content, msgType, null);
        } catch (Exception e) {
            logger.error("发送机器人消息失败: {}", e.getMessage(), e);
        }
    }

    @Transactional
    public GroupRobot createRobot(Long groupId, String name, String description) {
        GroupRobot robot = new GroupRobot();
        robot.setGroupId(groupId);
        robot.setName(name);
        robot.setDescription(description);
        robot.setIsEnabled(true);
        robot.setApiKey(UUID.randomUUID().toString().replace("-", ""));
        robot.setCreatedAt(new Date());
        robot.setUpdatedAt(new Date());
        return robotRepository.save(robot);
    }

    @Transactional
    public RobotCommand addCommand(Long robotId, String command, String description,
                                   Integer responseType, String responseContent) {
        RobotCommand robotCommand = new RobotCommand();
        robotCommand.setRobotId(robotId);
        robotCommand.setCommand(command);
        robotCommand.setDescription(description);
        robotCommand.setResponseType(responseType);
        robotCommand.setResponseContent(responseContent);
        robotCommand.setIsEnabled(true);
        robotCommand.setCreatedAt(new Date());
        robotCommand.setUpdatedAt(new Date());
        return commandRepository.save(robotCommand);
    }

    public List<GroupRobot> getGroupRobots(Long groupId) {
        return robotRepository.findByGroupId(groupId);
    }

    public List<RobotCommand> getRobotCommands(Long robotId) {
        return commandRepository.findByRobotId(robotId);
    }

    @Transactional
    public GroupRobot setRobotEnabled(Long robotId, Boolean enabled) {
        GroupRobot robot = robotRepository.findById(robotId)
                .orElseThrow(() -> new RuntimeException("机器人不存在"));
        robot.setIsEnabled(enabled);
        robot.setUpdatedAt(new Date());
        return robotRepository.save(robot);
    }

    @Transactional
    public void deleteRobot(Long robotId) {
        List<RobotCommand> commands = commandRepository.findByRobotId(robotId);
        commandRepository.deleteAll(commands);
        robotRepository.deleteById(robotId);
    }
}
