package com.hailiao.common.service;

import com.hailiao.common.entity.User;
import com.hailiao.common.entity.VideoCall;
import com.hailiao.common.repository.UserRepository;
import com.hailiao.common.repository.VideoCallRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class VideoCallService {

    private static final Logger logger = LoggerFactory.getLogger(VideoCallService.class);

    @Autowired
    private VideoCallRepository videoCallRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private WebSocketNotificationService webSocketNotificationService;

    @Transactional
    public VideoCall initiateCall(Long callerId, Long calleeId, Long groupId, Integer callType) {
        Optional<User> caller = userRepository.findById(callerId);
        Optional<User> callee = userRepository.findById(calleeId);

        if (!caller.isPresent()) {
            throw new RuntimeException("\u547c\u53eb\u65b9\u4e0d\u5b58\u5728");
        }

        if (!callee.isPresent()) {
            throw new RuntimeException("\u88ab\u547c\u53eb\u65b9\u4e0d\u5b58\u5728");
        }

        List<VideoCall> activeCalls = videoCallRepository.findByStatusAndUserId(0, calleeId);
        if (!activeCalls.isEmpty()) {
            throw new RuntimeException("\u88ab\u547c\u53eb\u65b9\u6b63\u5728\u901a\u8bdd\u4e2d");
        }

        VideoCall videoCall = new VideoCall();
        videoCall.setCallerId(callerId);
        videoCall.setCalleeId(calleeId);
        videoCall.setGroupId(groupId);
        videoCall.setCallType(callType);
        videoCall.setStatus(0);

        VideoCall savedCall = videoCallRepository.save(videoCall);

        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", savedCall.getId());
        callData.put("callerId", callerId);
        callData.put("callerName", caller.get().getNickname());
        callData.put("callerAvatar", caller.get().getAvatar());
        callData.put("callType", callType);
        callData.put("groupId", groupId);

        webSocketNotificationService.sendToUser(calleeId, "call_request", callData);

        logger.info("\u53d1\u8d77\u901a\u8bdd: callId={}, callerId={}, calleeId={}, type={}",
                savedCall.getId(), callerId, calleeId, callType);

        return savedCall;
    }

    @Transactional
    public VideoCall acceptCall(Long callId, Long userId) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("\u901a\u8bdd\u4e0d\u5b58\u5728");
        }

        VideoCall call = callOpt.get();

        if (!call.getCalleeId().equals(userId)) {
            throw new RuntimeException("\u65e0\u6743\u63a5\u542c\u6b64\u901a\u8bdd");
        }

        if (call.getStatus() != 0) {
            throw new RuntimeException("\u901a\u8bdd\u72b6\u6001\u4e0d\u6b63\u786e");
        }

        call.setStatus(1);
        call.setStartTime(LocalDateTime.now());

        VideoCall savedCall = videoCallRepository.save(call);

        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", savedCall.getId());
        callData.put("calleeId", userId);
        callData.put("startTime", savedCall.getStartTime());

        webSocketNotificationService.sendToUser(call.getCallerId(), "call_accepted", callData);

        logger.info("\u63a5\u542c\u901a\u8bdd: callId={}, userId={}", callId, userId);

        return savedCall;
    }

    @Transactional
    public VideoCall rejectCall(Long callId, Long userId) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("\u901a\u8bdd\u4e0d\u5b58\u5728");
        }

        VideoCall call = callOpt.get();

        if (!call.getCalleeId().equals(userId)) {
            throw new RuntimeException("\u65e0\u6743\u62d2\u7edd\u6b64\u901a\u8bdd");
        }

        if (call.getStatus() != 0) {
            throw new RuntimeException("\u901a\u8bdd\u72b6\u6001\u4e0d\u6b63\u786e");
        }

        call.setStatus(3);
        call.setEndReason("\u88ab\u62d2\u7edd");

        VideoCall savedCall = videoCallRepository.save(call);

        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", savedCall.getId());
        callData.put("calleeId", userId);
        callData.put("reason", "rejected");

        webSocketNotificationService.sendToUser(call.getCallerId(), "call_rejected", callData);

        logger.info("\u62d2\u7edd\u901a\u8bdd: callId={}, userId={}", callId, userId);

        return savedCall;
    }

    @Transactional
    public VideoCall endCall(Long callId, Long userId, String reason) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("\u901a\u8bdd\u4e0d\u5b58\u5728");
        }

        VideoCall call = callOpt.get();

        if (!call.getCallerId().equals(userId) && !call.getCalleeId().equals(userId)) {
            throw new RuntimeException("\u65e0\u6743\u7ed3\u675f\u6b64\u901a\u8bdd");
        }

        if (call.getStatus() == 2 || call.getStatus() == 3) {
            throw new RuntimeException("\u901a\u8bdd\u5df2\u7ed3\u675f");
        }

        LocalDateTime endTime = LocalDateTime.now();
        call.setEndTime(endTime);
        call.setEndReason(reason);

        if (call.getStatus() == 1 && call.getStartTime() != null) {
            call.setStatus(2);
            int duration = (int) java.time.Duration.between(call.getStartTime(), endTime).getSeconds();
            call.setDuration(duration);
        } else {
            call.setStatus(3);
        }

        VideoCall savedCall = videoCallRepository.save(call);

        Long otherUserId = call.getCallerId().equals(userId) ? call.getCalleeId() : call.getCallerId();

        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", savedCall.getId());
        callData.put("endedBy", userId);
        callData.put("reason", reason);
        callData.put("duration", savedCall.getDuration());

        webSocketNotificationService.sendToUser(otherUserId, "call_ended", callData);

        logger.info("\u7ed3\u675f\u901a\u8bdd: callId={}, userId={}, reason={}, duration={}",
                callId, userId, reason, savedCall.getDuration());

        return savedCall;
    }

    @Transactional
    public void cancelCall(Long callId, Long userId) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("\u901a\u8bdd\u4e0d\u5b58\u5728");
        }

        VideoCall call = callOpt.get();

        if (!call.getCallerId().equals(userId)) {
            throw new RuntimeException("\u65e0\u6743\u53d6\u6d88\u6b64\u901a\u8bdd");
        }

        if (call.getStatus() != 0) {
            throw new RuntimeException("\u901a\u8bdd\u72b6\u6001\u4e0d\u6b63\u786e");
        }

        call.setStatus(3);
        call.setEndReason("\u547c\u53eb\u65b9\u53d6\u6d88");

        videoCallRepository.save(call);

        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", callId);
        callData.put("callerId", userId);
        callData.put("reason", "cancelled");

        webSocketNotificationService.sendToUser(call.getCalleeId(), "call_cancelled", callData);

        logger.info("\u53d6\u6d88\u901a\u8bdd: callId={}, userId={}", callId, userId);
    }

    @Transactional(readOnly = true)
    public List<VideoCall> getCallHistory(Long userId) {
        return videoCallRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public Optional<VideoCall> getCallById(Long callId) {
        return videoCallRepository.findById(callId);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getCallStatistics(Long userId) {
        Map<String, Object> stats = new HashMap<>();

        Long totalCalls = videoCallRepository.countSuccessfulCallsByCaller(userId);
        Long totalDuration = videoCallRepository.sumDurationByCaller(userId);

        stats.put("totalCalls", totalCalls != null ? totalCalls : 0);
        stats.put("totalDuration", totalDuration != null ? totalDuration : 0);

        return stats;
    }

    @Transactional
    public void handleWebRTCSignal(Long callId, Long userId, String signalType, Map<String, Object> signalData) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("\u901a\u8bdd\u4e0d\u5b58\u5728");
        }

        VideoCall call = callOpt.get();

        if (!call.getCallerId().equals(userId) && !call.getCalleeId().equals(userId)) {
            throw new RuntimeException("\u65e0\u6743\u53d1\u9001\u4fe1\u4ee4");
        }

        Long targetUserId = call.getCallerId().equals(userId) ? call.getCalleeId() : call.getCallerId();

        Map<String, Object> message = new HashMap<>();
        message.put("callId", callId);
        message.put("fromUserId", userId);
        message.put("signalType", signalType);
        message.put("data", signalData);

        webSocketNotificationService.sendToUser(targetUserId, "webrtc_signal", message);

        logger.debug("WebRTC \u4fe1\u4ee4: callId={}, from={}, to={}, type={}",
                callId, userId, targetUserId, signalType);
    }
}
