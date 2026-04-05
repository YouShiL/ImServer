package com.hailiao.admin.controller;

import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.service.GroupChatService;
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
 * 群组管理控制器。
 */
@RestController
@RequestMapping("/admin/group")
public class GroupManageController {

    @Autowired
    private GroupChatService groupChatService;

    /**
     * 分页获取群组列表。
     */
    @GetMapping("/list")
    public ResponseEntity<?> getGroupList(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<GroupChat> groups = groupChatService.getGroupList(keyword, status, pageable);
            return ResponseEntity.ok(toGroupPageResponse(groups));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据 ID 获取群组详情。
     */
    @GetMapping("/{groupId}")
    public ResponseEntity<?> getGroupById(@PathVariable Long groupId) {
        try {
            GroupChat group = groupChatService.getGroupById(groupId);
            return ResponseEntity.ok(group);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据群号码获取群组详情。
     */
    @GetMapping("/by-groupid/{groupId}")
    public ResponseEntity<?> getGroupByGroupId(@PathVariable String groupId) {
        try {
            GroupChat group = groupChatService.getGroupByGroupId(groupId);
            return ResponseEntity.ok(group);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 更新群组信息。
     */
    @PutMapping("/{groupId}")
    public ResponseEntity<?> updateGroup(@PathVariable Long groupId, @RequestBody GroupChat group) {
        try {
            group.setId(groupId);
            GroupChat updatedGroup = groupChatService.updateGroupInfo(
                    groupId,
                    group.getGroupName(),
                    group.getDescription(),
                    group.getNotice(),
                    group.getAvatar(),
                    group.getAllowMemberInvite(),
                    group.getJoinType());
            return ResponseEntity.ok(updatedGroup);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 设置群组静音状态。
     */
    @PostMapping("/{groupId}/mute")
    public ResponseEntity<?> setGroupMute(@PathVariable Long groupId, @RequestBody Map<String, Boolean> request) {
        try {
            Boolean isMute = request.get("isMute");
            groupChatService.setGroupMute(groupId, isMute);
            return ResponseEntity.ok("设置成功");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取群组统计信息。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getGroupStats() {
        try {
            Map<String, Long> stats = new HashMap<>();
            stats.put("totalGroups", groupChatService.getTotalGroupCount());
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toGroupPageResponse(Page<GroupChat> groups) {
        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        long mutedCount = 0L;
        long verifyJoinCount = 0L;
        for (GroupChat group : groups.getContent()) {
            content.add(toGroupResponse(group));
            if (Boolean.TRUE.equals(group.getIsMute()) || Boolean.TRUE.equals(group.getMuteAll())) {
                mutedCount++;
            }
            if (group.getJoinType() != null && group.getJoinType() == 2) {
                verifyJoinCount++;
            }
        }

        Map<String, Object> summary = new LinkedHashMap<String, Object>();
        summary.put("filteredTotal", groups.getTotalElements());
        summary.put("currentPageCount", groups.getNumberOfElements());
        summary.put("mutedGroups", mutedCount);
        summary.put("verifyJoinGroups", verifyJoinCount);

        Map<String, Object> page = new LinkedHashMap<String, Object>();
        page.put("content", content);
        page.put("page", groups.getNumber());
        page.put("size", groups.getSize());
        page.put("totalElements", groups.getTotalElements());
        page.put("totalPages", groups.getTotalPages());
        page.put("first", groups.isFirst());
        page.put("last", groups.isLast());
        page.put("summary", summary);
        return page;
    }

    private Map<String, Object> toGroupResponse(GroupChat group) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", group.getId());
        item.put("groupId", group.getGroupId());
        item.put("groupName", group.getGroupName());
        item.put("ownerId", group.getOwnerId());
        item.put("memberCount", group.getMemberCount());
        item.put("maxMemberCount", group.getMaxMemberCount());
        item.put("status", group.getStatus());
        item.put("statusLabel", getGroupStatusLabel(group.getStatus()));
        item.put("isMute", group.getIsMute());
        item.put("muteLabel", Boolean.TRUE.equals(group.getIsMute()) ? "已禁言" : "未禁言");
        item.put("muteAll", group.getMuteAll());
        item.put("muteAllLabel", Boolean.TRUE.equals(group.getMuteAll()) ? "全员禁言" : "未开启");
        item.put("allowMemberInvite", group.getAllowMemberInvite());
        item.put("allowMemberInviteLabel", Boolean.TRUE.equals(group.getAllowMemberInvite()) ? "允许成员邀请" : "仅管理员可邀请");
        item.put("joinType", group.getJoinType());
        item.put("joinTypeLabel", getJoinTypeLabel(group.getJoinType()));
        item.put("createdAt", group.getCreatedAt());
        item.put("updatedAt", group.getUpdatedAt());
        return item;
    }

    private String getJoinTypeLabel(Integer joinType) {
        if (joinType == null || joinType == 1) {
            return "直接加入";
        }
        if (joinType == 2) {
            return "需要验证";
        }
        return "未知";
    }

    private String getGroupStatusLabel(Integer status) {
        if (status == null || status == 1) {
            return "正常";
        }
        if (status == 0) {
            return "已禁用";
        }
        return "未知";
    }
}
