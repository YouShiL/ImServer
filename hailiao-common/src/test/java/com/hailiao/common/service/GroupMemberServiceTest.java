package com.hailiao.common.service;

import com.hailiao.common.entity.GroupChat;
import com.hailiao.common.entity.GroupMember;
import com.hailiao.common.repository.GroupChatRepository;
import com.hailiao.common.repository.GroupMemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Date;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GroupMemberServiceTest {

    @Mock
    private GroupMemberRepository groupMemberRepository;

    @Mock
    private GroupChatRepository groupChatRepository;

    @InjectMocks
    private GroupMemberService groupMemberService;

    @Test
    void canInviteMembersShouldAllowOwnerAndAdmin() {
        GroupMember owner = buildMember(10L, 1L, GroupMemberService.ROLE_OWNER);
        when(groupMemberRepository.findByGroupIdAndUserId(10L, 1L)).thenReturn(Optional.of(owner));

        boolean result = groupMemberService.canInviteMembers(10L, 1L);

        assertTrue(result);
    }

    @Test
    void canInviteMembersShouldRespectGroupSettingForNormalMember() {
        GroupMember member = buildMember(10L, 2L, GroupMemberService.ROLE_MEMBER);
        GroupChat group = buildGroup(10L, 1L, 10, 200);
        group.setAllowMemberInvite(false);

        when(groupMemberRepository.findByGroupIdAndUserId(10L, 2L)).thenReturn(Optional.of(member));
        when(groupChatRepository.findById(10L)).thenReturn(Optional.of(group));

        boolean result = groupMemberService.canInviteMembers(10L, 2L);

        assertFalse(result);
    }

    @Test
    void muteAllShouldRejectNonAdmin() {
        GroupMember member = buildMember(10L, 2L, GroupMemberService.ROLE_MEMBER);
        when(groupMemberRepository.findByGroupIdAndUserId(10L, 2L)).thenReturn(Optional.of(member));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        groupMemberService.muteAll(10L, 2L, true);
                    }
                });

        assertEquals("只有管理员可以修改全员禁言", error.getMessage());
    }

    @Test
    void muteAllShouldUpdateGroupFlag() {
        GroupMember admin = buildMember(10L, 1L, GroupMemberService.ROLE_ADMIN);
        GroupChat group = buildGroup(10L, 9L, 10, 200);

        when(groupMemberRepository.findByGroupIdAndUserId(10L, 1L)).thenReturn(Optional.of(admin));
        when(groupChatRepository.findById(10L)).thenReturn(Optional.of(group));

        groupMemberService.muteAll(10L, 1L, true);

        assertTrue(group.getMuteAll());
        verify(groupChatRepository).save(group);
    }

    @Test
    void canSendGroupMessageShouldAllowAdminWhenMuteAllEnabled() {
        GroupChat group = buildGroup(10L, 1L, 10, 200);
        group.setMuteAll(true);
        GroupMember admin = buildMember(10L, 1L, GroupMemberService.ROLE_ADMIN);

        when(groupChatRepository.findById(10L)).thenReturn(Optional.of(group));
        when(groupMemberRepository.findByGroupIdAndUserId(10L, 1L)).thenReturn(Optional.of(admin));

        boolean result = groupMemberService.canSendGroupMessage(10L, 1L);

        assertTrue(result);
    }

    @Test
    void canSendGroupMessageShouldAutoRestoreExpiredMute() {
        GroupChat group = buildGroup(10L, 1L, 10, 200);
        group.setMuteAll(false);
        GroupMember member = buildMember(10L, 2L, GroupMemberService.ROLE_MEMBER);
        member.setIsMute(true);
        member.setMuteUntil(new Date(System.currentTimeMillis() - 60_000));

        when(groupChatRepository.findById(10L)).thenReturn(Optional.of(group));
        when(groupMemberRepository.findByGroupIdAndUserId(10L, 2L)).thenReturn(Optional.of(member));

        boolean result = groupMemberService.canSendGroupMessage(10L, 2L);

        assertTrue(result);
        assertFalse(member.getIsMute());
        verify(groupMemberRepository).save(member);
    }

    @Test
    void joinGroupShouldRejectWhenAlreadyMember() {
        when(groupMemberRepository.existsByGroupIdAndUserId(10L, 2L)).thenReturn(true);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        groupMemberService.joinGroup(10L, 2L);
                    }
                });

        assertEquals("你已是群成员", error.getMessage());
    }

    @Test
    void joinGroupShouldCreateMemberAndIncreaseCount() {
        GroupChat group = buildGroup(10L, 1L, 10, 200);

        when(groupMemberRepository.existsByGroupIdAndUserId(10L, 2L)).thenReturn(false);
        when(groupChatRepository.findById(10L)).thenReturn(Optional.of(group));
        when(groupMemberRepository.save(any(GroupMember.class))).thenAnswer(new org.mockito.stubbing.Answer<GroupMember>() {
            @Override
            public GroupMember answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (GroupMember) invocation.getArgument(0);
            }
        });

        groupMemberService.joinGroup(10L, 2L);

        assertEquals(Integer.valueOf(11), group.getMemberCount());
        verify(groupMemberRepository).save(any(GroupMember.class));
        verify(groupChatRepository).save(group);
    }

    private GroupMember buildMember(Long groupId, Long userId, Integer role) {
        GroupMember member = new GroupMember();
        member.setGroupId(groupId);
        member.setUserId(userId);
        member.setRole(role);
        member.setIsMute(false);
        return member;
    }

    private GroupChat buildGroup(Long id, Long ownerId, Integer memberCount, Integer maxMemberCount) {
        GroupChat group = new GroupChat();
        group.setId(id);
        group.setOwnerId(ownerId);
        group.setMemberCount(memberCount);
        group.setMaxMemberCount(maxMemberCount);
        group.setMuteAll(false);
        group.setAllowMemberInvite(true);
        return group;
    }
}
