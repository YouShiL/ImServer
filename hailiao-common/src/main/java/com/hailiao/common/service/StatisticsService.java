package com.hailiao.common.service;

import com.hailiao.common.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class StatisticsService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private GroupChatRepository groupChatRepository;

    @Autowired
    private ConversationRepository conversationRepository;

    @Autowired
    private VideoCallRepository videoCallRepository;

    @Autowired
    private GroupRobotRepository groupRobotRepository;

    public Map<String, Object> getSystemStatistics() {
        long totalUsers = userRepository.count();
        long totalMessages = messageRepository.count();
        long totalGroups = groupChatRepository.count();
        long totalConversations = conversationRepository.count();
        long totalVideoCalls = videoCallRepository.count();
        long totalRobots = groupRobotRepository.count();

        Map<String, Object> stats = new LinkedHashMap<String, Object>();
        stats.put("totalUsers", totalUsers);
        stats.put("totalMessages", totalMessages);
        stats.put("totalGroups", totalGroups);
        stats.put("totalConversations", totalConversations);
        stats.put("totalVideoCalls", totalVideoCalls);
        stats.put("totalRobots", totalRobots);
        stats.put("summary", mapOf(
                "userLabel", "用户总数",
                "messageLabel", "消息总量",
                "groupLabel", "群组总数",
                "conversationLabel", "会话总数",
                "videoCallLabel", "音视频通话总数",
                "robotLabel", "机器人总数"
        ));

        return stats;
    }

    public Map<String, Object> getUserStatistics(Long userId) {
        Map<String, Object> stats = new LinkedHashMap<String, Object>();

        stats.put("totalSentMessages", messageRepository.countByFromUserId(userId));

        Long totalCalls = videoCallRepository.countSuccessfulCallsByCaller(userId);
        Long totalDuration = videoCallRepository.sumDurationByCaller(userId);

        stats.put("totalCalls", totalCalls != null ? totalCalls : 0);
        stats.put("totalCallDuration", totalDuration != null ? totalDuration : 0);
        stats.put("summary", mapOf(
                "sentMessageLabel", "发送消息数",
                "callCountLabel", "通话次数",
                "callDurationLabel", "通话时长(秒)"
        ));

        return stats;
    }

    public Map<String, Object> getMessageStatistics() {
        Map<String, Object> stats = new LinkedHashMap<String, Object>();

        long totalMessages = messageRepository.count();
        stats.put("totalMessages", totalMessages);

        long textMessages = messageRepository.countByMsgType(1);
        long imageMessages = messageRepository.countByMsgType(2);
        long audioMessages = messageRepository.countByMsgType(3);
        long videoMessages = messageRepository.countByMsgType(4);

        stats.put("textMessages", textMessages);
        stats.put("imageMessages", imageMessages);
        stats.put("audioMessages", audioMessages);
        stats.put("videoMessages", videoMessages);
        stats.put("distribution", mapOf(
                "text", mapOf("label", "文本", "count", textMessages),
                "image", mapOf("label", "图片", "count", imageMessages),
                "audio", mapOf("label", "音频", "count", audioMessages),
                "video", mapOf("label", "视频", "count", videoMessages)
        ));
        stats.put("summary", mapOf(
                "totalLabel", "消息总量",
                "distributionLabel", "消息类型分布",
                "activeTypeCount", countPositive(textMessages, imageMessages, audioMessages, videoMessages)
        ));

        return stats;
    }

    public Map<String, Object> getGroupStatistics(Long groupId) {
        Map<String, Object> stats = new LinkedHashMap<String, Object>();
        long totalMessages = messageRepository.countByGroupId(groupId);
        stats.put("totalMessages", totalMessages);
        stats.put("summary", mapOf(
                "totalLabel", "群消息总量",
                "groupId", groupId
        ));

        return stats;
    }

    private long countPositive(long... values) {
        long count = 0L;
        for (long value : values) {
            if (value > 0) {
                count++;
            }
        }
        return count;
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
