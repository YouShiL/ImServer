package com.hailiao.api.controller;

import com.hailiao.api.dto.GroupDTO;
import com.hailiao.api.dto.GroupMemberDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupMember;
import com.hailiao.common.service.GroupChatService;
import com.hailiao.common.service.GroupMemberService;
import com.hailiao.common.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupControllerTest {

    @Mock
    private GroupChatService groupChatService;

    @Mock
    private UserService userService;

    @Mock
    private GroupMemberService groupMemberService;

    @InjectMocks
    private GroupController groupController;

    @Test
    void createGroupShouldReturnConvertedGroupDto() {
        GroupChat group = buildGroup(10L, "G100000001", "测试群");
        when(groupChatService.createGroup(1L, "测试群", "描述", buildMemberIds())).thenReturn(group);

        Map<String, Object> request = new HashMap<String, Object>();
        request.put("groupName", "测试群");
        request.put("description", "描述");
        request.put("memberIds", buildMemberIds());

        ResponseEntity<ResponseDTO<GroupDTO>> response = groupController.createGroup(1L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("G100000001", response.getBody().getData().getGroupId());
        assertEquals("测试群", response.getBody().getData().getGroupName());
    }

    @Test
    void getMyGroupsShouldReturnConvertedDtos() {
        List<GroupChat> groups = new ArrayList<GroupChat>();
        groups.add(buildGroup(10L, "G100000001", "群一"));
        groups.add(buildGroup(11L, "G100000002", "群二"));
        when(groupChatService.getUserGroupChats(1L)).thenReturn(groups);

        ResponseEntity<ResponseDTO<List<GroupDTO>>> response = groupController.getMyGroups(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(2, response.getBody().getData().size());
        assertEquals("群一", response.getBody().getData().get(0).getGroupName());
    }

    @Test
    void updateGroupInfoShouldPassExtendedFields() {
        GroupChat updated = buildGroup(10L, "G100000001", "新群名");
        updated.setAllowMemberInvite(false);
        updated.setJoinType(1);

        when(groupChatService.updateGroupInfo(10L, "新群名", "新描述", "新公告", "avatar.png", false, 1))
                .thenReturn(updated);

        Map<String, String> request = new HashMap<String, String>();
        request.put("groupName", "新群名");
        request.put("description", "新描述");
        request.put("notice", "新公告");
        request.put("avatar", "avatar.png");
        request.put("allowMemberInvite", "false");
        request.put("joinType", "1");

        ResponseEntity<ResponseDTO<GroupDTO>> response = groupController.updateGroupInfo(1L, 10L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertFalse(response.getBody().getData().getAllowMemberInvite());
        assertEquals(Integer.valueOf(1), response.getBody().getData().getJoinType());
    }

    @Test
    void setGroupMuteShouldDelegateToService() {
        Map<String, Boolean> request = new HashMap<String, Boolean>();
        request.put("isMute", true);

        ResponseEntity<ResponseDTO<String>> response = groupController.setGroupMute(1L, 10L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(groupChatService).setGroupMute(10L, true);
    }

    @Test
    void addMemberShouldReturnBadRequestWhenInviteNotAllowed() {
        when(groupMemberService.canInviteMembers(10L, 1L)).thenReturn(false);

        Map<String, Object> request = new HashMap<String, Object>();
        request.put("memberId", 2L);
        request.put("role", 3);

        ResponseEntity<ResponseDTO<GroupMemberDTO>> response = groupController.addMember(1L, 10L, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(400, response.getBody().getCode());
    }

    @Test
    void addMemberShouldReturnMemberDtoWhenAllowed() {
        GroupMember member = new GroupMember();
        member.setId(100L);
        member.setGroupId(10L);
        member.setUserId(2L);
        member.setRole(3);
        member.setIsMute(false);

        when(groupMemberService.canInviteMembers(10L, 1L)).thenReturn(true);
        when(groupChatService.addGroupMember(10L, 2L, 3, 1L)).thenReturn(member);

        Map<String, Object> request = new HashMap<String, Object>();
        request.put("memberId", 2L);
        request.put("role", 3);

        ResponseEntity<ResponseDTO<GroupMemberDTO>> response = groupController.addMember(1L, 10L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(Long.valueOf(2L), response.getBody().getData().getUserId());
        assertTrue(response.getBody().getData().getRole() == 3);
    }

    private List<Long> buildMemberIds() {
        List<Long> memberIds = new ArrayList<Long>();
        memberIds.add(2L);
        memberIds.add(3L);
        return memberIds;
    }

    private GroupChat buildGroup(Long id, String groupId, String groupName) {
        GroupChat group = new GroupChat();
        group.setId(id);
        group.setGroupId(groupId);
        group.setGroupName(groupName);
        group.setDescription("描述");
        group.setNotice("公告");
        group.setAvatar("avatar.png");
        group.setOwnerId(1L);
        group.setMemberCount(3);
        group.setMaxMemberCount(200);
        group.setAllowMemberInvite(true);
        group.setJoinType(0);
        group.setIsMute(false);
        group.setStatus(1);
        return group;
    }
}
