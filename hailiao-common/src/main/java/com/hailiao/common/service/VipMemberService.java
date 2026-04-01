package com.hailiao.common.service;

import com.hailiao.common.entity.User;
import com.hailiao.common.entity.VipMember;
import com.hailiao.common.repository.UserRepository;
import com.hailiao.common.repository.VipMemberRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Calendar;
import java.util.Date;
import java.util.List;

@Service
public class VipMemberService {

    @Autowired
    private VipMemberRepository vipMemberRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public VipMember createVipMember(Long userId, Integer vipLevel, Integer months) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("\u7528\u6237\u4e0d\u5b58\u5728"));

        VipMember vipMember = vipMemberRepository.findByUserId(userId).orElse(new VipMember());

        Date now = new Date();
        Calendar calendar = Calendar.getInstance();

        if (vipMember.getId() != null && vipMember.getExpireTime().after(now)) {
            calendar.setTime(vipMember.getExpireTime());
        } else {
            vipMember.setUserId(userId);
            vipMember.setStartTime(now);
            calendar.setTime(now);
        }

        calendar.add(Calendar.MONTH, months);
        vipMember.setExpireTime(calendar.getTime());
        vipMember.setVipLevel(vipLevel);
        vipMember.setStatus(1);
        vipMember.setUpdatedAt(now);

        if (vipMember.getId() == null) {
            vipMember.setCreatedAt(now);
        }

        VipMember savedVip = vipMemberRepository.save(vipMember);

        user.setIsVip(true);
        user.setGroupLimit(999);
        user.setGroupMemberLimit(5000);
        userRepository.save(user);

        return savedVip;
    }

    public VipMember getVipMemberByUserId(Long userId) {
        return vipMemberRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("VIP\u4f1a\u5458\u4e0d\u5b58\u5728"));
    }

    public List<VipMember> getAllVipMembers() {
        return vipMemberRepository.findByStatus(1);
    }

    public boolean isVip(Long userId) {
        return vipMemberRepository.findByUserId(userId)
                .map(vip -> vip.getStatus() == 1 && vip.getExpireTime().after(new Date()))
                .orElse(false);
    }

    @Transactional
    public void checkAndUpdateVipStatus(Long userId) {
        VipMember vipMember = vipMemberRepository.findByUserId(userId).orElse(null);
        if (vipMember != null && vipMember.getExpireTime().before(new Date())) {
            vipMember.setStatus(0);
            vipMemberRepository.save(vipMember);

            User user = userRepository.findById(userId).get();
            user.setIsVip(false);
            user.setGroupLimit(10);
            user.setGroupMemberLimit(500);
            userRepository.save(user);
        }
    }

    @Transactional
    public void cancelVip(Long userId) {
        VipMember vipMember = getVipMemberByUserId(userId);
        vipMember.setStatus(0);
        vipMember.setUpdatedAt(new Date());
        vipMemberRepository.save(vipMember);

        User user = userRepository.findById(userId).get();
        user.setIsVip(false);
        user.setGroupLimit(10);
        user.setGroupMemberLimit(500);
        userRepository.save(user);
    }

    public long getTotalVipCount() {
        return vipMemberRepository.countByStatus(1);
    }

    public long getVipCountByLevel(Integer level) {
        return vipMemberRepository.countByVipLevel(level);
    }
}
