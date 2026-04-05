package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.VideoCall;
import com.hailiao.common.service.VideoCallService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/calls")
@Tag(name = "音视频通话", description = "音视频通话相关接口")
public class VideoCallController {

    @Autowired
    private VideoCallService videoCallService;

    @PostMapping("/initiate")
    @Operation(summary = "发起通话", description = "发起音频或视频通话")
    public ResponseEntity<ResponseDTO<VideoCall>> initiateCall(
            @Parameter(description = "呼叫方 ID") @RequestParam Long callerId,
            @Parameter(description = "被呼叫方 ID") @RequestParam Long calleeId,
            @Parameter(description = "群组 ID（可选）") @RequestParam(required = false) Long groupId,
            @Parameter(description = "通话类型：1-音频，2-视频") @RequestParam Integer callType) {
        try {
            VideoCall call = videoCallService.initiateCall(callerId, calleeId, groupId, callType);
            return ResponseEntity.ok(ResponseDTO.success(call));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/accept")
    @Operation(summary = "接听通话", description = "接听来电")
    public ResponseEntity<ResponseDTO<VideoCall>> acceptCall(
            @Parameter(description = "通话 ID") @PathVariable Long callId,
            @Parameter(description = "用户 ID") @RequestParam Long userId) {
        try {
            VideoCall call = videoCallService.acceptCall(callId, userId);
            return ResponseEntity.ok(ResponseDTO.success(call));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/reject")
    @Operation(summary = "拒绝通话", description = "拒绝来电")
    public ResponseEntity<ResponseDTO<VideoCall>> rejectCall(
            @Parameter(description = "通话 ID") @PathVariable Long callId,
            @Parameter(description = "用户 ID") @RequestParam Long userId) {
        try {
            VideoCall call = videoCallService.rejectCall(callId, userId);
            return ResponseEntity.ok(ResponseDTO.success(call));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/end")
    @Operation(summary = "结束通话", description = "结束当前通话")
    public ResponseEntity<ResponseDTO<VideoCall>> endCall(
            @Parameter(description = "通话 ID") @PathVariable Long callId,
            @Parameter(description = "用户 ID") @RequestParam Long userId,
            @Parameter(description = "结束原因") @RequestParam(required = false, defaultValue = "正常结束") String reason) {
        try {
            VideoCall call = videoCallService.endCall(callId, userId, reason);
            return ResponseEntity.ok(ResponseDTO.success(call));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/cancel")
    @Operation(summary = "取消通话", description = "取消已发起的通话请求")
    public ResponseEntity<ResponseDTO<Void>> cancelCall(
            @Parameter(description = "通话 ID") @PathVariable Long callId,
            @Parameter(description = "用户 ID") @RequestParam Long userId) {
        try {
            videoCallService.cancelCall(callId, userId);
            return ResponseEntity.ok(ResponseDTO.success(null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/history/{userId}")
    @Operation(summary = "获取通话历史", description = "获取指定用户的通话历史")
    public ResponseEntity<ResponseDTO<List<VideoCall>>> getCallHistory(
            @Parameter(description = "用户 ID") @PathVariable Long userId) {
        try {
            List<VideoCall> history = videoCallService.getCallHistory(userId);
            return ResponseEntity.ok(ResponseDTO.success(history));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/{callId}")
    @Operation(summary = "获取通话详情", description = "根据通话 ID 获取详情")
    public ResponseEntity<ResponseDTO<VideoCall>> getCallById(
            @Parameter(description = "通话 ID") @PathVariable Long callId) {
        try {
            Optional<VideoCall> call = videoCallService.getCallById(callId);
            if (call.isPresent()) {
                return ResponseEntity.ok(ResponseDTO.success(call.get()));
            }
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/statistics/{userId}")
    @Operation(summary = "获取通话统计", description = "获取指定用户的通话统计数据")
    public ResponseEntity<ResponseDTO<Map<String, Object>>> getCallStatistics(
            @Parameter(description = "用户 ID") @PathVariable Long userId) {
        try {
            Map<String, Object> stats = videoCallService.getCallStatistics(userId);
            return ResponseEntity.ok(ResponseDTO.success(stats));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/signal")
    @Operation(summary = "发送 WebRTC 信令", description = "发送 WebRTC 协商信令数据")
    public ResponseEntity<ResponseDTO<Void>> sendSignal(
            @Parameter(description = "通话 ID") @PathVariable Long callId,
            @Parameter(description = "用户 ID") @RequestParam Long userId,
            @Parameter(description = "信令类型") @RequestParam String signalType,
            @RequestBody Map<String, Object> signalData) {
        try {
            videoCallService.handleWebRTCSignal(callId, userId, signalType, signalData);
            return ResponseEntity.ok(ResponseDTO.success(null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }
}
