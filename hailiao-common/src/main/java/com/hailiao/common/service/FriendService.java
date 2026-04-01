package com.hailiao.common.service;

import com.hailiao.common.entity.Friend;
import com.hailiao.common.entity.FriendRequest;
import com.hailiao.common.entity.User;
import com.hailiao.common.repository.BlacklistRepository;
import com.hailiao.common.repository.FriendRepository;
import com.hailiao.common.repository.FriendRequestRepository;
import com.hailiao.common.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

@Service
public class FriendService {

    @Autowired
    private FriendRepository friendRepository;

    @Autowired
    private FriendRequestRepository friendRequestRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BlacklistRepository blacklistRepository;

    @Transactional
    public FriendRequest sendFriendRequest(Long userId, Long friendId, String remark, String message) {
        if (userId.equals(friendId)) {
            throw new RuntimeException("\u4e0d\u80fd\u6dfb\u52a0\u81ea\u5df1\u4e3a\u597d\u53cb");
        }

        if (isFriend(userId, friendId)) {
            throw new RuntimeException("\u4f60\u4eec\u5df2\u7ecf\u662f\u597d\u53cb\u4e86");
        }

        User friendUser = userRepository.findById(friendId)
                .orElseThrow(() -> new RuntimeException("\u7528\u6237\u4e0d\u5b58\u5728"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("\u7528\u6237\u4e0d\u5b58\u5728"));

        validateNotBlocked(userId, friendId);

        if (friendUser.getNeedFriendVerification() != null && !friendUser.getNeedFriendVerification()) {
            createFriendRelation(userId, friendId, remark);

            FriendRequest request = new FriendRequest();
            request.setFromUserId(userId);
            request.setToUserId(friendId);
            request.setRemark(remark != null ? remark : friendUser.getNickname());
            request.setMessage(message);
            request.setStatus(1);
            request.setHandledAt(new Date());
            request.setCreatedAt(new Date());
            request.setUpdatedAt(new Date());
            return friendRequestRepository.save(request);
        }

        long friendCount = friendRepository.countByUserIdAndStatus(userId, 1);
        if (friendCount >= user.getFriendLimit()) {
            throw new RuntimeException("\u597d\u53cb\u6570\u91cf\u5df2\u8fbe\u4e0a\u9650");
        }

        friendRequestRepository.findByFromUserIdAndToUserIdAndStatus(userId, friendId, 0)
                .ifPresent(request -> {
                    throw new RuntimeException("\u597d\u53cb\u7533\u8bf7\u5df2\u53d1\u9001\uff0c\u8bf7\u52ff\u91cd\u590d\u63d0\u4ea4");
                });

        FriendRequest reversePending = friendRequestRepository
                .findByFromUserIdAndToUserIdAndStatus(friendId, userId, 0)
                .orElse(null);
        if (reversePending != null) {
            acceptFriendRequest(reversePending.getId(), userId);
            reversePending.setRemark(remark != null ? remark : friendUser.getNickname());
            return reversePending;
        }

        FriendRequest request = new FriendRequest();
        request.setFromUserId(userId);
        request.setToUserId(friendId);
        request.setRemark(remark != null ? remark : friendUser.getNickname());
        request.setMessage(message);
        request.setStatus(0);
        request.setCreatedAt(new Date());
        request.setUpdatedAt(new Date());
        return friendRequestRepository.save(request);
    }

    public List<Friend> getFriendList(Long userId) {
        return friendRepository.findByUserIdAndStatus(userId, 1);
    }

    public Friend getFriend(Long userId, Long friendId) {
        return friendRepository.findByUserIdAndFriendId(userId, friendId)
                .orElseThrow(() -> new RuntimeException("\u597d\u53cb\u4e0d\u5b58\u5728"));
    }

    @Transactional
    public Friend updateFriendRemark(Long userId, Long friendId, String remark) {
        Friend friend = getFriend(userId, friendId);
        friend.setRemark(remark);
        friend.setUpdatedAt(new Date());
        return friendRepository.save(friend);
    }

    @Transactional
    public Friend moveToGroup(Long userId, Long friendId, String groupName) {
        Friend friend = getFriend(userId, friendId);
        friend.setGroupName(groupName);
        friend.setUpdatedAt(new Date());
        return friendRepository.save(friend);
    }

    @Transactional
    public void deleteFriend(Long userId, Long friendId) {
        Friend friend = friendRepository.findByUserIdAndFriendId(userId, friendId)
                .orElseThrow(() -> new RuntimeException("\u597d\u53cb\u4e0d\u5b58\u5728"));
        friend.setStatus(0);
        friend.setUpdatedAt(new Date());
        friendRepository.save(friend);

        Friend reverseFriend = friendRepository.findByUserIdAndFriendId(friendId, userId)
                .orElse(null);
        if (reverseFriend != null) {
            reverseFriend.setStatus(0);
            reverseFriend.setUpdatedAt(new Date());
            friendRepository.save(reverseFriend);
        }
    }

    public boolean isFriend(Long userId, Long friendId) {
        return friendRepository.findByUserIdAndFriendId(userId, friendId)
                .map(friend -> friend.getStatus() != null && friend.getStatus() == 1)
                .orElse(false);
    }

    public long getFriendCount(Long userId) {
        return friendRepository.countByUserIdAndStatus(userId, 1);
    }

    public List<FriendRequest> getReceivedFriendRequests(Long userId) {
        return friendRequestRepository.findByToUserIdAndStatusOrderByCreatedAtDesc(userId, 0);
    }

    public List<FriendRequest> getSentFriendRequests(Long userId) {
        return friendRequestRepository.findByFromUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional
    public FriendRequest acceptFriendRequest(Long requestId, Long userId) {
        FriendRequest request = getPendingRequest(requestId);
        if (!request.getToUserId().equals(userId)) {
            throw new RuntimeException("\u65e0\u6743\u5904\u7406\u8be5\u597d\u53cb\u7533\u8bf7");
        }

        validateNotBlocked(request.getFromUserId(), request.getToUserId());

        if (!isFriend(request.getFromUserId(), request.getToUserId())) {
            createFriendRelation(request.getFromUserId(), request.getToUserId(), request.getRemark());
        }

        request.setStatus(1);
        request.setHandledAt(new Date());
        request.setUpdatedAt(new Date());
        return friendRequestRepository.save(request);
    }

    @Transactional
    public FriendRequest rejectFriendRequest(Long requestId, Long userId) {
        FriendRequest request = getPendingRequest(requestId);
        if (!request.getToUserId().equals(userId)) {
            throw new RuntimeException("\u65e0\u6743\u5904\u7406\u8be5\u597d\u53cb\u7533\u8bf7");
        }
        request.setStatus(2);
        request.setHandledAt(new Date());
        request.setUpdatedAt(new Date());
        return friendRequestRepository.save(request);
    }

    private FriendRequest getPendingRequest(Long requestId) {
        FriendRequest request = friendRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("\u597d\u53cb\u7533\u8bf7\u4e0d\u5b58\u5728"));
        if (request.getStatus() == null || request.getStatus() != 0) {
            throw new RuntimeException("\u597d\u53cb\u7533\u8bf7\u5df2\u5904\u7406");
        }
        return request;
    }

    private void createFriendRelation(Long userId, Long friendId, String remark) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("\u7528\u6237\u4e0d\u5b58\u5728"));
        User friendUser = userRepository.findById(friendId)
                .orElseThrow(() -> new RuntimeException("\u7528\u6237\u4e0d\u5b58\u5728"));

