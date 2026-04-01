package com.hailiao.admin.controller;

import com.hailiao.common.entity.VipMember;
import com.hailiao.common.service.VipMemberService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * VIP 管理控制器。
 */
@RestController
@RequestMapping("/admin/vip")
public class VipManageController {

    @Autowired
    private VipMemberService vipMemberService;

    /**
     * 获取全部 VIP 列表。
     */
    @GetMapping("/list")
    public ResponseEntity<?> getVipList() {
        try {
            List<VipMember> vips = vipMemberService.getAllVipMembers();
            return ResponseEntity.ok(toVipListResponse(vips));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据用户 ID 获取 VIP 信息。
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getVipByUserId(@PathVariable Long userId) {
        try {
            VipMember vip = vipMemberService.getVipMemberByUserId(userId);
            return ResponseEntity.ok(toVipResponse(vip));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 授予用户 VIP。
     */
    @PostMapping("/grant")
    public ResponseEntity<?> grantVip(@RequestBody Map<String, Object> request) {
        try {
            Long userId = Long.valueOf(request.get("userId").toString());
            Integer vipLevel = Integer.valueOf(request.get("vipLevel").toString());
            Integer months = Integer.valueOf(request.get("months").toString());
            VipMember vip = vipMemberService.createVipMember(userId, vipLevel, months);
            return ResponseEntity.ok(toVipResponse(vip));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 取消用户 VIP。
     */
    @PostMapping("/user/{userId}/cancel")
    public ResponseEntity<?> cancelVip(@PathVariable Long userId) {
        try {
            vipMemberService.cancelVip(userId);
            return ResponseEntity.ok("VIP \u53d6\u6d88\u6210\u529f");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取 VIP 统计信息。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getVipStats() {
        try {
            Map<String, Object> levelStats = new LinkedHashMap<String, Object>();
            levelStats.put("1", mapOf("vipLevel", 1, "vipLevelLabel", "VIP1", "count", vipMemberService.getVipCountByLevel(1)));
            levelStats.put("2", mapOf("vipLevel", 2, "vipLevelLabel", "VIP2", "count", vipMemberService.getVipCountByLevel(2)));
            levelStats.put("3", mapOf("vipLevel", 3, "vipLevelLabel", "VIP3", "count", vipMemberService.getVipCountByLevel(3)));

            Map<String, Object> stats = new LinkedHashMap<String, Object>();
            stats.put("totalVips", vipMemberService.getTotalVipCount());
            stats.put("levelStats", levelStats);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toVipListResponse(List<VipMember> vips) {
        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        long activeCount = 0L;
        long expiredCount = 0L;
        for (VipMember vip : vips) {
            content.add(toVipResponse(vip));
            if (vip.getStatus() != null && vip.getStatus() == 1) {
                activeCount++;
            } else {
                expiredCount++;
            }
        }

        Map<String, Object> response = new LinkedHashMap<String, Object>();
        response.put("content", content);
        response.put("summary", mapOf(
                "filteredTotal", vips.size(),
                "activeCount", activeCount,
                "expiredCount", expiredCount
        ));
        return response;
    }

    private Map<String, Object> toVipResponse(VipMember vip) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", vip.getId());
        item.put("userId", vip.getUserId());
        item.put("vipLevel", vip.getVipLevel());
        item.put("vipLevelLabel", getVipLevelLabel(vip.getVipLevel()));
        item.put("status", vip.getStatus());
        item.put("statusLabel", vip.getStatus() != null && vip.getStatus() == 1 ? "\u751f\u6548\u4e2d" : "\u5df2\u5931\u6548");
        item.put("startTime", vip.getStartTime());
        item.put("expireTime", vip.getExpireTime());
        item.put("createdAt", vip.getCreatedAt());
        return item;
    }

    private String getVipLevelLabel(Integer vipLevel) {
        if (vipLevel == null) {
            return "\u672a\u77e5\u7b49\u7ea7";
        }
        switch (vipLevel) {
            case 1:
                return "VIP1";
            case 2:
                return "VIP2";
            case 3:
                return "VIP3";
            default:
                return "VIP" + vipLevel;
        }
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
