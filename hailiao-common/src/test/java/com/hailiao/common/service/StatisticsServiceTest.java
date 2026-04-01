package com.hailiao.common.service;

import com.hailiao.common.repository.ConversationRepository;
import com.hailiao.common.repository.GroupChatRepository;
import com.hailiao.common.repository.GroupRobotRepository;
import com.hailiao.common.repository.MessageRepository;
import com.hailiao.common.repository.UserRepository;
import com.hailiao.common.repository.VideoCallRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StatisticsServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private MessageRepository messageRepository;

    @Mock
    private GroupChatRepository groupChatRepository;

    @Mock
    private ConversationRepository conversationRepository;

    @Mock
    private VideoCallRepository videoCallRepository;

    @Mock
    private GroupRobotRepository groupRobotRepository;

    @InjectMocks
    private StatisticsService statisticsService;

    @Test
    void getSystemStatisticsShouldReturnSummaryLabels() {
        when(userRepository.count()).thenReturn(10L);
        when(messageRepository.count()).thenReturn(200L);
        when(groupChatRepository.count()).thenReturn(5L);
        when(conversationRepository.count()).thenReturn(20L);
        when(videoCallRepository.count()).thenReturn(8L);
        when(groupRobotRepository.count()).thenReturn(3L);

        Map<String, Object> stats = statisticsService.getSystemStatistics();

        assertEquals(10L, stats.get("totalUsers"));
        assertEquals(200L, stats.get("totalMessages"));
        assertEquals(5L, stats.get("totalGroups"));
        assertEquals(20L, stats.get("totalConversations"));
        assertEquals(8L, stats.get("totalVideoCalls"));
        assertEquals(3L, stats.get("totalRobots"));
        assertNotNull(stats.get("summary"));
    }

    @Test
    void getUserStatisticsShouldFallbackNullCallStatsToZero() {
        when(messageRepository.countByFromUserId(1L)).thenReturn(15L);
        when(videoCallRepository.countSuccessfulCallsByCaller(1L)).thenReturn(null);
        when(videoCallRepository.sumDurationByCaller(1L)).thenReturn(null);

        Map<String, Object> stats = statisticsService.getUserStatistics(1L);

        assertEquals(15L, stats.get("totalSentMessages"));
        assertEquals(0L, stats.get("totalCalls"));
        assertEquals(0L, stats.get("totalCallDuration"));
        assertNotNull(stats.get("summary"));
    }

    @Test
    void getMessageStatisticsShouldBuildDistributionAndActiveTypeCount() {
        when(messageRepository.count()).thenReturn(50L);
        when(messageRepository.countByMsgType(1)).thenReturn(30L);
        when(messageRepository.countByMsgType(2)).thenReturn(10L);
        when(messageRepository.countByMsgType(3)).thenReturn(0L);
        when(messageRepository.countByMsgType(4)).thenReturn(10L);

        Map<String, Object> stats = statisticsService.getMessageStatistics();

        assertEquals(50L, stats.get("totalMessages"));
        assertEquals(30L, stats.get("textMessages"));
        assertEquals(10L, stats.get("imageMessages"));
        assertEquals(0L, stats.get("audioMessages"));
        assertEquals(10L, stats.get("videoMessages"));

        Map<?, ?> summary = (Map<?, ?>) stats.get("summary");
        assertEquals(3L, summary.get("activeTypeCount"));

        Map<?, ?> distribution = (Map<?, ?>) stats.get("distribution");
        Map<?, ?> text = (Map<?, ?>) distribution.get("text");
        assertEquals("\u6587\u672c", text.get("label"));
        assertEquals(30L, text.get("count"));
    }

    @Test
    void getGroupStatisticsShouldReturnGroupScopedSummary() {
        when(messageRepository.countByGroupId(99L)).thenReturn(66L);

        Map<String, Object> stats = statisticsService.getGroupStatistics(99L);

        assertEquals(66L, stats.get("totalMessages"));
        Map<?, ?> summary = (Map<?, ?>) stats.get("summary");
        assertEquals("\u7fa4\u6d88\u606f\u603b\u91cf", summary.get("totalLabel"));
        assertEquals(99L, summary.get("groupId"));
    }
}
