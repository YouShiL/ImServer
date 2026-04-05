package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupMember;
import com.hailiao.common.service.GroupChatService;
import com.hailiao.common.service.GroupJoinRequestService;
import com.hailiao.common.service.GroupMemberService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Tag(name = "Group Member")
@RestController
@RequestMapping("/api/group")
public class GroupMemberController {

    @Autowired
    private GroupMemberService groupMemberService;

    @Autowired
    private GroupChatService groupChatService;

    @Autowired
    private GroupJoinRequestService groupJoinRequestService;

    @PostMapping("/{groupId}/join")
    public ResponseEntity<ResponseDTO<String>> joinGroup(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long groupId,
            @RequestBody(required = false) Map<String, Object> request) {
        try {
            GroupChat group = groupChatService.getGroupById(groupId);
            if (group.getJoinType() != null && group.getJoinType() != 0) {
                String message = request != null ? (String) request.get("message") : null;
                groupJoinRequestService.submitJoinRequest(groupId, userId, message);
                return ResponseEntity.ok(ResponseDTO.success("入群申请已提交"));
            }

            groupMemberService.joinGroup(groupId, userId);
            return ResponseEntity.ok(ResponseDTO.success("已加入群组"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{groupId}/leave")
    public ResponseEntity<ResponseDTO<String>> leaveGroup(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long groupId) {
        try {
            groupMemberService.leaveGroup(groupId, userId);
            return ResponseEntity.ok(ResponseDTO.success("已退出群组"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{groupId}/kick/{targetUserId}")
    public ResponseEntity<ResponseDTO<String>> kickMember(
            @RequestAttribute("userId") Long operatorId,
            @PathVariable Long groupId,
            @PathVariable Long targetUserId) {
        try {
            groupMemberService.kickMember(groupId, targetUserId, operatorId);
            return ResponseEntity.ok(ResponseDTO.success("已移除成员"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{groupId}/admin/{targetUserId}")
    public ResponseEntity<ResponseDTO<String>> setAdmin(
            @RequestAttribute("userId") Long operatorId,
            @PathVariable Long groupId,
            @PathVariable Long targetUserId) {
        try {
            groupMemberService.setGroupAdmin(groupId, targetUserId, operatorId);
            return ResponseEntity.ok(ResponseDTO.success("设置成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @DeleteMapping("/{groupId}/admin/{targetUserId}")
    public ResponseEntity<ResponseDTO<String>> removeAdmin(
            @RequestAttribute("userId") Long operatorId,
            @PathVariable Long groupId,
            @PathVariable Long targetUserId) {
        try {
            groupMemberService.removeGroupAdmin(groupId, targetUserId, operatorId);
            return ResponseEntity.ok(ResponseDTO.success("设置成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{groupId}/transfer/{targetUserId}")
    public ResponseEntity<ResponseDTO<String>> transferOwnership(
            @RequestAttribute("userId") Long operatorId,
            @PathVariable Long groupId,
            @PathVariable Long targetUserId) {
        try {
            groupMemberService.transferOwnership(groupId, targetUserId, operatorId);
            return ResponseEntity.ok(ResponseDTO.success("转让成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{groupId}/mute/{targetUserId}")
    public ResponseEntity<ResponseDTO<String>> muteMember(
            @RequestAttribute("userId") Long operatorId,
            @PathVariable Long groupId,
            @PathVariable Long targetUserId,
            @RequestParam(required = false) Integer minutes) {
        try {
            groupMemberService.muteMember(groupId, targetUserId, operatorId, minutes);
            return ResponseEntity.ok(ResponseDTO.success("已禁言"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @DeleteMapping("/{groupId}/mute/{targetUserId}")
    public ResponseEntity<ResponseDTO<String>> unmuteMember(
            @RequestAttribute("userId") Long operatorId,
            @PathVariable Long groupId,
            @PathVariable Long targetUserId) {
        try {
            groupMemberService.unmuteMember(groupId, targetUserId, operatorId);
            return ResponseEntity.ok(ResponseDTO.success("已解除禁言"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{groupId}/mute-all")
    public ResponseEntity<ResponseDTO<String>> muteAll(
            @RequestAttribute("userId") Long operatorId,
            @PathVariable Long groupId,
            @RequestParam boolean mute) {
        try {
            groupMemberService.muteAll(groupId, operatorId, mute);
            return ResponseEntity.ok(ResponseDTO.success("设置成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PutMapping("/{groupId}/notice")
    public ResponseEntity<ResponseDTO<String>> updateNotice(
            @RequestAttribute("userId") Long operatorId,
            @PathVariable Long groupId,
            @RequestParam String notice) {
        try {
            groupMemberService.updateGroupNotice(groupId, operatorId, notice);
            return ResponseEntity.ok(ResponseDTO.success("设置成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/{groupId}/member-list")
    public ResponseEntity<ResponseDTO<List<GroupMember>>> getMembers(@PathVariable Long groupId) {
        try {
            return ResponseEntity.ok(ResponseDTO.success(groupMemberService.getGroupMembers(groupId)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/{groupId}/admins")
    public ResponseEntity<ResponseDTO<List<GroupMember>>> getAdmins(@PathVariable Long groupId) {
        try {
            return ResponseEntity.ok(ResponseDTO.success(groupMemberService.getGroupAdmins(groupId)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/{groupId}/member/{targetUserId}")
    public ResponseEntity<ResponseDTO<GroupMember>> getMember(
            @PathVariable Long groupId,
            @PathVariable Long targetUserId) {
        try {
            return ResponseEntity.ok(ResponseDTO.success(
                    groupMemberService.getGroupMember(groupId, targetUserId).orElse(null)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/{groupId}/can-send")
    public ResponseEntity<ResponseDTO<Boolean>> canSendMessage(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long groupId) {
        try {
            return ResponseEntity.ok(ResponseDTO.success(groupMemberService.canSendGroupMessage(groupId, userId)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }
}

