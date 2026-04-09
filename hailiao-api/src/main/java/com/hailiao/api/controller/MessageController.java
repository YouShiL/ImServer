package com.hailiao.api.controller;

import com.hailiao.api.dto.MessageDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.SendGroupMessageRequestDTO;
import com.hailiao.api.dto.SendPrivateMessageRequestDTO;
import com.hailiao.api.dto.UserDTO;
import com.hailiao.common.entity.Message;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.MessageService;
import com.hailiao.common.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@Tag(name = "消息管理", description = "消息相关接口")
@RestController
@RequestMapping("/api/message")
public class MessageController {

    @Autowired
    private MessageService messageService;

    @Autowired
    private UserService userService;

    @PostMapping("/send/private")
    public ResponseEntity<ResponseDTO<MessageDTO>> sendPrivateMessage(@RequestAttribute("userId") Long userId,
                                                                     @RequestBody SendPrivateMessageRequestDTO request) {
        try {
            Message message = messageService.sendPrivateMessage(
                    userId,
                    request.getToUserId(),
                    request.getContent(),
                    request.getMsgType() != null ? request.getMsgType() : 1,
                    request.getExtra(),
                    request.getClientMsgNo());
            return ResponseEntity.ok(ResponseDTO.success(convertToDTO(message)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/send/group")
    public ResponseEntity<ResponseDTO<MessageDTO>> sendGroupMessage(@RequestAttribute("userId") Long userId,
                                                                   @RequestBody SendGroupMessageRequestDTO request) {
        try {
            Message message = messageService.sendGroupMessage(
                    userId,
                    request.getGroupId(),
                    request.getContent(),
                    request.getMsgType() != null ? request.getMsgType() : 1,
                    request.getExtra(),
                    request.getClientMsgNo());
            return ResponseEntity.ok(ResponseDTO.success(convertToDTO(message)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/{messageId}/recall")
    public ResponseEntity<ResponseDTO<String>> recallMessage(@RequestAttribute("userId") Long userId,
                                                             @PathVariable Long messageId) {
        try {
            messageService.recallMessage(messageId, userId);
            return ResponseEntity.ok(ResponseDTO.success("撤回成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/private/{toUserId}")
    public ResponseEntity<ResponseDTO<Page<MessageDTO>>> getPrivateMessages(@RequestAttribute("userId") Long userId,
                                                                            @PathVariable Long toUserId,
                                                                            @RequestParam(defaultValue = "0") int page,
                                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<MessageDTO> dtoPage = messageService.getPrivateMessages(userId, toUserId, pageable).map(this::convertToDTO);
            return ResponseEntity.ok(ResponseDTO.success(dtoPage));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/group/{groupId}")
    public ResponseEntity<ResponseDTO<Page<MessageDTO>>> getGroupMessages(@PathVariable Long groupId,
                                                                          @RequestParam(defaultValue = "0") int page,
                                                                          @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<MessageDTO> dtoPage = messageService.getGroupMessages(groupId, pageable).map(this::convertToDTO);
            return ResponseEntity.ok(ResponseDTO.success(dtoPage));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/unread/{fromUserId}")
    public ResponseEntity<ResponseDTO<List<MessageDTO>>> getUnreadMessages(@RequestAttribute("userId") Long userId,
                                                                           @PathVariable Long fromUserId) {
        try {
            List<MessageDTO> dtoList = new ArrayList<>();
            for (Message message : messageService.getUnreadMessages(userId, fromUserId)) {
                dtoList.add(convertToDTO(message));
            }
            return ResponseEntity.ok(ResponseDTO.success(dtoList));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/read/{fromUserId}")
    public ResponseEntity<ResponseDTO<String>> markAsRead(@RequestAttribute("userId") Long userId,
                                                          @PathVariable Long fromUserId) {
        try {
            messageService.markAsRead(userId, fromUserId);
            return ResponseEntity.ok(ResponseDTO.success("已标记为已读"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/unread-count/{fromUserId}")
    public ResponseEntity<ResponseDTO<Long>> getUnreadCount(@RequestAttribute("userId") Long userId,
                                                            @PathVariable Long fromUserId) {
        try {
            return ResponseEntity.ok(ResponseDTO.success(messageService.getUnreadCount(userId, fromUserId)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    public MessageDTO convertToDTO(Message message) {
        MessageDTO dto = new MessageDTO();
        dto.setId(message.getId());
        dto.setMsgId(message.getMsgId());
        dto.setFromUserId(message.getFromUserId());
        dto.setToUserId(message.getToUserId());
        dto.setGroupId(message.getGroupId());
        dto.setContent(message.getContent());
        dto.setMsgType(message.getMsgType());
        dto.setExtra(message.getExtra());
        dto.setStatus(message.getStatus());
        dto.setCreatedAt(message.getCreatedAt());
        dto.setReplyToMsgId(message.getReplyToMsgId());
        dto.setForwardFromMsgId(message.getForwardFromMsgId());
        dto.setForwardFromUserId(message.getForwardFromUserId());
        dto.setIsEdited(message.getIsEdited());
        dto.setIsRead(message.getIsRead());
        dto.setIsRecalled(message.getIsRecall());
        dto.setClientMsgNo(message.getClientMsgNo());

        try {
            User user = userService.getUserById(message.getFromUserId());
            UserDTO userDTO = new UserDTO();
            userDTO.setId(user.getId());
            userDTO.setUserId(user.getUserId());
            userDTO.setNickname(user.getNickname());
            userDTO.setAvatar(user.getAvatar());
            dto.setFromUserInfo(userDTO);
        } catch (Exception ignored) {
        }

        return dto;
    }
}
