package com.hailiao.api.controller;

import com.hailiao.api.dto.AddToBlacklistRequestDTO;
import com.hailiao.api.dto.BlacklistDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.UserDTO;
import com.hailiao.common.entity.Blacklist;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.BlacklistService;
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

import java.util.ArrayList;
import java.util.List;

/**
 * 黑名单管理控制器
 * 处理黑名单的添加、移除、查询等操作
 * 
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Tag(name = "黑名单管理", description = "黑名单相关接口 - 添加、移除、查询黑名单")
@RestController
@RequestMapping("/api/blacklist")
public class BlacklistController {

    @Autowired
    private BlacklistService blacklistService;

    @Autowired
    private UserService userService;

    @Operation(summary = "添加到黑名单", description = "将指定用户添加到黑名单，添加后对方无法给您发送消息")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "添加成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "400", description = "添加失败，参数错误或用户不存在", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @PostMapping("/add")
    public ResponseEntity<ResponseDTO<BlacklistDTO>> addToBlacklist(@RequestAttribute("userId") Long userId,
                                            @Parameter(name = "request", description = "添加黑名单请求参数", required = true, schema = @Schema(implementation = AddToBlacklistRequestDTO.class)) @RequestBody AddToBlacklistRequestDTO request) {
        try {
            Long blockedUserId = request.getBlockedUserId();
            Blacklist blacklist = blacklistService.addToBlacklist(userId, blockedUserId);
            BlacklistDTO dto = convertToDTO(blacklist);
            return ResponseEntity.ok(ResponseDTO.success(dto));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "从黑名单移除", description = "将指定用户从黑名单中移除，移除后对方可以给您发送消息")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "移除成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "400", description = "移除失败", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @DeleteMapping("/{blockedUserId}")
    public ResponseEntity<ResponseDTO<String>> removeFromBlacklist(@RequestAttribute("userId") Long userId,
                                                 @Parameter(name = "blockedUserId", description = "被拉黑用户ID", required = true, example = "2") @PathVariable Long blockedUserId) {
        try {
            blacklistService.removeFromBlacklist(userId, blockedUserId);
            return ResponseEntity.ok(ResponseDTO.success("移除成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "获取黑名单列表", description = "获取当前登录用户添加的所有黑名单列表")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @GetMapping("/list")
    public ResponseEntity<ResponseDTO<List<BlacklistDTO>>> getBlacklist(@RequestAttribute("userId") Long userId) {
        try {
            List<Blacklist> blacklist = blacklistService.getBlacklist(userId);
            List<BlacklistDTO> dtoList = new ArrayList<>();
            for (Blacklist bl : blacklist) {
                dtoList.add(convertToDTO(bl));
            }
            return ResponseEntity.ok(ResponseDTO.success(dtoList));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "检查是否在黑名单", description = "检查指定用户是否在当前用户的黑名单中")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @GetMapping("/check/{blockedUserId}")
    public ResponseEntity<ResponseDTO<Boolean>> isBlocked(@RequestAttribute("userId") Long userId,
                                       @Parameter(name = "blockedUserId", description = "被检查用户ID", required = true, example = "2") @PathVariable Long blockedUserId) {
        try {
            boolean isBlocked = blacklistService.isBlocked(userId, blockedUserId);
            return ResponseEntity.ok(ResponseDTO.success(isBlocked));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private BlacklistDTO convertToDTO(Blacklist blacklist) {
        BlacklistDTO dto = new BlacklistDTO();
        dto.setId(blacklist.getId());
        dto.setUserId(blacklist.getUserId());
        dto.setBlockedUserId(blacklist.getBlockedUserId());
        dto.setCreatedAt(blacklist.getCreatedAt());

        try {
            User user = userService.getUserById(blacklist.getBlockedUserId());
            if (user != null) {
                UserDTO userDTO = new UserDTO();
                userDTO.setId(user.getId());
                userDTO.setUserId(user.getUserId());
                userDTO.setNickname(user.getNickname());
                userDTO.setAvatar(user.getAvatar());
                dto.setBlockedUserInfo(userDTO);
            }
        } catch (Exception e) {
        }

        return dto;
    }
}
