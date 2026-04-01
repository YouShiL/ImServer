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
                "userLabel", "\u7528\u6237\u603b\u6570",
                "messageLabel", "\u6d88\u606f\u603b\u91cf",
                "groupLabel", "\u7fa4\u7ec4\u603b\u6570",
                "conversationLabel", "\u4f1a\u8bdd\u603b\u6570",
                "videoCallLabel", "\u97f3\u89c6\u9891\u901a\u8bdd\u603b\u6570",
                "robotLabel", "\u673a\u5668\u4eba\u603b\u6570"
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
                "sentMessageLabel", "\u53d1\u9001\u6d88\u606f\u6570",
                "callCountLabel", "\u901a\u8bdd\u6b21\u6570",
                "callDurationLabel", "\u901a\u8bdd\u65f6\u957f(\u79d2)"
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
                "text", mapOf("label", "\u6587\u672c", "count", textMessages),
                "image", mapOf("label", "\u56fe\u7247", "count", imageMessages),
                "audio", mapOf("label", "\u97f3\u9891", "count", audioMessages),
                "video", mapOf("label", "\u89c6\u9891", "count", videoMessages)
        ));
        stats.put("summary", mapOf(
                "totalLabel", "\u6d88\u606f\u603b\u91cf",
                "distributionLabel", "\u6d88\u606f\u7c7b\u578b\u5206\u5e03",
                "activeTypeCount", countPositive(textMessages, imageMessages, audioMessages, videoMessages)
        ));

        return stats;
    }

    public Map<String, Object> getGroupStatistics(Long groupId) {
        Map<String, Object> stats = new LinkedHashMap<String, Object>();
        long totalMessages = messageRepository.countByGroupId(groupId);
        stats.put("totalMessages", totalMessages);
        stats.put("summary", mapOf(
                "totalLabel", "\u7fa4\u6d88\u606f\u603b\u91cf",
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
