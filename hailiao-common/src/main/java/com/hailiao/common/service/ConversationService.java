package com.hailiao.common.service;

import com.hailiao.common.entity.Conversation;
import com.hailiao.common.repository.ConversationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

@Service
public class ConversationService {

    @Autowired
    private ConversationRepository conversationRepository;

    public List<Conversation> getConversationList(Long userId) {
        return conversationRepository.findByUserIdOrderByIsTopDescUpdatedAtDesc(userId);
    }

    @Transactional
    public void setTop(Long userId, Long targetId, Integer type, Boolean isTop) {
        Conversation conversation = conversationRepository.findByUserIdAndTargetIdAndType(userId, targetId, type)
                .orElseThrow(() -> new RuntimeException("\u4f1a\u8bdd\u4e0d\u5b58\u5728"));
        conversation.setIsTop(isTop);
        conversation.setUpdatedAt(new Date());
        conversationRepository.save(conversation);
    }

    @Transactional
    public void setMute(Long userId, Long targetId, Integer type, Boolean isMute) {
        Conversation conversation = conversationRepository.findByUserIdAndTargetIdAndType(userId, targetId, type)
                .orElseThrow(() -> new RuntimeException("\u4f1a\u8bdd\u4e0d\u5b58\u5728"));
        conversation.setIsMute(isMute);
        conversation.setUpdatedAt(new Date());
        conversationRepository.save(conversation);
    }

    @Transactional
    public void deleteConversation(Long userId, Long targetId, Integer type) {
        Conversation conversation = conversationRepository.findByUserIdAndTargetIdAndType(userId, targetId, type)
                .orElseThrow(() -> new RuntimeException("\u4f1a\u8bdd\u4e0d\u5b58\u5728"));
        conversationRepository.delete(conversation);
    }

    public long getTotalUnreadCount(Long userId) {
        return conversationRepository.countByUserIdAndUnreadCountGreaterThan(userId, 0);
    }
}
