package com.hailiao.common.service;

import com.hailiao.common.entity.Blacklist;
import com.hailiao.common.repository.BlacklistRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

@Service
public class BlacklistService {

    @Autowired
    private BlacklistRepository blacklistRepository;

    @Transactional
    public Blacklist addToBlacklist(Long userId, Long blockedUserId) {
        if (userId.equals(blockedUserId)) {
            throw new RuntimeException("不能拉黑自己");
        }

        if (blacklistRepository.existsByUserIdAndBlockedUserId(userId, blockedUserId)) {
            throw new RuntimeException("已在黑名单中");
        }

        Blacklist blacklist = new Blacklist();
        blacklist.setUserId(userId);
        blacklist.setBlockedUserId(blockedUserId);
        blacklist.setCreatedAt(new Date());

        return blacklistRepository.save(blacklist);
    }

    @Transactional
    public void removeFromBlacklist(Long userId, Long blockedUserId) {
        blacklistRepository.deleteByUserIdAndBlockedUserId(userId, blockedUserId);
    }

    public List<Blacklist> getBlacklist(Long userId) {
        return blacklistRepository.findByUserId(userId);
    }

    public boolean isBlocked(Long userId, Long blockedUserId) {
        return blacklistRepository.existsByUserIdAndBlockedUserId(userId, blockedUserId);
    }
}
