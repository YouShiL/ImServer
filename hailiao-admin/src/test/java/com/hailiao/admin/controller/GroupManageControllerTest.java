package com.hailiao.admin.controller;

import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.service.GroupChatService;
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
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupManageControllerTest {

    @Mock
    private GroupChatService groupChatService;

    @InjectMocks
    private GroupManageController groupManageController;

    @Test
    void getGroupListReturnsSummaryAndLabels() {
        GroupChat group = new GroupChat();
        group.setId(1L);
        group.setGroupId("10001");
        group.setGroupName("运营群");
        group.setStatus(1);
        group.setIsMute(true);
        group.setMuteAll(false);
        group.setAllowMemberInvite(false);
        group.setJoinType(2);

        List<GroupChat> groups = new ArrayList<GroupChat>();
        groups.add(group);
        Page<GroupChat> page = new PageImpl<GroupChat>(groups, PageRequest.of(0, 20), 1);
        when(groupChatService.getGroupList(null, 1, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending())))
                .thenReturn(page);

        ResponseEntity<?> actual = groupManageController.getGroupList(null, 1, 0, 20);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1L, summary.get("filteredTotal"));
        assertEquals(1L, summary.get("mutedGroups"));
        assertEquals(1L, summary.get("verifyJoinGroups"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("正常", first.get("statusLabel"));
        assertEquals("仅管理员可邀请", first.get("allowMemberInviteLabel"));
        assertEquals("需要验证", first.get("joinTypeLabel"));
        assertEquals("已禁言", first.get("muteLabel"));
        verify(groupChatService).getGroupList(null, 1, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending()));
    }

    @Test
    void updateGroupPassesExtendedFieldsToService() {
        GroupChat request = new GroupChat();
        request.setGroupName("新群名");
        request.setDescription("简介");
        request.setNotice("公告");
        request.setAvatar("avatar.png");
        request.setAllowMemberInvite(true);
        request.setJoinType(1);

        GroupChat updated = new GroupChat();
        updated.setId(9L);

        when(groupChatService.updateGroupInfo(9L, "新群名", "简介", "公告", "avatar.png", true, 1)).thenReturn(updated);

        ResponseEntity<?> actual = groupManageController.updateGroup(9L, request);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertTrue(actual.getBody() instanceof GroupChat);
        verify(groupChatService).updateGroupInfo(9L, "新群名", "简介", "公告", "avatar.png", true, 1);
    }
}
