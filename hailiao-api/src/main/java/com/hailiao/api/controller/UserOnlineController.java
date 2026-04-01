package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.service.UserOnlineService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/online")
public class UserOnlineController {

    @Autowired
    private UserOnlineService userOnlineService;

    @GetMapping("/status/{userId}")
    public ResponseEntity<ResponseDTO> getOnlineStatus(
            @RequestAttribute("userId") Long currentUserId,
            @PathVariable Long userId) {
        Map<String, Object> info = userOnlineService.getUserOnlineInfo(currentUserId, userId);
        return ResponseEntity.ok(ResponseDTO.success(info));
    }

    @PostMapping("/batch-status")
    public ResponseEntity<ResponseDTO> batchGetOnlineStatus(
            @RequestBody List<Long> userIds) {
        Map<Long, Boolean> status = userOnlineService.batchGetOnlineStatus(userIds);
        return ResponseEntity.ok(ResponseDTO.success(status));
    }

    @PutMapping("/settings")
    public ResponseEntity<ResponseDTO> updateOnlineSettings(
            @RequestAttribute("userId") Long userId,
            @RequestParam(required = false) Boolean showOnlineStatus,
            @RequestParam(required = false) Boolean showLastOnline) {
        userOnlineService.updateOnlineStatusSetting(userId, showOnlineStatus, showLastOnline);
        return ResponseEntity.ok(ResponseDTO.success(null));
    }

    @PostMapping("/online")
    public ResponseEntity<ResponseDTO> setOnline(
            @RequestAttribute("userId") Long userId) {
        userOnlineService.setUserOnline(userId);
        return ResponseEntity.ok(ResponseDTO.success(null));
    }

    @PostMapping("/offline")
    public ResponseEntity<ResponseDTO> setOffline(
            @RequestAttribute("userId") Long userId) {
        userOnlineService.setUserOffline(userId);
        return ResponseEntity.ok(ResponseDTO.success(null));
    }
}
