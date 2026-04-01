package com.hailiao.admin.controller;

import com.hailiao.common.entity.User;
import com.hailiao.common.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 用户管理控制器。
 */
@RestController
@RequestMapping("/admin/user")
public class UserManageController {

    @Autowired
    private UserService userService;

    /**
     * 分页获取用户列表。
     */
    @GetMapping("/list")
    public ResponseEntity<?> getUserList(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<User> users = userService.getUserList(keyword, status, pageable);
            return ResponseEntity.ok(toUserPageResponse(users));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据 ID 获取用户详情。
     */
    @GetMapping("/{userId}")
    public ResponseEntity<?> getUserById(@PathVariable Long userId) {
        try {
            User user = userService.getUserById(userId);
            return ResponseEntity.ok(toUserResponse(user));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 更新用户信息。
     */
    @PutMapping("/{userId}")
    public ResponseEntity<?> updateUser(@PathVariable Long userId, @RequestBody User user) {
        try {
            user.setId(userId);
            User updatedUser = userService.updateUser(user);
            return ResponseEntity.ok(toUserResponse(updatedUser));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 封禁用户。
     */
    @PostMapping("/{userId}/ban")
    public ResponseEntity<?> banUser(@PathVariable Long userId, @RequestBody Map<String, String> request) {
        try {
            String reason = request.get("reason");
            userService.banUser(userId, reason);
            return ResponseEntity.ok("\u5c01\u7981\u6210\u529f");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 解封用户。
     */
    @PostMapping("/{userId}/unban")
    public ResponseEntity<?> unbanUser(@PathVariable Long userId) {
        try {
            userService.unbanUser(userId);
            return ResponseEntity.ok("\u89e3\u5c01\u6210\u529f");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取用户统计信息。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getUserStats() {
        try {
            long totalUsers = userService.getTotalUserCount();
            long activeUsers = userService.getActiveUserCount();
            long inactiveUsers = Math.max(0L, totalUsers - activeUsers);
            Map<String, Object> stats = new LinkedHashMap<String, Object>();
            stats.put("totalUsers", totalUsers);
            stats.put("activeUsers", activeUsers);
            stats.put("inactiveUsers", inactiveUsers);
            stats.put("summary", mapOf(
                    "activeLabel", "\u6b63\u5e38\u7528\u6237",
                    "inactiveLabel", "\u975e\u6d3b\u8dc3/\u5f02\u5e38\u7528\u6237",
                    "activeRatio", totalUsers == 0 ? "0.00%" : String.format("%.2f%%", (activeUsers * 100.0) / totalUsers)
            ));
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toUserPageResponse(Page<User> users) {
        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        long bannedCount = 0L;
        long vipCount = 0L;
        for (User user : users.getContent()) {
            content.add(toUserResponse(user));
            if (user.getStatus() != null && user.getStatus() == 0) {
                bannedCount++;
            }
            if (Boolean.TRUE.equals(user.getIsVip())) {
                vipCount++;
            }
        }

        Map<String, Object> summary = new LinkedHashMap<String, Object>();
        summary.put("filteredTotal", users.getTotalElements());
        summary.put("currentPageCount", users.getNumberOfElements());
        summary.put("bannedCount", bannedCount);
        summary.put("vipCount", vipCount);

        Map<String, Object> page = new LinkedHashMap<String, Object>();
        page.put("content", content);
        page.put("page", users.getNumber());
        page.put("size", users.getSize());
        page.put("totalElements", users.getTotalElements());
        page.put("totalPages", users.getTotalPages());
        page.put("first", users.isFirst());
        page.put("last", users.isLast());
        page.put("summary", summary);
        return page;
    }

    private Map<String, Object> toUserResponse(User user) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", user.getId());
        item.put("userId", user.getUserId());
        item.put("phone", user.getPhone());
        item.put("nickname", user.getNickname());
        item.put("gender", user.getGender());
        item.put("genderLabel", getGenderLabel(user.getGender()));
        item.put("onlineStatus", user.getOnlineStatus());
        item.put("onlineStatusLabel", user.getOnlineStatus() != null && user.getOnlineStatus() == 1 ? "\u5728\u7ebf" : "\u79bb\u7ebf");
        item.put("isVip", user.getIsVip());
        item.put("vipLabel", Boolean.TRUE.equals(user.getIsVip()) ? "VIP" : "\u666e\u901a\u7528\u6237");
        item.put("isPrettyNumber", user.getIsPrettyNumber());
        item.put("prettyNumberLabel", Boolean.TRUE.equals(user.getIsPrettyNumber()) ? "\u9773\u53f7\u7528\u6237" : "\u666e\u901a\u53f7\u7801");
        item.put("status", user.getStatus());
        item.put("statusLabel", user.getStatus() != null && user.getStatus() == 0 ? "\u5df2\u5c01\u7981" : "\u6b63\u5e38");
        item.put("deviceLock", user.getDeviceLock());
        item.put("deviceLockLabel", Boolean.TRUE.equals(user.getDeviceLock()) ? "\u5df2\u5f00\u542f" : "\u672a\u5f00\u542f");
        item.put("createdAt", user.getCreatedAt());
        item.put("lastLoginAt", user.getLastLoginAt());
        return item;
    }

    private String getGenderLabel(Integer gender) {
        if (gender == null || gender == 0) {
            return "\u672a\u8bbe\u7f6e";
        }
        if (gender == 1) {
            return "\u7537";
        }
        if (gender == 2) {
            return "\u5973";
        }
        return "\u672a\u77e5";
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
