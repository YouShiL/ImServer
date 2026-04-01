package com.hailiao.common.service;

import com.hailiao.common.entity.Friend;
import com.hailiao.common.entity.FriendRequest;
import com.hailiao.common.entity.User;
import com.hailiao.common.repository.BlacklistRepository;
import com.hailiao.common.repository.FriendRepository;
import com.hailiao.common.repository.FriendRequestRepository;
import com.hailiao.common.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Date;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FriendServiceTest {

    @Mock
    private FriendRepository friendRepository;

    @Mock
    private FriendRequestRepository friendRequestRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private BlacklistRepository blacklistRepository;

    @InjectMocks
    private FriendService friendService;

    @Test
    void sendFriendRequestShouldRejectSelf() {
        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        friendService.sendFriendRequest(1L, 1L, null, null);
                    }
                });

        assertEquals("不能添加自己为好友", error.getMessage());
    }

    @Test
    void sendFriendRequestShouldCreatePendingRequestWhenVerificationNeeded() {
        User requester = buildUser(1L, "请求者", true, 500);
        User target = buildUser(2L, "目标用户", true, 500);

        when(friendRepository.findByUserIdAndFriendId(1L, 2L)).thenReturn(Optional.<Friend>empty());
        when(userRepository.findById(1L)).thenReturn(Optional.of(requester));
        when(userRepository.findById(2L)).thenReturn(Optional.of(target));
        when(blacklistRepository.existsByUserIdAndBlockedUserId(1L, 2L)).thenReturn(false);
        when(blacklistRepository.existsByUserIdAndBlockedUserId(2L, 1L)).thenReturn(false);
        when(friendRepository.countByUserIdAndStatus(1L, 1)).thenReturn(0L);
        when(friendRequestRepository.findByFromUserIdAndToUserIdAndStatus(1L, 2L, 0))
                .thenReturn(Optional.<FriendRequest>empty());
        when(friendRequestRepository.findByFromUserIdAndToUserIdAndStatus(2L, 1L, 0))
                .thenReturn(Optional.<FriendRequest>empty());
        when(friendRequestRepository.save(any(FriendRequest.class))).thenAnswer(new org.mockito.stubbing.Answer<FriendRequest>() {
            @Override
            public FriendRequest answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (FriendRequest) invocation.getArgument(0);
            }
        });

        FriendRequest request = friendService.sendFriendRequest(1L, 2L, "备注", "你好");

        assertEquals(Integer.valueOf(0), request.getStatus());
        assertEquals("备注", request.getRemark());
        assertEquals("你好", request.getMessage());
        assertNotNull(request.getCreatedAt());
    }

    @Test
    void sendFriendRequestShouldAutoCreateFriendWhenVerificationDisabled() {
        User requester = buildUser(1L, "请求者", true, 500);
        User target = buildUser(2L, "目标用户", false, 500);

        when(friendRepository.findByUserIdAndFriendId(1L, 2L)).thenReturn(Optional.<Friend>empty());
        when(friendRepository.findByUserIdAndFriendId(2L, 1L)).thenReturn(Optional.<Friend>empty());
        when(userRepository.findById(1L)).thenReturn(Optional.of(requester));
        when(userRepository.findById(2L)).thenReturn(Optional.of(target));
        when(blacklistRepository.existsByUserIdAndBlockedUserId(1L, 2L)).thenReturn(false);
        when(blacklistRepository.existsByUserIdAndBlockedUserId(2L, 1L)).thenReturn(false);
        when(friendRepository.save(any(Friend.class))).thenAnswer(new org.mockito.stubbing.Answer<Friend>() {
            @Override
            public Friend answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (Friend) invocation.getArgument(0);
            }
        });
        when(friendRequestRepository.save(any(FriendRequest.class))).thenAnswer(new org.mockito.stubbing.Answer<FriendRequest>() {
            @Override
            public FriendRequest answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (FriendRequest) invocation.getArgument(0);
            }
        });

        FriendRequest request = friendService.sendFriendRequest(1L, 2L, null, "你好");

        assertEquals(Integer.valueOf(1), request.getStatus());
        verify(friendRepository, times(2)).save(any(Friend.class));
    }

    @Test
    void acceptFriendRequestShouldCreateFriendRelationAndUpdateStatus() {
        FriendRequest request = new FriendRequest();
        request.setId(1L);
        request.setFromUserId(2L);
        request.setToUserId(1L);
        request.setStatus(0);
        request.setRemark("同学");

        User requester = buildUser(2L, "请求者", true, 500);
        User target = buildUser(1L, "目标用户", true, 500);

        when(friendRequestRepository.findById(1L)).thenReturn(Optional.of(request));
        when(blacklistRepository.existsByUserIdAndBlockedUserId(2L, 1L)).thenReturn(false);
        when(blacklistRepository.existsByUserIdAndBlockedUserId(1L, 2L)).thenReturn(false);
        when(friendRepository.findByUserIdAndFriendId(2L, 1L)).thenReturn(Optional.<Friend>empty());
        when(friendRepository.findByUserIdAndFriendId(1L, 2L)).thenReturn(Optional.<Friend>empty());
        when(userRepository.findById(1L)).thenReturn(Optional.of(target));
        when(userRepository.findById(2L)).thenReturn(Optional.of(requester));
        when(friendRepository.save(any(Friend.class))).thenAnswer(new org.mockito.stubbing.Answer<Friend>() {
            @Override
            public Friend answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (Friend) invocation.getArgument(0);
            }
        });
        when(friendRequestRepository.save(any(FriendRequest.class))).thenAnswer(new org.mockito.stubbing.Answer<FriendRequest>() {
            @Override
            public FriendRequest answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (FriendRequest) invocation.getArgument(0);
            }
        });

        FriendRequest saved = friendService.acceptFriendRequest(1L, 1L);

        assertEquals(Integer.valueOf(1), saved.getStatus());
        assertNotNull(saved.getHandledAt());
        verify(friendRepository, times(2)).save(any(Friend.class));
    }

    @Test
    void rejectFriendRequestShouldSetRejectedStatus() {
        FriendRequest request = new FriendRequest();
        request.setId(1L);
        request.setFromUserId(2L);
        request.setToUserId(1L);
        request.setStatus(0);

        when(friendRequestRepository.findById(1L)).thenReturn(Optional.of(request));
        when(friendRequestRepository.save(any(FriendRequest.class))).thenAnswer(new org.mockito.stubbing.Answer<FriendRequest>() {
            @Override
            public FriendRequest answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (FriendRequest) invocation.getArgument(0);
            }
        });

        FriendRequest saved = friendService.rejectFriendRequest(1L, 1L);

        assertEquals(Integer.valueOf(2), saved.getStatus());
        assertNotNull(saved.getHandledAt());
    }

    private User buildUser(Long id, String nickname, boolean needVerification, int friendLimit) {
        User user = new User();
        user.setId(id);
        user.setNickname(nickname);
        user.setNeedFriendVerification(needVerification);
        user.setFriendLimit(friendLimit);
        return user;
    }
}
