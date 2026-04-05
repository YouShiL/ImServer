package com.hailiao.api.controller;

import com.hailiao.api.dto.GroupJoinRequestDTO;
import com.hailiao.api.dto.GroupDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.UserDTO;
import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupJoinRequest;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.GroupJoinRequestService;
import com.hailiao.common.service.GroupChatService;
import com.hailiao.common.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/group")
public class GroupJoinRequestController {

    @Autowired
    private GroupJoinRequestService groupJoinRequestService;

    @Autowired
    private UserService userService;

    @Autowired
    private GroupChatService groupChatService;

    @GetMapping("/{groupId}/join-requests")
    public ResponseEntity<ResponseDTO<List<GroupJoinRequestDTO>>> getPendingRequests(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long groupId) {
        try {
            List<GroupJoinRequest> requests = groupJoinRequestService.getPendingRequests(groupId, userId);
            List<GroupJoinRequestDTO> dtos = new ArrayList<>();
            for (GroupJoinRequest request : requests) {
                dtos.add(toDTO(request));
            }
            return ResponseEntity.ok(ResponseDTO.success(dtos));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/join-requests/mine")
    public ResponseEntity<ResponseDTO<List<GroupJoinRequestDTO>>> getMyRequests(
            @RequestAttribute("userId") Long userId) {
        try {
            List<GroupJoinRequest> requests = groupJoinRequestService.getUserRequests(userId);
            List<GroupJoinRequestDTO> dtos = new ArrayList<>();
            for (GroupJoinRequest request : requests) {
                dtos.add(toDTO(request));
            }
            return ResponseEntity.ok(ResponseDTO.success(dtos));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/join-request/{requestId}/approve")
    public ResponseEntity<ResponseDTO<String>> approveRequest(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long requestId) {
        try {
            groupJoinRequestService.approveRequest(requestId, userId);
            return ResponseEntity.ok(ResponseDTO.success("已同意入群申请"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/join-request/{requestId}/reject")
    public ResponseEntity<ResponseDTO<String>> rejectRequest(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long requestId) {
        try {
            groupJoinRequestService.rejectRequest(requestId, userId);
            return ResponseEntity.ok(ResponseDTO.success("已拒绝入群申请"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @DeleteMapping("/join-request/{requestId}")
    public ResponseEntity<ResponseDTO<String>> withdrawRequest(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long requestId) {
        try {
            groupJoinRequestService.withdrawRequest(requestId, userId);
            return ResponseEntity.ok(ResponseDTO.success("已撤回入群申请"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private GroupJoinRequestDTO toDTO(GroupJoinRequest request) {
        GroupJoinRequestDTO dto = new GroupJoinRequestDTO();
        dto.setId(request.getId());
        dto.setGroupId(request.getGroupId());
        dto.setUserId(request.getUserId());
        dto.setMessage(request.getMessage());
        dto.setStatus(request.getStatus());
        dto.setHandledBy(request.getHandledBy());
        dto.setHandledAt(request.getHandledAt());
        dto.setCreatedAt(request.getCreatedAt());

        try {
            User user = userService.getUserById(request.getUserId());
            UserDTO userDTO = new UserDTO();
            userDTO.setId(user.getId());
            userDTO.setUserId(user.getUserId());
            userDTO.setNickname(user.getNickname());
            userDTO.setAvatar(user.getAvatar());
            userDTO.setOnlineStatus(user.getOnlineStatus());
            userDTO.setRegion(user.getRegion());
            dto.setUserInfo(userDTO);
        } catch (Exception ignored) {
        }

        try {
            GroupChat group = groupChatService.getGroupById(request.getGroupId());
            dto.setGroupInfo(toGroupDTO(group));
        } catch (Exception ignored) {
        }

        return dto;
    }

    private GroupDTO toGroupDTO(GroupChat group) {
        GroupDTO dto = new GroupDTO();
        dto.setId(group.getId());
        dto.setGroupId(group.getGroupId());
        dto.setGroupName(group.getGroupName());
        dto.setDescription(group.getDescription());
        dto.setNotice(group.getNotice());
        dto.setAvatar(group.getAvatar());
        dto.setOwnerId(group.getOwnerId());
        dto.setMemberCount(group.getMemberCount());
        dto.setMaxMembers(group.getMaxMemberCount());
        dto.setNeedVerify(group.getJoinType() != null && group.getJoinType() == 1);
        dto.setAllowMemberInvite(group.getAllowMemberInvite());
        dto.setJoinType(group.getJoinType());
        dto.setIsMute(group.getIsMute());
        dto.setStatus(group.getStatus());
        dto.setCreatedAt(group.getCreatedAt());
        dto.setUpdatedAt(group.getUpdatedAt());
        return dto;
    }
}