        Friend friend = friendRepository.findByUserIdAndFriendId(userId, friendId).orElse(new Friend());
        friend.setUserId(userId);
        friend.setFriendId(friendId);
        friend.setRemark(remark != null ? remark : friendUser.getNickname());
        friend.setGroupName(friend.getGroupName() != null ? friend.getGroupName() : "\u6211\u7684\u597d\u53cb");
        friend.setStatus(1);
        friend.setCreatedAt(friend.getCreatedAt() != null ? friend.getCreatedAt() : new Date());
        friend.setUpdatedAt(new Date());

        Friend reverseFriend = friendRepository.findByUserIdAndFriendId(friendId, userId).orElse(new Friend());
        reverseFriend.setUserId(friendId);
        reverseFriend.setFriendId(userId);
        reverseFriend.setRemark(reverseFriend.getRemark() != null ? reverseFriend.getRemark() : user.getNickname());
        reverseFriend.setGroupName(reverseFriend.getGroupName() != null ? reverseFriend.getGroupName() : "\u6211\u7684\u597d\u53cb");
        reverseFriend.setStatus(1);
        reverseFriend.setCreatedAt(reverseFriend.getCreatedAt() != null ? reverseFriend.getCreatedAt() : new Date());
        reverseFriend.setUpdatedAt(new Date());

        friendRepository.save(friend);
        friendRepository.save(reverseFriend);
    }

    private void validateNotBlocked(Long userId, Long friendId) {
        if (blacklistRepository.existsByUserIdAndBlockedUserId(userId, friendId)) {
            throw new RuntimeException("\u4f60\u5df2\u5c06\u5bf9\u65b9\u52a0\u5165\u9ed1\u540d\u5355");
        }
        if (blacklistRepository.existsByUserIdAndBlockedUserId(friendId, userId)) {
            throw new RuntimeException("\u5bf9\u65b9\u5df2\u5c06\u4f60\u52a0\u5165\u9ed1\u540d\u5355");
        }
    }
}
