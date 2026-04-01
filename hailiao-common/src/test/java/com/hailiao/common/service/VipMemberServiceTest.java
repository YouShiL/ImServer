package com.hailiao.common.service;

import com.hailiao.common.entity.User;
import com.hailiao.common.entity.VipMember;
import com.hailiao.common.repository.UserRepository;
import com.hailiao.common.repository.VipMemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Calendar;
import java.util.Date;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VipMemberServiceTest {

    @Mock
    private VipMemberRepository vipMemberRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private VipMemberService vipMemberService;

    @Test
    void createVipMemberShouldUpgradeUserLimits() {
        User user = new User();
        user.setId(1L);
        user.setIsVip(false);

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(vipMemberRepository.findByUserId(1L)).thenReturn(Optional.<VipMember>empty());
        when(vipMemberRepository.save(any(VipMember.class))).thenAnswer(new org.mockito.stubbing.Answer<VipMember>() {
            @Override
            public VipMember answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (VipMember) invocation.getArgument(0);
            }
        });

        VipMember vipMember = vipMemberService.createVipMember(1L, 2, 3);

        assertEquals(Integer.valueOf(2), vipMember.getVipLevel());
        assertEquals(Integer.valueOf(1), vipMember.getStatus());
        assertNotNull(vipMember.getStartTime());
        assertNotNull(vipMember.getExpireTime());
        assertTrue(user.getIsVip());
        assertEquals(Integer.valueOf(999), user.getGroupLimit());
        assertEquals(Integer.valueOf(5000), user.getGroupMemberLimit());
    }

    @Test
    void isVipShouldReturnFalseWhenExpired() {
        VipMember vipMember = new VipMember();
        vipMember.setStatus(1);
        vipMember.setExpireTime(new Date(System.currentTimeMillis() - 1000));

        when(vipMemberRepository.findByUserId(1L)).thenReturn(Optional.of(vipMember));

        assertFalse(vipMemberService.isVip(1L));
    }

    @Test
    void checkAndUpdateVipStatusShouldDowngradeExpiredUser() {
        VipMember vipMember = new VipMember();
        vipMember.setUserId(1L);
        vipMember.setStatus(1);
        vipMember.setExpireTime(new Date(System.currentTimeMillis() - 1000));

        User user = new User();
        user.setId(1L);
        user.setIsVip(true);

        when(vipMemberRepository.findByUserId(1L)).thenReturn(Optional.of(vipMember));
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        vipMemberService.checkAndUpdateVipStatus(1L);

        assertEquals(Integer.valueOf(0), vipMember.getStatus());
        assertFalse(user.getIsVip());
        assertEquals(Integer.valueOf(10), user.getGroupLimit());
        assertEquals(Integer.valueOf(500), user.getGroupMemberLimit());
        verify(vipMemberRepository).save(vipMember);
        verify(userRepository).save(user);
    }

    @Test
    void createVipMemberShouldExtendFromExistingExpireTime() {
        User user = new User();
        user.setId(1L);

        VipMember vipMember = new VipMember();
        vipMember.setId(2L);
        Calendar calendar = Calendar.getInstance();
        calendar.add(Calendar.MONTH, 1);
        Date oldExpireTime = calendar.getTime();
        vipMember.setExpireTime(oldExpireTime);

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(vipMemberRepository.findByUserId(1L)).thenReturn(Optional.of(vipMember));
        when(vipMemberRepository.save(any(VipMember.class))).thenAnswer(new org.mockito.stubbing.Answer<VipMember>() {
            @Override
            public VipMember answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (VipMember) invocation.getArgument(0);
            }
        });

        VipMember saved = vipMemberService.createVipMember(1L, 1, 2);

        assertTrue(saved.getExpireTime().after(oldExpireTime));
    }
}
