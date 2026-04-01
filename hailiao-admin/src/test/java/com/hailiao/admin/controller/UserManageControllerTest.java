package com.hailiao.admin.controller;

import com.hailiao.common.entity.User;
import com.hailiao.common.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
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
class UserManageControllerTest {

    @Mock
    private UserService userService;

    @InjectMocks
    private UserManageController userManageController;

    @Test
    void getUserListReturnsSummaryAndLabels() {
        User user = new User();
        user.setId(1L);
        user.setUserId("10001");
        user.setNickname("Alice");
        user.setStatus(0);
        user.setIsVip(true);
        user.setOnlineStatus(1);

        List<User> users = new ArrayList<User>();
        users.add(user);
        Page<User> page = new PageImpl<User>(users, PageRequest.of(0, 20), 1);
        when(userService.getUserList(null, 0, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending())))
                .thenReturn(page);

        ResponseEntity<?> actual = userManageController.getUserList(null, 0, 0, 20);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1L, summary.get("filteredTotal"));
        assertEquals(1L, summary.get("bannedCount"));
        assertEquals(1L, summary.get("vipCount"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("已封禁", first.get("statusLabel"));
        assertEquals("VIP", first.get("vipLabel"));
        assertEquals("在线", first.get("onlineStatusLabel"));
    }

    @Test
    void getUserStatsReturnsSummaryBlock() {
        when(userService.getTotalUserCount()).thenReturn(10L);
        when(userService.getActiveUserCount()).thenReturn(8L);

        ResponseEntity<?> actual = userManageController.getUserStats();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals(10L, body.get("totalUsers"));
        assertEquals(8L, body.get("activeUsers"));
        assertEquals(2L, body.get("inactiveUsers"));
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals("正常用户", summary.get("activeLabel"));
    }
}
