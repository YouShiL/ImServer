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
            throw new RuntimeException("不能添加自己为好友");
        }

        if (isFriend(userId, friendId)) {
            throw new RuntimeException("你们已经是好友了");
        }

        User friendUser = userRepository.findById(friendId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));

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
            throw new RuntimeException("好友数量已达上限");
        }

        friendRequestRepository.findByFromUserIdAndToUserIdAndStatus(userId, friendId, 0)
                .ifPresent(request -> {
                    throw new RuntimeException("好友申请已发送，请勿重复提交");
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
                .orElseThrow(() -> new RuntimeException("好友不存在"));
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
                .orElseThrow(() -> new RuntimeException("好友不存在"));
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
            throw new RuntimeException("无权处理该好友申请");
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
            throw new RuntimeException("无权处理该好友申请");
        }
        request.setStatus(2);
        request.setHandledAt(new Date());
        request.setUpdatedAt(new Date());
        return friendRequestRepository.save(request);
    }

    private FriendRequest getPendingRequest(Long requestId) {
        FriendRequest request = friendRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("好友申请不存在"));
        if (request.getStatus() == null || request.getStatus() != 0) {
            throw new RuntimeException("好友申请已处理");
        }
        return request;
    }

    private void createFriendRelation(Long userId, Long friendId, String remark) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
        User friendUser = userRepository.findById(friendId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        Friend friend = friendRepository.findByUserIdAndFriendId(userId, friendId).orElse(new Friend());
        friend.setUserId(userId);
        friend.setFriendId(friendId);
        friend.setRemark(remark != null ? remark : friendUser.getNickname());
        friend.setGroupName(friend.getGroupName() != null ? friend.getGroupName() : "我的好友");
        friend.setStatus(1);
        friend.setCreatedAt(friend.getCreatedAt() != null ? friend.getCreatedAt() : new Date());
        friend.setUpdatedAt(new Date());

        Friend reverseFriend = friendRepository.findByUserIdAndFriendId(friendId, userId).orElse(new Friend());
        reverseFriend.setUserId(friendId);
        reverseFriend.setFriendId(userId);
        reverseFriend.setRemark(reverseFriend.getRemark() != null ? reverseFriend.getRemark() : user.getNickname());
        reverseFriend.setGroupName(reverseFriend.getGroupName() != null ? reverseFriend.getGroupName() : "我的好友");
        reverseFriend.setStatus(1);
        reverseFriend.setCreatedAt(reverseFriend.getCreatedAt() != null ? reverseFriend.getCreatedAt() : new Date());
        reverseFriend.setUpdatedAt(new Date());

        friendRepository.save(friend);
        friendRepository.save(reverseFriend);
    }

    private void validateNotBlocked(Long userId, Long friendId) {
        if (blacklistRepository.existsByUserIdAndBlockedUserId(userId, friendId)) {
            throw new RuntimeException("你已将对方加入黑名单");
        }
        if (blacklistRepository.existsByUserIdAndBlockedUserId(friendId, userId)) {
            throw new RuntimeException("对方已将你加入黑名单");
        }
    }
}
