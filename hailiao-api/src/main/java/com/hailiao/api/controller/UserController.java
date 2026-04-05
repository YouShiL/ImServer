package com.hailiao.api.controller;

import com.hailiao.api.dto.ChangePasswordRequestDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.SearchUserRequestDTO;
import com.hailiao.api.dto.UpdateOnlineStatusRequestDTO;
import com.hailiao.api.dto.UserDTO;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Tag(name = "User")
@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired
    private UserService userService;

    @Operation(summary = "Get current profile")
    @GetMapping("/profile")
    public ResponseEntity<ResponseDTO<UserDTO>> getProfile(@RequestAttribute("userId") Long userId) {
        try {
            return ResponseEntity.ok(ResponseDTO.success(toUserDTO(userService.getUserById(userId), false)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "Get user by id")
    @GetMapping("/{userId}")
    public ResponseEntity<ResponseDTO<UserDTO>> getUserById(@RequestAttribute("userId") Long currentUserId,
                                                            @PathVariable Long userId) {
        try {
            User user = userService.getUserById(userId);
            return ResponseEntity.ok(ResponseDTO.success(toUserDTO(user, !user.getId().equals(currentUserId))));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "Get user by business id")
    @GetMapping("/by-userid/{userId}")
    public ResponseEntity<ResponseDTO<UserDTO>> getUserByUserId(@RequestAttribute("userId") Long currentUserId,
                                                                @PathVariable String userId) {
        try {
            User user = userService.getUserByUserId(userId);
            return ResponseEntity.ok(ResponseDTO.success(toUserDTO(user, !user.getId().equals(currentUserId))));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "Update current profile")
    @PutMapping("/profile")
    public ResponseEntity<ResponseDTO<UserDTO>> updateProfile(@RequestAttribute("userId") Long userId,
                                                              @RequestBody User user) {
        try {
            user.setId(userId);
            User updatedUser = userService.updateUser(user);
            return ResponseEntity.ok(ResponseDTO.success(toUserDTO(updatedUser, false)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "Change password")
    @PostMapping("/change-password")
    public ResponseEntity<ResponseDTO<String>> changePassword(@RequestAttribute("userId") Long userId,
                                                              @RequestBody ChangePasswordRequestDTO request) {
        try {
            if (request.getOldPassword() == null || request.getNewPassword() == null) {
                return ResponseEntity.badRequest().body(ResponseDTO.badRequest("请填写原密码和新密码"));
            }
            userService.changePassword(userId, request.getOldPassword(), request.getNewPassword());
            return ResponseEntity.ok(ResponseDTO.success("密码修改成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "Search user")
    @PostMapping("/search")
    public ResponseEntity<ResponseDTO<UserDTO>> searchUser(@RequestAttribute("userId") Long currentUserId,
                                                           @RequestBody SearchUserRequestDTO request) {
        try {
            User user;
            if ("phone".equals(request.getType())) {
                user = userService.getUserByPhone(request.getKeyword());
                if (!user.getId().equals(currentUserId)
                        && user.getAllowSearchByPhone() != null
                        && !user.getAllowSearchByPhone()) {
                    return ResponseEntity.badRequest().body(ResponseDTO.badRequest("用户不存在"));
                }
            } else if ("userId".equals(request.getType())) {
                user = userService.getUserByUserId(request.getKeyword());
            } else {
                return ResponseEntity.badRequest().body(ResponseDTO.badRequest("不支持的搜索类型"));
            }

            return ResponseEntity.ok(ResponseDTO.success(toUserDTO(user, !user.getId().equals(currentUserId))));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "Get current online status")
    @GetMapping("/online-status")
    public ResponseEntity<ResponseDTO<Map<String, Object>>> getOnlineStatus(@RequestAttribute("userId") Long userId) {
        try {
            User user = userService.getUserById(userId);
            Map<String, Object> response = new HashMap<>();
            response.put("onlineStatus", user.getOnlineStatus());
            return ResponseEntity.ok(ResponseDTO.success(response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "Update current online status")
    @PostMapping("/update-online-status")
    public ResponseEntity<ResponseDTO<String>> updateOnlineStatus(@RequestAttribute("userId") Long userId,
                                                                  @RequestBody UpdateOnlineStatusRequestDTO request) {
        try {
            userService.updateOnlineStatus(userId, request.getStatus());
            return ResponseEntity.ok(ResponseDTO.success("在线状态更新成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private UserDTO toUserDTO(User user, boolean hidePhone) {
        UserDTO userDTO = new UserDTO();
        userDTO.setId(user.getId());
        userDTO.setUserId(user.getUserId());
        userDTO.setPhone(hidePhone ? null : user.getPhone());
        userDTO.setNickname(user.getNickname());
        userDTO.setAvatar(user.getAvatar());
        userDTO.setGender(user.getGender());
        userDTO.setRegion(user.getRegion());
        userDTO.setSignature(user.getSignature());
        userDTO.setBackground(user.getBackground());
        userDTO.setOnlineStatus(user.getOnlineStatus());
        userDTO.setIsVip(user.getIsVip());
        userDTO.setIsPrettyNumber(user.getIsPrettyNumber());
        userDTO.setPrettyNumber(user.getPrettyNumber());
        userDTO.setFriendLimit(user.getFriendLimit());
        userDTO.setGroupLimit(user.getGroupLimit());
        userDTO.setGroupMemberLimit(user.getGroupMemberLimit());
        userDTO.setDeviceLock(user.getDeviceLock());
        userDTO.setShowOnlineStatus(user.getShowOnlineStatus());
        userDTO.setShowLastOnline(user.getShowLastOnline());
        userDTO.setAllowSearchByPhone(user.getAllowSearchByPhone());
        userDTO.setNeedFriendVerification(user.getNeedFriendVerification());
        userDTO.setStatus(user.getStatus());
        userDTO.setCreatedAt(user.getCreatedAt());
        userDTO.setUpdatedAt(user.getUpdatedAt());
        userDTO.setLastLoginAt(user.getLastLoginAt());
        userDTO.setLastLoginIp(user.getLastLoginIp());
        return userDTO;
    }
}
