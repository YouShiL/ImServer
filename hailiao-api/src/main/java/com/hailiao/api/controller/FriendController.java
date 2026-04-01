package com.hailiao.api.controller;

import com.hailiao.api.dto.FriendDTO;
import com.hailiao.api.dto.FriendRequestDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.UserDTO;
import com.hailiao.common.entity.Friend;
import com.hailiao.common.entity.FriendRequest;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.FriendService;
import com.hailiao.common.service.UserService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Tag(name = "Friend")
@RestController
@RequestMapping("/api/friend")
public class FriendController {

    @Autowired
    private FriendService friendService;

    @Autowired
    private UserService userService;

    @PostMapping("/add")
    public ResponseEntity<ResponseDTO<String>> addFriend(@RequestAttribute("userId") Long userId,
                                                         @RequestBody Map<String, Object> request) {
        try {
            Long friendId = Long.valueOf(request.get("friendId").toString());
            String remark = (String) request.get("remark");
            String message = (String) request.get("message");
            FriendRequest friendRequest = friendService.sendFriendRequest(userId, friendId, remark, message);
            String resultMessage = friendRequest.getStatus() != null && friendRequest.getStatus() == 1
                    ? "\u5df2\u81ea\u52a8\u6dfb\u52a0\u4e3a\u597d\u53cb"
                    : "\u597d\u53cb\u7533\u8bf7\u5df2\u53d1\u9001";
            return ResponseEntity.ok(ResponseDTO.success(resultMessage));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/request/received")
    public ResponseEntity<ResponseDTO<List<FriendRequestDTO>>> getReceivedRequests(@RequestAttribute("userId") Long userId) {
        try {
            List<FriendRequest> requests = friendService.getReceivedFriendRequests(userId);
            List<FriendRequestDTO> dtos = new ArrayList<>();
            for (FriendRequest request : requests) {
                dtos.add(convertRequestToDTO(request));
            }
            return ResponseEntity.ok(ResponseDTO.success(dtos));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/request/sent")
    public ResponseEntity<ResponseDTO<List<FriendRequestDTO>>> getSentRequests(@RequestAttribute("userId") Long userId) {
        try {
            List<FriendRequest> requests = friendService.getSentFriendRequests(userId);
            List<FriendRequestDTO> dtos = new ArrayList<>();
            for (FriendRequest request : requests) {
                dtos.add(convertRequestToDTO(request));
            }
            return ResponseEntity.ok(ResponseDTO.success(dtos));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/request/{requestId}/accept")
    public ResponseEntity<ResponseDTO<String>> acceptRequest(@RequestAttribute("userId") Long userId,
                                                             @PathVariable Long requestId) {
        try {
            friendService.acceptFriendRequest(requestId, userId);
            return ResponseEntity.ok(ResponseDTO.success("\u5df2\u540c\u610f\u597d\u53cb\u7533\u8bf7"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PostMapping("/request/{requestId}/reject")
    public ResponseEntity<ResponseDTO<String>> rejectRequest(@RequestAttribute("userId") Long userId,
                                                             @PathVariable Long requestId) {
        try {
            friendService.rejectFriendRequest(requestId, userId);
            return ResponseEntity.ok(ResponseDTO.success("\u5df2\u62d2\u7edd\u597d\u53cb\u7533\u8bf7"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/list")
    public ResponseEntity<ResponseDTO<List<FriendDTO>>> getFriendList(@RequestAttribute("userId") Long userId) {
        try {
            List<Friend> friends = friendService.getFriendList(userId);
            List<FriendDTO> friendDTOs = new ArrayList<>();
            for (Friend friend : friends) {
                friendDTOs.add(convertToDTO(friend));
            }
            return ResponseEntity.ok(ResponseDTO.success(friendDTOs));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/{friendId}")
    public ResponseEntity<ResponseDTO<FriendDTO>> getFriend(@RequestAttribute("userId") Long userId,
                                                            @PathVariable Long friendId) {
        try {
            Friend friend = friendService.getFriend(userId, friendId);
            return ResponseEntity.ok(ResponseDTO.success(convertToDTO(friend)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PutMapping("/{friendId}/remark")
    public ResponseEntity<ResponseDTO<FriendDTO>> updateRemark(@RequestAttribute("userId") Long userId,
                                                               @PathVariable Long friendId,
                                                               @RequestBody Map<String, String> request) {
        try {
            String remark = request.get("remark");
            Friend friend = friendService.updateFriendRemark(userId, friendId, remark);
            return ResponseEntity.ok(ResponseDTO.success(convertToDTO(friend)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @PutMapping("/{friendId}/group")
    public ResponseEntity<ResponseDTO<FriendDTO>> moveToGroup(@RequestAttribute("userId") Long userId,
                                                              @PathVariable Long friendId,
                                                              @RequestBody Map<String, String> request) {
        try {
            String groupName = request.get("groupName");
            Friend friend = friendService.moveToGroup(userId, friendId, groupName);
            return ResponseEntity.ok(ResponseDTO.success(convertToDTO(friend)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @DeleteMapping("/{friendId}")
    public ResponseEntity<ResponseDTO<String>> deleteFriend(@RequestAttribute("userId") Long userId,
                                                            @PathVariable Long friendId) {
        try {
            friendService.deleteFriend(userId, friendId);
            return ResponseEntity.ok(ResponseDTO.success("\u5220\u9664\u6210\u529f"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/count")
    public ResponseEntity<ResponseDTO<Long>> getFriendCount(@RequestAttribute("userId") Long userId) {
        try {
            return ResponseEntity.ok(ResponseDTO.success(friendService.getFriendCount(userId)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/check/{friendId}")
    public ResponseEntity<ResponseDTO<Boolean>> isFriend(@RequestAttribute("userId") Long userId,
                                                         @PathVariable Long friendId) {
        try {
            return ResponseEntity.ok(ResponseDTO.success(friendService.isFriend(userId, friendId)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private FriendDTO convertToDTO(Friend friend) {
        FriendDTO dto = new FriendDTO();
        dto.setId(friend.getId());
        dto.setUserId(friend.getUserId());
        dto.setFriendId(friend.getFriendId());
        dto.setRemark(friend.getRemark());
        dto.setGroupName(friend.getGroupName());
        dto.setStatus(friend.getStatus());
        dto.setCreatedAt(friend.getCreatedAt());
        dto.setUpdatedAt(friend.getUpdatedAt());

        try {
            User friendUser = userService.getUserById(friend.getFriendId());
            UserDTO userDTO = toSimpleUserDTO(friendUser);
            userDTO.setPhone(friendUser.getPhone());
            userDTO.setGender(friendUser.getGender());
            userDTO.setRegion(friendUser.getRegion());
            userDTO.setSignature(friendUser.getSignature());
            userDTO.setOnlineStatus(friendUser.getOnlineStatus());
            dto.setFriendUserInfo(userDTO);
        } catch (Exception ignored) {
        }

        return dto;
    }

    private FriendRequestDTO convertRequestToDTO(FriendRequest request) {
        FriendRequestDTO dto = new FriendRequestDTO();
        dto.setId(request.getId());
        dto.setFromUserId(request.getFromUserId());
        dto.setToUserId(request.getToUserId());
        dto.setRemark(request.getRemark());
        dto.setMessage(request.getMessage());
        dto.setStatus(request.getStatus());
        dto.setHandledAt(request.getHandledAt());
        dto.setCreatedAt(request.getCreatedAt());

        try {
            dto.setFromUserInfo(toSimpleUserDTO(userService.getUserById(request.getFromUserId())));
        } catch (Exception ignored) {
        }
        try {
            dto.setToUserInfo(toSimpleUserDTO(userService.getUserById(request.getToUserId())));
        } catch (Exception ignored) {
        }
        return dto;
    }

    private UserDTO toSimpleUserDTO(User user) {
        UserDTO userDTO = new UserDTO();
        userDTO.setId(user.getId());
        userDTO.setUserId(user.getUserId());
        userDTO.setNickname(user.getNickname());
        userDTO.setAvatar(user.getAvatar());
        return userDTO;
    }
}

