package com.hailiao.common.service;

import com.hailiao.common.entity.User;
import com.hailiao.common.entity.VideoCall;
import com.hailiao.common.repository.UserRepository;
import com.hailiao.common.repository.VideoCallRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VideoCallServiceTest {

    @Mock
    private VideoCallRepository videoCallRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private WebSocketNotificationService webSocketNotificationService;

    @InjectMocks
    private VideoCallService videoCallService;

    @Test
    void initiateCallShouldCreatePendingCallAndNotifyCallee() {
        User caller = new User();
        caller.setId(1L);
        caller.setNickname("caller");
        caller.setAvatar("avatar.png");

        User callee = new User();
        callee.setId(2L);

        when(userRepository.findById(1L)).thenReturn(Optional.of(caller));
        when(userRepository.findById(2L)).thenReturn(Optional.of(callee));
        when(videoCallRepository.findByStatusAndUserId(0, 2L)).thenReturn(new ArrayList<VideoCall>());
        when(videoCallRepository.save(any(VideoCall.class))).thenAnswer(new org.mockito.stubbing.Answer<VideoCall>() {
            @Override
            public VideoCall answer(org.mockito.invocation.InvocationOnMock invocation) {
                VideoCall call = (VideoCall) invocation.getArgument(0);
                call.setId(100L);
                return call;
            }
        });

        VideoCall call = videoCallService.initiateCall(1L, 2L, 10L, 1);

        assertEquals(Long.valueOf(100L), call.getId());
        assertEquals(Integer.valueOf(0), call.getStatus());
        assertEquals(Long.valueOf(10L), call.getGroupId());

        ArgumentCaptor<Map> payloadCaptor = ArgumentCaptor.forClass(Map.class);
        verify(webSocketNotificationService).sendToUser(eq(2L), eq("call_request"), payloadCaptor.capture());
        assertEquals(100L, payloadCaptor.getValue().get("callId"));
        assertEquals("caller", payloadCaptor.getValue().get("callerName"));
        assertEquals("avatar.png", payloadCaptor.getValue().get("callerAvatar"));
    }

    @Test
    void acceptCallShouldSetStartTimeAndNotifyCaller() {
        VideoCall call = new VideoCall();
        call.setId(100L);
        call.setCallerId(1L);
        call.setCalleeId(2L);
        call.setStatus(0);

        when(videoCallRepository.findById(100L)).thenReturn(Optional.of(call));
        when(videoCallRepository.save(any(VideoCall.class))).thenAnswer(new org.mockito.stubbing.Answer<VideoCall>() {
            @Override
            public VideoCall answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (VideoCall) invocation.getArgument(0);
            }
        });

        VideoCall saved = videoCallService.acceptCall(100L, 2L);

        assertEquals(Integer.valueOf(1), saved.getStatus());
        assertNotNull(saved.getStartTime());

        ArgumentCaptor<Map> payloadCaptor = ArgumentCaptor.forClass(Map.class);
        verify(webSocketNotificationService).sendToUser(eq(1L), eq("call_accepted"), payloadCaptor.capture());
        assertEquals(2L, payloadCaptor.getValue().get("calleeId"));
        assertNotNull(payloadCaptor.getValue().get("startTime"));
    }

    @Test
    void rejectCallShouldSetRejectedStatusAndNotifyCaller() {
        VideoCall call = new VideoCall();
        call.setId(100L);
        call.setCallerId(1L);
        call.setCalleeId(2L);
        call.setStatus(0);

        when(videoCallRepository.findById(100L)).thenReturn(Optional.of(call));
        when(videoCallRepository.save(any(VideoCall.class))).thenAnswer(new org.mockito.stubbing.Answer<VideoCall>() {
            @Override
            public VideoCall answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (VideoCall) invocation.getArgument(0);
            }
        });

        VideoCall saved = videoCallService.rejectCall(100L, 2L);

        assertEquals(Integer.valueOf(3), saved.getStatus());
        assertEquals("\u88ab\u62d2\u7edd", saved.getEndReason());

        ArgumentCaptor<Map> payloadCaptor = ArgumentCaptor.forClass(Map.class);
        verify(webSocketNotificationService).sendToUser(eq(1L), eq("call_rejected"), payloadCaptor.capture());
        assertEquals("rejected", payloadCaptor.getValue().get("reason"));
    }

    @Test
    void endCallShouldCompleteActiveCallAndNotifyOtherUser() {
        VideoCall call = new VideoCall();
        call.setId(100L);
        call.setCallerId(1L);
        call.setCalleeId(2L);
        call.setStatus(1);
        call.setStartTime(LocalDateTime.now().minusSeconds(30));

        when(videoCallRepository.findById(100L)).thenReturn(Optional.of(call));
        when(videoCallRepository.save(any(VideoCall.class))).thenAnswer(new org.mockito.stubbing.Answer<VideoCall>() {
            @Override
            public VideoCall answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (VideoCall) invocation.getArgument(0);
            }
        });

        VideoCall saved = videoCallService.endCall(100L, 1L, "hangup");

        assertEquals(Integer.valueOf(2), saved.getStatus());
        assertEquals("hangup", saved.getEndReason());
        assertNotNull(saved.getEndTime());
        assertTrue(saved.getDuration() >= 30);

        ArgumentCaptor<Map> payloadCaptor = ArgumentCaptor.forClass(Map.class);
        verify(webSocketNotificationService).sendToUser(eq(2L), eq("call_ended"), payloadCaptor.capture());
        assertEquals(1L, payloadCaptor.getValue().get("endedBy"));
        assertEquals("hangup", payloadCaptor.getValue().get("reason"));
    }

    @Test
    void cancelCallShouldRequireCallerAndPendingStatus() {
        VideoCall call = new VideoCall();
        call.setId(100L);
        call.setCallerId(1L);
        call.setCalleeId(2L);
        call.setStatus(0);

        when(videoCallRepository.findById(100L)).thenReturn(Optional.of(call));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        videoCallService.cancelCall(100L, 2L);
                    }
                });

        assertEquals("\u65e0\u6743\u53d6\u6d88\u6b64\u901a\u8bdd", error.getMessage());
    }

    @Test
    void getCallStatisticsShouldFallbackToZero() {
        when(videoCallRepository.countSuccessfulCallsByCaller(1L)).thenReturn(null);
        when(videoCallRepository.sumDurationByCaller(1L)).thenReturn(null);

        Map<String, Object> stats = videoCallService.getCallStatistics(1L);

        assertEquals(0L, stats.get("totalCalls"));
        assertEquals(0L, stats.get("totalDuration"));
    }

    @Test
    void handleWebRtcSignalShouldRelayToOtherUser() {
        VideoCall call = new VideoCall();
        call.setId(100L);
        call.setCallerId(1L);
        call.setCalleeId(2L);

        Map<String, Object> signalData = new HashMap<String, Object>();
        signalData.put("sdp", "offer");

        when(videoCallRepository.findById(100L)).thenReturn(Optional.of(call));

        videoCallService.handleWebRTCSignal(100L, 1L, "offer", signalData);

        ArgumentCaptor<Map> payloadCaptor = ArgumentCaptor.forClass(Map.class);
        verify(webSocketNotificationService).sendToUser(eq(2L), eq("webrtc_signal"), payloadCaptor.capture());
        assertEquals(100L, payloadCaptor.getValue().get("callId"));
        assertEquals(1L, payloadCaptor.getValue().get("fromUserId"));
        assertEquals("offer", payloadCaptor.getValue().get("signalType"));
        assertEquals(signalData, payloadCaptor.getValue().get("data"));
    }

    @Test
    void initiateCallShouldRejectBusyCallee() {
        User caller = new User();
        caller.setId(1L);
        User callee = new User();
        callee.setId(2L);

        List<VideoCall> activeCalls = new ArrayList<VideoCall>();
        activeCalls.add(new VideoCall());

        when(userRepository.findById(1L)).thenReturn(Optional.of(caller));
        when(userRepository.findById(2L)).thenReturn(Optional.of(callee));
        when(videoCallRepository.findByStatusAndUserId(0, 2L)).thenReturn(activeCalls);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        videoCallService.initiateCall(1L, 2L, null, 2);
                    }
                });

        assertEquals("\u88ab\u547c\u53eb\u65b9\u6b63\u5728\u901a\u8bdd\u4e2d", error.getMessage());
    }
}
