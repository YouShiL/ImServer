package com.hailiao.admin.controller;

import com.hailiao.common.entity.VipMember;
import com.hailiao.common.service.VipMemberService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VipManageControllerTest {

    @Mock
    private VipMemberService vipMemberService;

    @InjectMocks
    private VipManageController vipManageController;

    @Test
    void getVipListReturnsSummaryAndLabels() {
        VipMember vip = new VipMember();
        vip.setId(1L);
        vip.setUserId(100L);
        vip.setVipLevel(2);
        vip.setStatus(1);

        List<VipMember> vipList = new ArrayList<VipMember>();
        vipList.add(vip);
        when(vipMemberService.getAllVipMembers()).thenReturn(vipList);

        ResponseEntity<?> actual = vipManageController.getVipList();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1, summary.get("filteredTotal"));
        assertEquals(1L, summary.get("activeCount"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("VIP2", first.get("vipLevelLabel"));
        assertEquals("生效中", first.get("statusLabel"));
    }

    @Test
    void getVipStatsReturnsLevelBreakdown() {
        when(vipMemberService.getTotalVipCount()).thenReturn(6L);
        when(vipMemberService.getVipCountByLevel(1)).thenReturn(2L);
        when(vipMemberService.getVipCountByLevel(2)).thenReturn(3L);
        when(vipMemberService.getVipCountByLevel(3)).thenReturn(1L);

        ResponseEntity<?> actual = vipManageController.getVipStats();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals(6L, body.get("totalVips"));
        Map<?, ?> levelStats = assertInstanceOf(Map.class, body.get("levelStats"));
        Map<?, ?> vip2 = assertInstanceOf(Map.class, levelStats.get("2"));
        assertEquals("VIP2", vip2.get("vipLevelLabel"));
        assertEquals(3L, vip2.get("count"));
        verify(vipMemberService).getVipCountByLevel(3);
    }
}
