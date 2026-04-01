package com.hailiao.common.service;

import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupMember;
import com.hailiao.common.entity.User;
import com.hailiao.common.repository.GroupChatRepository;
import com.hailiao.common.repository.GroupMemberRepository;
import com.hailiao.common.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.Collections;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupChatServiceTest {

    @Mock
    private GroupChatRepository groupChatRepository;

    @Mock
    private GroupMemberRepository groupMemberRepository;

    @Mock
    private UserRepository userRepository;

    @Spy
    @InjectMocks
    private GroupChatService groupChatService;

    @Test
    void createGroupShouldRejectWhenOwnerReachedLimit() {
        User owner = new User();
        owner.setId(1L);
        owner.setGroupLimit(1);

        when(userRepository.findById(1L)).thenReturn(Optional.of(owner));
        when(groupMemberRepository.countByUserId(1L)).thenReturn(1L);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        groupChatService.createGroup(1L, "Test Group", "desc", Collections.<Long>emptyList());
                    }
                });

        assertEquals("\u521b\u5efa\u7fa4\u7ec4\u6570\u91cf\u5df2\u8fbe\u4e0a\u9650", error.getMessage());
    }

    @Test
    void createGroupShouldCreateOwnerMembershipAndDefaults() {
        User owner = new User();
        owner.setId(1L);
        owner.setNickname("owner");
        owner.setGroupLimit(10);
        owner.setGroupMemberLimit(500);

        when(userRepository.findById(1L)).thenReturn(Optional.of(owner));
        when(groupMemberRepository.countByUserId(1L)).thenReturn(0L);
        when(groupChatRepository.existsByGroupId(any(String.class))).thenReturn(false);
        when(groupChatRepository.save(any(GroupChat.class))).thenAnswer(new org.mockito.stubbing.Answer<GroupChat>() {
            @Override
            public GroupChat answer(org.mockito.invocation.InvocationOnMock invocation) {
                GroupChat group = (GroupChat) invocation.getArgument(0);
                if (group.getId() == null) {
                    group.setId(10L);
                }
                return group;
            }
        });
        when(groupMemberRepository.save(any(GroupMember.class))).thenAnswer(new org.mockito.stubbing.Answer<GroupMember>() {
            @Override
            public GroupMember answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (GroupMember) invocation.getArgument(0);
            }
        });

        GroupChat group = groupChatService.createGroup(1L, "Test Group", "desc", Arrays.asList(1L));

        assertEquals(Long.valueOf(10L), group.getId());
        assertEquals("Test Group", group.getGroupName());
        assertEquals(Long.valueOf(1L), group.getOwnerId());
        assertEquals(Integer.valueOf(1), group.getMemberCount());
        assertEquals(Integer.valueOf(500), group.getMaxMemberCount());
        assertTrue(group.getAllowMemberInvite());
        assertEquals(Integer.valueOf(0), group.getJoinType());
        assertNotNull(group.getGroupId());

        ArgumentCaptor<GroupMember> memberCaptor = ArgumentCaptor.forClass(GroupMember.class);
        verify(groupMemberRepository).save(memberCaptor.capture());
        assertEquals(Long.valueOf(10L), memberCaptor.getValue().getGroupId());
        assertEquals(Long.valueOf(1L), memberCaptor.getValue().getUserId());
        assertEquals(Integer.valueOf(1), memberCaptor.getValue().getRole());
    }

    @Test
    void addGroupMemberShouldRejectWhenNormalMemberCannotInvite() {
        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setAllowMemberInvite(false);

        GroupMember operator = new GroupMember();
        operator.setGroupId(10L);
        operator.setUserId(5L);
        operator.setRole(3);

        doReturn(group).when(groupChatService).getGroupById(10L);
        when(groupMemberRepository.findByGroupIdAndUserId(10L, 5L)).thenReturn(Optional.of(operator));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        groupChatService.addGroupMember(10L, 2L, 3, 5L);
                    }
                });

        assertEquals("\u5f53\u524d\u7fa4\u7ec4\u4e0d\u5141\u8bb8\u666e\u901a\u6210\u5458\u9080\u8bf7\u65b0\u6210\u5458", error.getMessage());
    }

    @Test
    void addGroupMemberShouldUpdateMemberCount() {
        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setAllowMemberInvite(true);
        group.setMaxMemberCount(200);

        User user = new User();
        user.setId(2L);
        user.setNickname("member");

        doReturn(group).when(groupChatService).getGroupById(10L);
        when(groupMemberRepository.existsByGroupIdAndUserId(10L, 2L)).thenReturn(false);
        when(groupMemberRepository.countByGroupId(10L)).thenReturn(1L);
        when(userRepository.findById(2L)).thenReturn(Optional.of(user));
        when(groupChatRepository.save(any(GroupChat.class))).thenAnswer(new org.mockito.stubbing.Answer<GroupChat>() {
            @Override
            public GroupChat answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (GroupChat) invocation.getArgument(0);
            }
        });
        when(groupMemberRepository.save(any(GroupMember.class))).thenAnswer(new org.mockito.stubbing.Answer<GroupMember>() {
            @Override
            public GroupMember answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (GroupMember) invocation.getArgument(0);
            }
        });

        GroupMember member = groupChatService.addGroupMember(10L, 2L, 3);

        assertEquals(Long.valueOf(2L), member.getUserId());
        assertEquals(Integer.valueOf(2), group.getMemberCount());
        assertFalse(member.getIsMute());
    }

    @Test
    void quitGroupShouldRejectOwnerQuit() {
        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setOwnerId(1L);

        doReturn(group).when(groupChatService).getGroupById(10L);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        groupChatService.quitGroup(10L, 1L);
                    }
                });

        assertEquals("\u7fa4\u4e3b\u4e0d\u80fd\u9000\u51fa\u7fa4\u7ec4", error.getMessage());
    }

    @Test
    void transferGroupOwnerShouldSwapRoles() {
        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setOwnerId(1L);

        GroupMember oldOwner = new GroupMember();
        oldOwner.setGroupId(10L);
        oldOwner.setUserId(1L);
        oldOwner.setRole(1);

        GroupMember newOwner = new GroupMember();
        newOwner.setGroupId(10L);
        newOwner.setUserId(2L);
        newOwner.setRole(3);

        doReturn(group).when(groupChatService).getGroupById(10L);
        when(groupMemberRepository.findByGroupIdAndUserId(10L, 2L)).thenReturn(Optional.of(newOwner));
        when(groupMemberRepository.findByGroupIdAndUserId(10L, 1L)).thenReturn(Optional.of(oldOwner));

        groupChatService.transferGroupOwner(10L, 2L);

        assertEquals(Long.valueOf(2L), group.getOwnerId());
        assertEquals(Integer.valueOf(3), oldOwner.getRole());
        assertEquals(Integer.valueOf(1), newOwner.getRole());
        verify(groupMemberRepository, times(2)).save(any(GroupMember.class));
        verify(groupChatRepository).save(group);
    }

    @Test
    void updateGroupInfoShouldOnlyApplyProvidedFields() {
        GroupChat group = new GroupChat();
        group.setId(10L);
        group.setGroupName("old");
        group.setDescription("old-desc");
        group.setNotice("old-notice");
        group.setAvatar("old.png");
        group.setAllowMemberInvite(true);
        group.setJoinType(0);

        doReturn(group).when(groupChatService).getGroupById(10L);
        when(groupChatRepository.save(any(GroupChat.class))).thenAnswer(new org.mockito.stubbing.Answer<GroupChat>() {
            @Override
            public GroupChat answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (GroupChat) invocation.getArgument(0);
            }
        });

        GroupChat saved = groupChatService.updateGroupInfo(10L, "new", null, "notice", null, false, 1);

        assertEquals("new", saved.getGroupName());
        assertEquals("old-desc", saved.getDescription());
        assertEquals("notice", saved.getNotice());
        assertEquals("old.png", saved.getAvatar());
        assertFalse(saved.getAllowMemberInvite());
        assertEquals(Integer.valueOf(1), saved.getJoinType());
        assertNotNull(saved.getUpdatedAt());
    }
}
