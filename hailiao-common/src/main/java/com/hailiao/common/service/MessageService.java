package com.hailiao.common.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hailiao.common.entity.Conversation;
import com.hailiao.common.entity.ContentAudit;
import com.hailiao.common.entity.Message;
import com.hailiao.common.entity.MessageReadStatus;
import com.hailiao.common.repository.ConversationRepository;
import com.hailiao.common.repository.MessageReadStatusRepository;
import com.hailiao.common.repository.MessageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MessageService {

    private static final Logger logger = LoggerFactory.getLogger(MessageService.class);
    private static final int RECALL_TIME_LIMIT = 2 * 60 * 1000;
    private static final int EDIT_TIME_LIMIT = 15 * 60 * 1000;

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private ConversationRepository conversationRepository;

    @Autowired
    private MessageReadStatusRepository messageReadStatusRepository;

    @Autowired(required = false)
    private GroupRobotService groupRobotService;

    @Autowired
    private MessageCacheService messageCacheService;

    @Autowired(required = false)
    private WebSocketNotificationService notificationService;

    @Autowired(required = false)
    private ContentAuditService contentAuditService;

    private ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 发送私聊消息，并同步更新双方会话。
     */
    @Transactional
    public Message sendPrivateMessage(Long fromUserId, Long toUserId, String content, Integer msgType, String extra) {
        Message message = new Message();
        message.setMsgId(UUID.randomUUID().toString().replace("-", ""));
        message.setFromUserId(fromUserId);
        message.setToUserId(toUserId);
        message.setContent(content);
        message.setMsgType(msgType != null ? msgType : 1);
        message.setExtra(extra);
        message.setStatus(1);
        message.setIsRead(false);
        message.setIsRecall(false);
        message.setCreatedAt(new Date());

        Message savedMessage = messageRepository.save(message);

        updateConversation(fromUserId, toUserId, 1, savedMessage);
        updateConversation(toUserId, fromUserId, 1, savedMessage);

        try {
            messageCacheService.cachePrivateMessage(fromUserId, toUserId, savedMessage);
        } catch (Exception e) {
            logger.warn("\u7f13\u5b58\u79c1\u804a\u6d88\u606f\u5931\u8d25: {}", e.getMessage());
        }

        createContentAuditIfNeeded(savedMessage);
        return savedMessage;
    }

    private void createContentAuditIfNeeded(Message message) {
        if (contentAuditService == null || message == null) {
            return;
        }
        if (message.getFromUserId() == null || message.getFromUserId() <= 0) {
            return;
        }
        if (message.getMsgType() == null || message.getMsgType() < 1 || message.getMsgType() > 6) {
            return;
        }

        try {
            ContentAudit audit = new ContentAudit();
            audit.setContentType(message.getMsgType());
            audit.setTargetId(message.getId());
            audit.setUserId(message.getFromUserId());
            audit.setContent(buildAuditContent(message));
            contentAuditService.createAudit(audit);
        } catch (Exception e) {
            logger.warn("\u521b\u5efa\u5185\u5bb9\u5ba1\u6838\u8bb0\u5f55\u5931\u8d25: {}", e.getMessage());
        }
    }

    private String buildAuditContent(Message message) {
        if (message.getContent() != null && !message.getContent().trim().isEmpty()) {
            return message.getContent();
        }
        if (message.getExtra() != null && !message.getExtra().trim().isEmpty()) {
            return message.getExtra();
        }
        return "";
    }

    /**
     * 发送群聊消息。
     */
    @Transactional
    public Message sendGroupMessage(Long fromUserId, Long groupId, String content, Integer msgType, String extra) {
        Message message = new Message();
        message.setMsgId(UUID.randomUUID().toString().replace("-", ""));
        message.setFromUserId(fromUserId);
        message.setGroupId(groupId);
        message.setContent(content);
        message.setMsgType(msgType != null ? msgType : 1);
        message.setExtra(extra);
        message.setStatus(1);
        message.setIsRead(false);
        message.setIsRecall(false);
        message.setCreatedAt(new Date());

        Message savedMessage = messageRepository.save(message);

        if (groupRobotService != null && fromUserId > 0) {
            try {
                groupRobotService.processGroupMessage(savedMessage);
            } catch (Exception e) {
                // 机器人处理失败不影响消息发送。
            }
        }

        try {
            messageCacheService.cacheGroupMessage(groupId, savedMessage);
        } catch (Exception e) {
            logger.warn("\u7f13\u5b58\u7fa4\u804a\u6d88\u606f\u5931\u8d25: {}", e.getMessage());
        }

        createContentAuditIfNeeded(savedMessage);
        return savedMessage;
    }

    /**
     * 撤回消息。仅允许撤回自己发送且在时限内的消息。
     */
    @Transactional
    public void recallMessage(Long messageId, Long userId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("\u6d88\u606f\u4e0d\u5b58\u5728"));

        if (!message.getFromUserId().equals(userId)) {
            throw new RuntimeException("\u53ea\u80fd\u64a4\u56de\u81ea\u5df1\u7684\u6d88\u606f");
        }

        long diff = new Date().getTime() - message.getCreatedAt().getTime();
        if (diff > 2 * 60 * 1000) {
            throw new RuntimeException("\u6d88\u606f\u8d85\u8fc7 2 \u5206\u949f\uff0c\u65e0\u6cd5\u64a4\u56de");
        }

        message.setIsRecall(true);
        message.setRecallTime(new Date());
        messageRepository.save(message);
    }

    /**
     * 获取私聊消息记录。
     */
    public Page<Message> getPrivateMessages(Long fromUserId, Long toUserId, Pageable pageable) {
        return messageRepository.findByFromUserIdAndToUserIdOrderByCreatedAtDesc(fromUserId, toUserId, pageable);
    }

    /**
     * 获取群聊消息记录。
     */
    public Page<Message> getGroupMessages(Long groupId, Pageable pageable) {
        return messageRepository.findByGroupIdOrderByCreatedAtDesc(groupId, pageable);
    }

    /**
     * 获取最近 7 天的未读消息。
     */
    public List<Message> getUnreadMessages(Long userId, Long fromUserId) {
        return messageRepository.findByFromUserIdAndToUserIdAndCreatedAtAfter(
                fromUserId, userId, new Date(System.currentTimeMillis() - 7 * 24 * 60 * 60 * 1000));
    }

    /**
     * 标记指定发送方的消息为已读，并更新会话未读数。
     */
    @Transactional
    public void markAsRead(Long userId, Long fromUserId) {
        List<Message> messages = messageRepository.findByFromUserIdAndToUserIdAndCreatedAtAfter(
                fromUserId, userId, new Date(System.currentTimeMillis() - 7 * 24 * 60 * 60 * 1000));
        
        for (Message message : messages) {
            if (!message.getIsRead()) {
                message.setIsRead(true);
                messageRepository.save(message);
            }
        }

        Conversation conversation = conversationRepository.findByUserIdAndTargetIdAndType(userId, fromUserId, 1)
                .orElse(null);
        if (conversation != null) {
            conversation.setUnreadCount(0);
            conversationRepository.save(conversation);
        }
    }

    /**
     * 获取未读消息数量。
     */
    public long getUnreadCount(Long userId, Long fromUserId) {
        return messageRepository.countByFromUserIdAndToUserIdAndIsReadFalse(fromUserId, userId);
    }

    /**
     * 创建或更新会话，并同步最后一条消息与未读计数。
     */
    private void updateConversation(Long userId, Long targetId, Integer type, Message message) {
        Conversation conversation = conversationRepository.findByUserIdAndTargetIdAndType(userId, targetId, type)
                .orElse(new Conversation());

        conversation.setUserId(userId);
        conversation.setTargetId(targetId);
        conversation.setType(type);
        conversation.setLastMsgId(message.getId());
        conversation.setLastMsgContent(getMessagePreview(message));
        
        if (conversation.getUnreadCount() == null) {
            conversation.setUnreadCount(0);
        }
        if (!userId.equals(message.getFromUserId())) {
            conversation.setUnreadCount(conversation.getUnreadCount() + 1);
        }
        
        if (conversation.getIsTop() == null) {
            conversation.setIsTop(false);
        }
        if (conversation.getIsMute() == null) {
            conversation.setIsMute(false);
        }
        
        conversation.setUpdatedAt(new Date());
        conversationRepository.save(conversation);
    }

    /**
     * 根据消息类型生成会话预览文本。
     */
    private String getMessagePreview(Message message) {
        if (message.getIsRecall() != null && message.getIsRecall()) {
            return "[\u6d88\u606f\u5df2\u64a4\u56de]";
        }
        switch (message.getMsgType()) {
            case 1:
                return message.getContent();
            case 2:
                return "[\u56fe\u7247]";
            case 3:
                return "[\u97f3\u9891]";
            case 4:
                return "[\u89c6\u9891]";
            case 5:
                return "[\u6587\u4ef6]";
            case 6:
                return "[\u4f4d\u7f6e]";
            default:
                return "[\u672a\u77e5\u6d88\u606f]";
        }
    }

    @Transactional
    public Message replyToMessage(Long fromUserId, Long toUserId, Long groupId, Long replyToMsgId, 
                                   String content, Integer msgType, String extra) {
        Message replyMessage;
        if (groupId != null) {
            replyMessage = sendGroupMessage(fromUserId, groupId, content, msgType, extra);
        } else {
            replyMessage = sendPrivateMessage(fromUserId, toUserId, content, msgType, extra);
        }
        
        replyMessage.setReplyToMsgId(replyToMsgId);
        return messageRepository.save(replyMessage);
    }

    @Transactional
    public Message forwardMessage(Long fromUserId, Long toUserId, Long groupId, Long originalMsgId) {
        Message originalMsg = messageRepository.findById(originalMsgId)
                .orElseThrow(() -> new RuntimeException("\u539f\u6d88\u606f\u4e0d\u5b58\u5728"));

        if (originalMsg.getIsRecall() != null && originalMsg.getIsRecall()) {
            throw new RuntimeException("\u5df2\u64a4\u56de\u7684\u6d88\u606f\u65e0\u6cd5\u8f6c\u53d1");
        }

        Message forwardMessage;
        if (groupId != null) {
            forwardMessage = sendGroupMessage(fromUserId, groupId, originalMsg.getContent(), 
                    originalMsg.getMsgType(), originalMsg.getExtra());
        } else {
            forwardMessage = sendPrivateMessage(fromUserId, toUserId, originalMsg.getContent(), 
                    originalMsg.getMsgType(), originalMsg.getExtra());
        }

        forwardMessage.setForwardFromMsgId(originalMsgId);
        forwardMessage.setForwardFromUserId(originalMsg.getFromUserId());
        
        return messageRepository.save(forwardMessage);
    }

    @Transactional
    public Message editMessage(Long messageId, Long userId, String newContent) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("\u6d88\u606f\u4e0d\u5b58\u5728"));

        if (!message.getFromUserId().equals(userId)) {
            throw new RuntimeException("\u53ea\u80fd\u7f16\u8f91\u81ea\u5df1\u7684\u6d88\u606f");
        }

        long diff = new Date().getTime() - message.getCreatedAt().getTime();
        if (diff > EDIT_TIME_LIMIT) {
            throw new RuntimeException("\u6d88\u606f\u8d85\u8fc7 15 \u5206\u949f\uff0c\u65e0\u6cd5\u7f16\u8f91");
        }

        if (message.getMsgType() != 1) {
            throw new RuntimeException("\u53ea\u80fd\u7f16\u8f91\u6587\u672c\u6d88\u606f");
        }

        message.setContent(newContent);
        message.setIsEdited(true);
        message.setEditTime(new Date());
        
        return messageRepository.save(message);
    }

    @Transactional
    public Message pinMessage(Long messageId, Long userId, boolean pinned) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("\u6d88\u606f\u4e0d\u5b58\u5728"));

        message.setIsPinned(pinned);
        message.setPinTime(pinned ? new Date() : null);
        
        return messageRepository.save(message);
    }

    @Transactional
    public Message sendGroupMessageWithAt(Long fromUserId, Long groupId, String content, 
                                           Integer msgType, String extra, List<Long> atUserIds, boolean atAll) {
        Message message = sendGroupMessage(fromUserId, groupId, content, msgType, extra);
        
        if (atUserIds != null && !atUserIds.isEmpty()) {
            try {
                message.setAtUserIds(objectMapper.writeValueAsString(atUserIds));
            } catch (JsonProcessingException e) {
                logger.warn("\u5e8f\u5217\u5316 @\u7528\u6237\u5217\u8868\u5931\u8d25: {}", e.getMessage());
            }
        }
        message.setIsAtAll(atAll);
        
        return messageRepository.save(message);
    }

    @Transactional
    public void markGroupMessageAsRead(Long messageId, Long userId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("\u6d88\u606f\u4e0d\u5b58\u5728"));

        if (message.getGroupId() == null) {
            throw new RuntimeException("\u53ea\u80fd\u6807\u8bb0\u7fa4\u804a\u6d88\u606f\u7684\u5df2\u8bfb\u72b6\u6001");
        }

        MessageReadStatus existing = messageReadStatusRepository
                .findByMessageIdAndUserId(messageId, userId)
                .orElse(null);

        if (existing == null) {
            MessageReadStatus status = new MessageReadStatus();
            status.setMessageId(messageId);
            status.setUserId(userId);
            status.setReadAt(new Date());
            messageReadStatusRepository.save(status);

            message.setReadCount(message.getReadCount() == null ? 1 : message.getReadCount() + 1);
            messageRepository.save(message);
        }
    }

    public Map<String, Object> getMessageReadStatus(Long messageId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("消息不存在"));

        Map<String, Object> result = new HashMap<>();
        result.put("messageId", messageId);
        result.put("readCount", message.getReadCount() != null ? message.getReadCount() : 0);

        List<MessageReadStatus> readStatuses = messageReadStatusRepository.findByMessageId(messageId);
        List<Long> readUserIds = readStatuses.stream()
                .map(MessageReadStatus::getUserId)
                .collect(Collectors.toList());
        result.put("readUserIds", readUserIds);

        return result;
    }

    public List<Long> getAtUserIds(Message message) {
        if (message.getAtUserIds() == null || message.getAtUserIds().isEmpty()) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(message.getAtUserIds(), new TypeReference<List<Long>>() {});
        } catch (JsonProcessingException e) {
            logger.warn("\u89e3\u6790 @\u7528\u6237\u5217\u8868\u5931\u8d25: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    public Page<Message> searchMessages(Long userId, String keyword, Pageable pageable) {
        return messageRepository.searchMessages(userId, keyword, pageable);
    }

    public Page<Message> searchGroupMessages(Long groupId, String keyword, Pageable pageable) {
        return messageRepository.searchGroupMessages(groupId, keyword, pageable);
    }
}
