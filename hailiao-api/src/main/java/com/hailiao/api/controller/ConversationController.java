package com.hailiao.api.controller;

import com.hailiao.api.dto.ConversationDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.SetMuteRequestDTO;
import com.hailiao.api.dto.SetTopRequestDTO;
import com.hailiao.common.entity.Conversation;
import com.hailiao.common.service.ConversationService;
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
 * 会话管理控制器
 * 处理会话列表获取、置顶、静音、删除等操作
 * 
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Tag(name = "会话管理", description = "会话相关接口 - 会话列表、置顶、静音、删除")
@RestController
@RequestMapping("/api/conversation")
public class ConversationController {

    @Autowired
    private ConversationService conversationService;

    @Operation(summary = "获取会话列表", description = "获取当前登录用户的所有会话列表，包含私聊和群聊")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @GetMapping("/list")
    public ResponseEntity<ResponseDTO<List<ConversationDTO>>> getConversationList(@RequestAttribute("userId") Long userId) {
        try {
            List<Conversation> conversations = conversationService.getConversationList(userId);
            List<ConversationDTO> dtoList = new ArrayList<>();
            for (Conversation conv : conversations) {
                ConversationDTO dto = convertToDTO(conv);
                dtoList.add(dto);
            }
            return ResponseEntity.ok(ResponseDTO.success(dtoList));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "设置会话置顶", description = "设置指定会话的置顶状态，置顶的会话会显示在列表最前面")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "设置成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "400", description = "设置失败", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @PostMapping("/{targetId}/top")
    public ResponseEntity<ResponseDTO<String>> setTop(@RequestAttribute("userId") Long userId,
                                    @Parameter(name = "targetId", description = "目标ID（用户ID或群组ID）", required = true, example = "2") @PathVariable Long targetId,
                                    @Parameter(name = "request", description = "设置置顶请求参数", required = true, schema = @Schema(implementation = SetTopRequestDTO.class)) @RequestBody SetTopRequestDTO request) {
        try {
            Integer type = request.getType();
            Boolean isTop = request.getIsTop();
            conversationService.setTop(userId, targetId, type, isTop);
            return ResponseEntity.ok(ResponseDTO.success("设置成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "设置会话静音", description = "设置指定会话的静音状态，静音后不会收到消息通知")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "设置成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "400", description = "设置失败", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @PostMapping("/{targetId}/mute")
    public ResponseEntity<ResponseDTO<String>> setMute(@RequestAttribute("userId") Long userId,
                                     @Parameter(name = "targetId", description = "目标ID（用户ID或群组ID）", required = true, example = "2") @PathVariable Long targetId,
                                     @Parameter(name = "request", description = "设置静音请求参数", required = true, schema = @Schema(implementation = SetMuteRequestDTO.class)) @RequestBody SetMuteRequestDTO request) {
        try {
            Integer type = request.getType();
            Boolean isMute = request.getIsMute();
            conversationService.setMute(userId, targetId, type, isMute);
            return ResponseEntity.ok(ResponseDTO.success("设置成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "删除会话", description = "删除指定的会话，删除后不会删除聊天记录")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "删除成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "400", description = "删除失败", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @DeleteMapping("/{targetId}")
    public ResponseEntity<ResponseDTO<String>> deleteConversation(@RequestAttribute("userId") Long userId,
                                                @Parameter(name = "targetId", description = "目标ID（用户ID或群组ID）", required = true, example = "2") @PathVariable Long targetId,
                                                @Parameter(name = "type", description = "会话类型（1：私聊，2：群聊）", required = true, example = "1") @RequestParam Integer type) {
        try {
            conversationService.deleteConversation(userId, targetId, type);
            return ResponseEntity.ok(ResponseDTO.success("删除成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "获取未读消息总数", description = "获取当前登录用户所有会话的未读消息总数")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "获取成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
        @ApiResponse(responseCode = "401", description = "未授权", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @GetMapping("/unread-total")
    public ResponseEntity<ResponseDTO<Long>> getTotalUnreadCount(@RequestAttribute("userId") Long userId) {
        try {
            long count = conversationService.getTotalUnreadCount(userId);
            return ResponseEntity.ok(ResponseDTO.success(count));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private ConversationDTO convertToDTO(Conversation conv) {
        ConversationDTO dto = new ConversationDTO();
        dto.setId(conv.getId());
        dto.setUserId(conv.getUserId());
        dto.setTargetId(conv.getTargetId());
        dto.setType(conv.getType());
        dto.setLastMessage(conv.getLastMsgContent());
        dto.setLastMessageTime(conv.getUpdatedAt());
        dto.setUnreadCount(conv.getUnreadCount());
        dto.setIsTop(conv.getIsTop());
        dto.setIsMute(conv.getIsMute());
        return dto;
    }
}
