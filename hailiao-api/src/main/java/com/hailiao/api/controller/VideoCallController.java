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
@Tag(name = "\u97f3\u89c6\u9891\u901a\u8bdd", description = "\u97f3\u89c6\u9891\u901a\u8bdd\u76f8\u5173\u63a5\u53e3")
public class VideoCallController {

    @Autowired
    private VideoCallService videoCallService;

    @PostMapping("/initiate")
    @Operation(summary = "\u53d1\u8d77\u901a\u8bdd", description = "\u53d1\u8d77\u97f3\u9891\u6216\u89c6\u9891\u901a\u8bdd")
    public ResponseEntity<ResponseDTO<VideoCall>> initiateCall(
            @Parameter(description = "\u547c\u53eb\u65b9 ID") @RequestParam Long callerId,
            @Parameter(description = "\u88ab\u547c\u53eb\u65b9 ID") @RequestParam Long calleeId,
            @Parameter(description = "\u7fa4\u7ec4 ID\uff08\u53ef\u9009\uff09") @RequestParam(required = false) Long groupId,
            @Parameter(description = "\u901a\u8bdd\u7c7b\u578b\uff1a1-\u97f3\u9891\uff0c2-\u89c6\u9891") @RequestParam Integer callType) {
        try {
            VideoCall call = videoCallService.initiateCall(callerId, calleeId, groupId, callType);
            return ResponseEntity.ok(ResponseDTO.success(call));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/accept")
    @Operation(summary = "\u63a5\u542c\u901a\u8bdd", description = "\u63a5\u542c\u6765\u7535")
    public ResponseEntity<ResponseDTO<VideoCall>> acceptCall(
            @Parameter(description = "\u901a\u8bdd ID") @PathVariable Long callId,
            @Parameter(description = "\u7528\u6237 ID") @RequestParam Long userId) {
        try {
            VideoCall call = videoCallService.acceptCall(callId, userId);
            return ResponseEntity.ok(ResponseDTO.success(call));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/reject")
    @Operation(summary = "\u62d2\u7edd\u901a\u8bdd", description = "\u62d2\u7edd\u6765\u7535")
    public ResponseEntity<ResponseDTO<VideoCall>> rejectCall(
            @Parameter(description = "\u901a\u8bdd ID") @PathVariable Long callId,
            @Parameter(description = "\u7528\u6237 ID") @RequestParam Long userId) {
        try {
            VideoCall call = videoCallService.rejectCall(callId, userId);
            return ResponseEntity.ok(ResponseDTO.success(call));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/end")
    @Operation(summary = "\u7ed3\u675f\u901a\u8bdd", description = "\u7ed3\u675f\u5f53\u524d\u901a\u8bdd")
    public ResponseEntity<ResponseDTO<VideoCall>> endCall(
            @Parameter(description = "\u901a\u8bdd ID") @PathVariable Long callId,
            @Parameter(description = "\u7528\u6237 ID") @RequestParam Long userId,
            @Parameter(description = "\u7ed3\u675f\u539f\u56e0") @RequestParam(required = false, defaultValue = "\u6b63\u5e38\u7ed3\u675f") String reason) {
        try {
            VideoCall call = videoCallService.endCall(callId, userId, reason);
            return ResponseEntity.ok(ResponseDTO.success(call));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/cancel")
    @Operation(summary = "\u53d6\u6d88\u901a\u8bdd", description = "\u53d6\u6d88\u5df2\u53d1\u8d77\u7684\u901a\u8bdd\u8bf7\u6c42")
    public ResponseEntity<ResponseDTO<Void>> cancelCall(
            @Parameter(description = "\u901a\u8bdd ID") @PathVariable Long callId,
            @Parameter(description = "\u7528\u6237 ID") @RequestParam Long userId) {
        try {
            videoCallService.cancelCall(callId, userId);
            return ResponseEntity.ok(ResponseDTO.success(null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/history/{userId}")
    @Operation(summary = "\u83b7\u53d6\u901a\u8bdd\u5386\u53f2", description = "\u83b7\u53d6\u6307\u5b9a\u7528\u6237\u7684\u901a\u8bdd\u5386\u53f2")
    public ResponseEntity<ResponseDTO<List<VideoCall>>> getCallHistory(
            @Parameter(description = "\u7528\u6237 ID") @PathVariable Long userId) {
        try {
            List<VideoCall> history = videoCallService.getCallHistory(userId);
            return ResponseEntity.ok(ResponseDTO.success(history));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/{callId}")
    @Operation(summary = "\u83b7\u53d6\u901a\u8bdd\u8be6\u60c5", description = "\u6839\u636e\u901a\u8bdd ID \u83b7\u53d6\u8be6\u60c5")
    public ResponseEntity<ResponseDTO<VideoCall>> getCallById(
            @Parameter(description = "\u901a\u8bdd ID") @PathVariable Long callId) {
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
    @Operation(summary = "\u83b7\u53d6\u901a\u8bdd\u7edf\u8ba1", description = "\u83b7\u53d6\u6307\u5b9a\u7528\u6237\u7684\u901a\u8bdd\u7edf\u8ba1\u6570\u636e")
    public ResponseEntity<ResponseDTO<Map<String, Object>>> getCallStatistics(
            @Parameter(description = "\u7528\u6237 ID") @PathVariable Long userId) {
        try {
            Map<String, Object> stats = videoCallService.getCallStatistics(userId);
            return ResponseEntity.ok(ResponseDTO.success(stats));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{callId}/signal")
    @Operation(summary = "\u53d1\u9001 WebRTC \u4fe1\u4ee4", description = "\u53d1\u9001 WebRTC \u534f\u5546\u4fe1\u4ee4\u6570\u636e")
    public ResponseEntity<ResponseDTO<Void>> sendSignal(
            @Parameter(description = "\u901a\u8bdd ID") @PathVariable Long callId,
            @Parameter(description = "\u7528\u6237 ID") @RequestParam Long userId,
            @Parameter(description = "\u4fe1\u4ee4\u7c7b\u578b") @RequestParam String signalType,
            @RequestBody Map<String, Object> signalData) {
        try {
            videoCallService.handleWebRTCSignal(callId, userId, signalType, signalData);
            return ResponseEntity.ok(ResponseDTO.success(null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }
}
