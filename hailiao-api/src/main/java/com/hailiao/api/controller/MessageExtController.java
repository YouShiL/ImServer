package com.hailiao.api.controller;

import com.hailiao.api.dto.MessageDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.Message;
import com.hailiao.common.service.MessageService;
import com.hailiao.common.service.UserOnlineService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/message/ext")
public class MessageExtController {

    @Autowired
    private MessageService messageService;

    @Autowired
    private UserOnlineService userOnlineService;

    @Autowired
    private MessageController messageController;

    @PostMapping("/reply")
    public ResponseEntity<ResponseDTO<MessageDTO>> replyMessage(@RequestAttribute("userId") Long userId,
                                                                @RequestParam Long replyToMsgId,
                                                                @RequestParam(required = false) Long toUserId,
                                                                @RequestParam(required = false) Long groupId,
                                                                @RequestParam String content,
                                                                @RequestParam(defaultValue = "1") Integer msgType,
                                                                @RequestParam(required = false) String extra) {
        Message message = messageService.replyToMessage(userId, toUserId, groupId, replyToMsgId, content, msgType, extra);
        return ResponseEntity.ok(ResponseDTO.success(messageController.convertToDTO(message)));
    }

    @PostMapping("/forward")
    public ResponseEntity<ResponseDTO<MessageDTO>> forwardMessage(@RequestAttribute("userId") Long userId,
                                                                  @RequestParam Long originalMsgId,
                                                                  @RequestParam(required = false) Long toUserId,
                                                                  @RequestParam(required = false) Long groupId) {
        Message message = messageService.forwardMessage(userId, toUserId, groupId, originalMsgId);
        return ResponseEntity.ok(ResponseDTO.success(messageController.convertToDTO(message)));
    }

    @PutMapping("/{messageId}/edit")
    public ResponseEntity<ResponseDTO<MessageDTO>> editMessage(@RequestAttribute("userId") Long userId,
                                                               @PathVariable Long messageId,
                                                               @RequestParam String newContent) {
        Message message = messageService.editMessage(messageId, userId, newContent);
        return ResponseEntity.ok(ResponseDTO.success(messageController.convertToDTO(message)));
    }

    @PutMapping("/{messageId}/pin")
    public ResponseEntity<ResponseDTO<MessageDTO>> pinMessage(@RequestAttribute("userId") Long userId,
                                                              @PathVariable Long messageId,
                                                              @RequestParam boolean pinned) {
        Message message = messageService.pinMessage(messageId, userId, pinned);
        return ResponseEntity.ok(ResponseDTO.success(messageController.convertToDTO(message)));
    }

    @PostMapping("/group/at")
    public ResponseEntity<ResponseDTO<MessageDTO>> sendGroupMessageWithAt(@RequestAttribute("userId") Long userId,
                                                                          @RequestParam Long groupId,
                                                                          @RequestParam String content,
                                                                          @RequestParam(defaultValue = "1") Integer msgType,
                                                                          @RequestParam(required = false) String extra,
                                                                          @RequestParam(required = false) List<Long> atUserIds,
                                                                          @RequestParam(defaultValue = "false") boolean atAll) {
        Message message = messageService.sendGroupMessageWithAt(userId, groupId, content, msgType, extra, atUserIds, atAll);
        return ResponseEntity.ok(ResponseDTO.success(messageController.convertToDTO(message)));
    }

    @PostMapping("/{messageId}/read")
    public ResponseEntity<ResponseDTO<String>> markGroupMessageAsRead(@RequestAttribute("userId") Long userId,
                                                                      @PathVariable Long messageId) {
        messageService.markGroupMessageAsRead(messageId, userId);
        return ResponseEntity.ok(ResponseDTO.success("\u5df2\u6807\u8bb0\u5df2\u8bfb"));
    }

    @GetMapping("/{messageId}/read-status")
    public ResponseEntity<ResponseDTO<Object>> getMessageReadStatus(@PathVariable Long messageId) {
        return ResponseEntity.ok(ResponseDTO.success(messageService.getMessageReadStatus(messageId)));
    }

    @GetMapping("/search")
    public ResponseEntity<ResponseDTO<Object>> searchMessages(@RequestAttribute("userId") Long userId,
                                                              @RequestParam String keyword,
                                                              @RequestParam(defaultValue = "0") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(ResponseDTO.success(messageService.searchMessages(userId, keyword, pageable)));
    }

    @GetMapping("/group/{groupId}/search")
    public ResponseEntity<ResponseDTO<Object>> searchGroupMessages(@PathVariable Long groupId,
                                                                   @RequestParam String keyword,
                                                                   @RequestParam(defaultValue = "0") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(ResponseDTO.success(messageService.searchGroupMessages(groupId, keyword, pageable)));
    }

    @GetMapping("/pinned")
    public ResponseEntity<ResponseDTO<Object>> getPinnedMessages(@RequestAttribute("userId") Long userId,
                                                                 @RequestParam(required = false) Long groupId) {
        return ResponseEntity.ok(ResponseDTO.success(
                messageService.searchMessages(userId, "", PageRequest.of(0, 100))
        ));
    }

    @PostMapping("/heartbeat")
    public ResponseEntity<ResponseDTO<String>> heartbeat(@RequestAttribute("userId") Long userId) {
        userOnlineService.heartbeat(userId);
        return ResponseEntity.ok(ResponseDTO.success("\u64cd\u4f5c\u6210\u529f"));
    }
}
