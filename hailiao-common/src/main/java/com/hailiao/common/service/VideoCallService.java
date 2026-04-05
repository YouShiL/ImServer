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
            throw new RuntimeException("呼叫方不存在");
        }

        if (!callee.isPresent()) {
            throw new RuntimeException("被呼叫方不存在");
        }

        List<VideoCall> activeCalls = videoCallRepository.findByStatusAndUserId(0, calleeId);
        if (!activeCalls.isEmpty()) {
            throw new RuntimeException("被呼叫方正在通话中");
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

        logger.info("发起通话: callId={}, callerId={}, calleeId={}, type={}",
                savedCall.getId(), callerId, calleeId, callType);

        return savedCall;
    }

    @Transactional
    public VideoCall acceptCall(Long callId, Long userId) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("通话不存在");
        }

        VideoCall call = callOpt.get();

        if (!call.getCalleeId().equals(userId)) {
            throw new RuntimeException("无权接听此通话");
        }

        if (call.getStatus() != 0) {
            throw new RuntimeException("通话状态不正确");
        }

        call.setStatus(1);
        call.setStartTime(LocalDateTime.now());

        VideoCall savedCall = videoCallRepository.save(call);

        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", savedCall.getId());
        callData.put("calleeId", userId);
        callData.put("startTime", savedCall.getStartTime());

        webSocketNotificationService.sendToUser(call.getCallerId(), "call_accepted", callData);

        logger.info("接听通话: callId={}, userId={}", callId, userId);

        return savedCall;
    }

    @Transactional
    public VideoCall rejectCall(Long callId, Long userId) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("通话不存在");
        }

        VideoCall call = callOpt.get();

        if (!call.getCalleeId().equals(userId)) {
            throw new RuntimeException("无权拒绝此通话");
        }

        if (call.getStatus() != 0) {
            throw new RuntimeException("通话状态不正确");
        }

        call.setStatus(3);
        call.setEndReason("被拒绝");

        VideoCall savedCall = videoCallRepository.save(call);

        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", savedCall.getId());
        callData.put("calleeId", userId);
        callData.put("reason", "rejected");

        webSocketNotificationService.sendToUser(call.getCallerId(), "call_rejected", callData);

        logger.info("拒绝通话: callId={}, userId={}", callId, userId);

        return savedCall;
    }

    @Transactional
    public VideoCall endCall(Long callId, Long userId, String reason) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("通话不存在");
        }

        VideoCall call = callOpt.get();

        if (!call.getCallerId().equals(userId) && !call.getCalleeId().equals(userId)) {
            throw new RuntimeException("无权结束此通话");
        }

        if (call.getStatus() == 2 || call.getStatus() == 3) {
            throw new RuntimeException("通话已结束");
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

        logger.info("结束通话: callId={}, userId={}, reason={}, duration={}",
                callId, userId, reason, savedCall.getDuration());

        return savedCall;
    }

    @Transactional
    public void cancelCall(Long callId, Long userId) {
        Optional<VideoCall> callOpt = videoCallRepository.findById(callId);

        if (!callOpt.isPresent()) {
            throw new RuntimeException("通话不存在");
        }

        VideoCall call = callOpt.get();

        if (!call.getCallerId().equals(userId)) {
            throw new RuntimeException("无权取消此通话");
        }

        if (call.getStatus() != 0) {
            throw new RuntimeException("通话状态不正确");
        }

        call.setStatus(3);
        call.setEndReason("呼叫方取消");

        videoCallRepository.save(call);

        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", callId);
        callData.put("callerId", userId);
        callData.put("reason", "cancelled");

        webSocketNotificationService.sendToUser(call.getCalleeId(), "call_cancelled", callData);

        logger.info("取消通话: callId={}, userId={}", callId, userId);
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
            throw new RuntimeException("通话不存在");
        }

        VideoCall call = callOpt.get();

        if (!call.getCallerId().equals(userId) && !call.getCalleeId().equals(userId)) {
            throw new RuntimeException("无权发送信令");
        }

        Long targetUserId = call.getCallerId().equals(userId) ? call.getCalleeId() : call.getCallerId();

        Map<String, Object> message = new HashMap<>();
        message.put("callId", callId);
        message.put("fromUserId", userId);
        message.put("signalType", signalType);
        message.put("data", signalData);

        webSocketNotificationService.sendToUser(targetUserId, "webrtc_signal", message);

        logger.debug("WebRTC 信令: callId={}, from={}, to={}, type={}",
                callId, userId, targetUserId, signalType);
    }
}
