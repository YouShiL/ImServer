package com.hailiao.api.controller;

import com.hailiao.api.dto.GroupDTO;
import com.hailiao.api.dto.GroupMemberDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.UserDTO;
import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupMember;
import com.hailiao.common.service.GroupMemberService;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.GroupChatService;
import com.hailiao.common.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 群组管理控制器
 * 处理群组的创建、管理、成员操作等功能
 * 
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Tag(name = "群组管理", description = "群组相关接口 - 创建群聊、管理成员、群设置")
@RestController
@RequestMapping("/api/group")
public class GroupController {

    @Autowired
    private GroupChatService groupChatService;

    @Autowired
    private UserService userService;

    @Autowired
    private GroupMemberService groupMemberService;

    @Operation(summary = "创建群组", description = "创建一个新的群聊，可选择添加初始成员")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "创建成功"),
        @ApiResponse(responseCode = "400", description = "创建失败，参数错误"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/create")
    public ResponseEntity<ResponseDTO<GroupDTO>> createGroup(@RequestAttribute("userId") Long userId,
                                         @Parameter(name = "request", description = "创建群组请求参数", required = true,
                                                 example = "{\"groupName\": \"测试群聊\", \"description\": \"测试描述\", \"memberIds\": [2, 3]}") @RequestBody Map<String, Object> request) {
        try {
            String groupName = (String) request.get("groupName");
            String description = (String) request.get("description");
            @SuppressWarnings("unchecked")
            List<Long> memberIds = (List<Long>) request.get("memberIds");
            
            GroupChat group = groupChatService.createGroup(userId, groupName, description, memberIds);
            GroupDTO groupDTO = convertGroupToDTO(group);
            return ResponseEntity.ok(ResponseDTO.success(groupDTO));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "获取群组信息", description = "根据群组ID获取群组的详细信息")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功"),
        @ApiResponse(responseCode = "400", description = "群组不存在"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @GetMapping("/{groupId}")
    public ResponseEntity<ResponseDTO<GroupDTO>> getGroup(@Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId) {
        try {
            GroupChat group = groupChatService.getGroupById(groupId);
            GroupDTO groupDTO = convertGroupToDTO(group);
            return ResponseEntity.ok(ResponseDTO.success(groupDTO));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "根据唯一标识获取群组", description = "根据群组唯一业务ID获取群组详细信息")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功"),
        @ApiResponse(responseCode = "400", description = "群组不存在"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @GetMapping("/by-groupid/{groupId}")
    public ResponseEntity<ResponseDTO<GroupDTO>> getGroupByGroupId(@Parameter(name = "groupId", description = "群组唯一标识", required = true, example = "G100000001") @PathVariable String groupId) {
        try {
            GroupChat group = groupChatService.getGroupByGroupId(groupId);
            GroupDTO groupDTO = convertGroupToDTO(group);
            return ResponseEntity.ok(ResponseDTO.success(groupDTO));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "添加群组成员", description = "向指定群组添加新成员，只有群主和管理员可以添加成员")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "添加成功"),
        @ApiResponse(responseCode = "400", description = "添加失败，用户已是成员或无权限"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/{groupId}/member")
    public ResponseEntity<ResponseDTO<GroupMemberDTO>> addMember(@RequestAttribute("userId") Long userId,
                                       @Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId,
                                       @Parameter(name = "request", description = "添加成员请求参数", required = true,
                                               example = "{\"memberId\": 2, \"role\": 0}") @RequestBody Map<String, Object> request) {
        try {
            Long memberId = Long.valueOf(request.get("memberId").toString());
            Integer role = request.get("role") != null ? Integer.valueOf(request.get("role").toString()) : 3;

            if (!groupMemberService.canInviteMembers(groupId, userId)) {
                return ResponseEntity.badRequest().body(ResponseDTO.badRequest("当前群组不允许普通成员邀请新成员"));
            }
            
            GroupMember member = groupChatService.addGroupMember(groupId, memberId, role, userId);
            GroupMemberDTO memberDTO = convertMemberToDTO(member);
            return ResponseEntity.ok(ResponseDTO.success(memberDTO));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "移除群组成员", description = "从指定群组移除成员，只有群主和管理员可以移除成员")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "移除成功"),
        @ApiResponse(responseCode = "400", description = "移除失败，无权限"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @DeleteMapping("/{groupId}/member/{memberId}")
    public ResponseEntity<ResponseDTO<String>> removeMember(@RequestAttribute("userId") Long userId,
                                          @Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId,
                                          @Parameter(name = "memberId", description = "成员ID", required = true, example = "2") @PathVariable Long memberId) {
        try {
            groupChatService.removeGroupMember(groupId, memberId);
            return ResponseEntity.ok(ResponseDTO.success("移除成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "退出群组", description = "当前用户退出指定群组")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "退出成功"),
        @ApiResponse(responseCode = "400", description = "退出失败"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/{groupId}/quit")
    public ResponseEntity<ResponseDTO<String>> quitGroup(@RequestAttribute("userId") Long userId,
                                       @Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId) {
        try {
            groupChatService.quitGroup(groupId, userId);
            return ResponseEntity.ok(ResponseDTO.success("退出成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "获取群组成员", description = "获取指定群组的所有成员列表")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功"),
        @ApiResponse(responseCode = "400", description = "群组不存在"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @GetMapping("/{groupId}/members")
    public ResponseEntity<ResponseDTO<List<GroupMemberDTO>>> getGroupMembers(@Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId) {
        try {
            List<GroupMember> members = groupChatService.getGroupMembers(groupId);
            List<GroupMemberDTO> memberDTOs = new ArrayList<>();
            for (GroupMember member : members) {
                memberDTOs.add(convertMemberToDTO(member));
            }
            return ResponseEntity.ok(ResponseDTO.success(memberDTOs));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "获取我的群组", description = "获取当前登录用户加入的所有群组列表")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @GetMapping("/my-groups")
    public ResponseEntity<ResponseDTO<List<GroupDTO>>> getMyGroups(@RequestAttribute("userId") Long userId) {
        try {
            List<GroupChat> groups = groupChatService.getUserGroupChats(userId);
            List<GroupDTO> groupDTOs = new ArrayList<>();
            for (GroupChat group : groups) {
                groupDTOs.add(convertGroupToDTO(group));
            }
            return ResponseEntity.ok(ResponseDTO.success(groupDTOs));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "更新群组信息", description = "更新群组的基本信息，只有群主可以修改")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "更新成功"),
        @ApiResponse(responseCode = "400", description = "更新失败，无权限"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PutMapping("/{groupId}")
    public ResponseEntity<ResponseDTO<GroupDTO>> updateGroupInfo(@RequestAttribute("userId") Long userId,
                                             @Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId,
                                             @Parameter(name = "request", description = "更新群组信息请求参数", required = true,
                                                     example = "{\"groupName\": \"新群名\", \"description\": \"新描述\", \"notice\": \"新公告\", \"avatar\": \"https://example.com/avatar.jpg\"}") @RequestBody Map<String, String> request) {
        try {
            String groupName = request.get("groupName");
            String description = request.get("description");
            String notice = request.get("notice");
            String avatar = request.get("avatar");
            Boolean allowMemberInvite = request.get("allowMemberInvite") != null
                    ? Boolean.valueOf(request.get("allowMemberInvite"))
                    : null;
            Integer joinType = request.get("joinType") != null
                    ? Integer.valueOf(request.get("joinType"))
                    : null;
            
            GroupChat group = groupChatService.updateGroupInfo(
                    groupId, groupName, description, notice, avatar, allowMemberInvite, joinType);
            GroupDTO groupDTO = convertGroupToDTO(group);
            return ResponseEntity.ok(ResponseDTO.success(groupDTO));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "转让群所有权", description = "将群主身份转让给指定成员，只有群主可以操作")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "转让成功"),
        @ApiResponse(responseCode = "400", description = "转让失败，无权限"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/{groupId}/transfer")
    public ResponseEntity<ResponseDTO<String>> transferOwner(@RequestAttribute("userId") Long userId,
                                           @Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId,
                                           @Parameter(name = "request", description = "转让群主请求参数", required = true,
                                                   example = "{\"newOwnerId\": 2}") @RequestBody Map<String, Object> request) {
        try {
            Long newOwnerId = Long.valueOf(request.get("newOwnerId").toString());
            groupChatService.transferGroupOwner(groupId, newOwnerId);
            return ResponseEntity.ok(ResponseDTO.success("转让成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "设置群组静音", description = "设置群组的静音状态，开启后不会收到消息通知")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "设置成功"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/{groupId}/mute")
    public ResponseEntity<ResponseDTO<String>> setGroupMute(@RequestAttribute("userId") Long userId,
                                          @Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId,
                                          @Parameter(name = "request", description = "设置静音请求参数", required = true,
                                                  example = "{\"isMute\": true}") @RequestBody Map<String, Boolean> request) {
        try {
            Boolean isMute = request.get("isMute");
            groupChatService.setGroupMute(groupId, isMute);
            return ResponseEntity.ok(ResponseDTO.success("设置成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "设置成员静音", description = "设置群组成员的静音状态")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "设置成功"),
        @ApiResponse(responseCode = "400", description = "设置失败"),
        @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/{groupId}/member/{memberId}/mute")
    public ResponseEntity<ResponseDTO<String>> setMemberMute(@RequestAttribute("userId") Long userId,
                                           @Parameter(name = "groupId", description = "群组ID", required = true, example = "1") @PathVariable Long groupId,
                                           @Parameter(name = "memberId", description = "成员ID", required = true, example = "2") @PathVariable Long memberId,
                                           @Parameter(name = "request", description = "设置成员静音请求参数", required = true,
                                                   example = "{\"isMute\": true}") @RequestBody Map<String, Boolean> request) {
        try {
            Boolean isMute = request.get("isMute");
            groupChatService.setMemberMute(groupId, memberId, isMute);
            return ResponseEntity.ok(ResponseDTO.success("设置成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private GroupDTO convertGroupToDTO(GroupChat group) {
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

    private GroupMemberDTO convertMemberToDTO(GroupMember member) {
        GroupMemberDTO dto = new GroupMemberDTO();
        dto.setId(member.getId());
        dto.setGroupId(member.getGroupId());
        dto.setUserId(member.getUserId());
        dto.setNickname(member.getNickname());
        dto.setRole(member.getRole());
        dto.setIsMute(member.getIsMute());
        dto.setJoinedAt(member.getJoinTime());

        try {
            User user = userService.getUserById(member.getUserId());
            if (user != null) {
                UserDTO userDTO = new UserDTO();
                userDTO.setId(user.getId());
                userDTO.setUserId(user.getUserId());
                userDTO.setNickname(user.getNickname());
                userDTO.setAvatar(user.getAvatar());
                userDTO.setOnlineStatus(user.getOnlineStatus());
                dto.setUserInfo(userDTO);
            }
        } catch (Exception e) {
        }

        return dto;
    }
}
