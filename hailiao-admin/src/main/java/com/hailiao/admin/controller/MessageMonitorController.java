package com.hailiao.admin.controller;

import com.hailiao.common.entity.Message;
import com.hailiao.common.repository.MessageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin/messages")
public class MessageMonitorController {

    @Autowired
    private MessageRepository messageRepository;

    @GetMapping
    public ResponseEntity<Map<String, Object>> getMessages(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Long groupId,
            @RequestParam(required = false) Integer msgType) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Message> messages;

        if (groupId != null) {
            messages = messageRepository.findByGroupIdOrderByCreatedAtDesc(groupId, pageable);
        } else if (userId != null) {
            messages = messageRepository.findByFromUserIdOrToUserId(userId, userId, pageable);
        } else if (msgType != null) {
            messages = messageRepository.findByMsgType(msgType, pageable);
        } else {
            messages = messageRepository.findAll(pageable);
        }

        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        long recalledCount = 0L;
        for (Message message : messages.getContent()) {
            content.add(toMessageResponse(message));
            if (Boolean.TRUE.equals(message.getIsRecall())) {
                recalledCount++;
            }
        }

        Map<String, Object> response = new LinkedHashMap<String, Object>();
        response.put("content", content);
        response.put("totalElements", messages.getTotalElements());
        response.put("totalPages", messages.getTotalPages());
        response.put("currentPage", messages.getNumber());
        response.put("pageSize", messages.getSize());
        response.put("summary", mapOf(
                "currentPageCount", messages.getNumberOfElements(),
                "recalledCount", recalledCount,
                "msgTypeLabel", getMsgTypeLabel(msgType)
        ));
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Message> getMessageById(@PathVariable Long id) {
        return messageRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    private Map<String, Object> toMessageResponse(Message message) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", message.getId());
        item.put("msgId", message.getMsgId());
        item.put("fromUserId", message.getFromUserId());
        item.put("toUserId", message.getToUserId());
        item.put("groupId", message.getGroupId());
        item.put("msgType", message.getMsgType());
        item.put("msgTypeLabel", getMsgTypeLabel(message.getMsgType()));
        item.put("content", message.getContent());
        item.put("status", message.getStatus());
        item.put("statusLabel", message.getStatus() != null && message.getStatus() == 1 ? "\u6b63\u5e38" : "\u5f02\u5e38");
        item.put("isRead", message.getIsRead());
        item.put("readLabel", Boolean.TRUE.equals(message.getIsRead()) ? "\u5df2\u8bfb" : "\u672a\u8bfb");
        item.put("isRecall", message.getIsRecall());
        item.put("recallLabel", Boolean.TRUE.equals(message.getIsRecall()) ? "\u5df2\u64a4\u56de" : "\u672a\u64a4\u56de");
        item.put("createdAt", message.getCreatedAt());
        return item;
    }

    private String getMsgTypeLabel(Integer msgType) {
        if (msgType == null) {
            return "\u5168\u90e8\u7c7b\u578b";
        }
        switch (msgType) {
            case 1:
                return "\u6587\u672c";
            case 2:
                return "\u56fe\u7247";
            case 3:
                return "\u97f3\u9891";
            case 4:
                return "\u89c6\u9891";
            case 5:
                return "\u6587\u4ef6";
            case 6:
                return "\u4f4d\u7f6e";
            default:
                return "\u672a\u77e5\u7c7b\u578b";
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
