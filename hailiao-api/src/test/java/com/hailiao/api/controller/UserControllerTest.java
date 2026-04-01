package com.hailiao.api.controller;

import com.hailiao.api.dto.ChangePasswordRequestDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.SearchUserRequestDTO;
import com.hailiao.api.dto.UpdateOnlineStatusRequestDTO;
import com.hailiao.api.dto.UserDTO;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    @Mock
    private UserService userService;

    @InjectMocks
    private UserController userController;

    @Test
    void getProfileShouldReturnCurrentUserWithoutMaskingPhone() {
        User user = buildUser(1L, "1000000001", "13800138000");
        when(userService.getUserById(1L)).thenReturn(user);

        ResponseEntity<ResponseDTO<UserDTO>> response = userController.getProfile(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("13800138000", response.getBody().getData().getPhone());
    }

    @Test
    void getUserByIdShouldHidePhoneForOtherUser() {
        User user = buildUser(2L, "1000000002", "13900139000");
        when(userService.getUserById(2L)).thenReturn(user);

        ResponseEntity<ResponseDTO<UserDTO>> response = userController.getUserById(1L, 2L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNull(response.getBody().getData().getPhone());
    }

    @Test
    void changePasswordShouldRequireBothPasswords() {
        ChangePasswordRequestDTO request = new ChangePasswordRequestDTO();
        request.setOldPassword("old");

        ResponseEntity<ResponseDTO<String>> response = userController.changePassword(1L, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(400, response.getBody().getCode());
    }

    @Test
    void searchUserShouldRejectPhoneSearchWhenUserDisablesIt() {
        User user = buildUser(2L, "1000000002", "13900139000");
        user.setAllowSearchByPhone(false);

        SearchUserRequestDTO request = new SearchUserRequestDTO();
        request.setType("phone");
        request.setKeyword("13900139000");

        when(userService.getUserByPhone("13900139000")).thenReturn(user);

        ResponseEntity<ResponseDTO<UserDTO>> response = userController.searchUser(1L, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(400, response.getBody().getCode());
    }

    @Test
    void updateOnlineStatusShouldDelegateToService() {
        UpdateOnlineStatusRequestDTO request = new UpdateOnlineStatusRequestDTO();
        request.setStatus(2);

        ResponseEntity<ResponseDTO<String>> response = userController.updateOnlineStatus(1L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().getCode() == 200);
        verify(userService).updateOnlineStatus(1L, 2);
    }

    @Test
    void getOnlineStatusShouldReturnSimpleMap() {
        User user = buildUser(1L, "1000000001", "13800138000");
        user.setOnlineStatus(1);
        when(userService.getUserById(1L)).thenReturn(user);

        ResponseEntity<ResponseDTO<Map<String, Object>>> response = userController.getOnlineStatus(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().get("onlineStatus"));
    }

    private User buildUser(Long id, String userId, String phone) {
        User user = new User();
        user.setId(id);
        user.setUserId(userId);
        user.setPhone(phone);
        user.setNickname("tester");
        user.setAllowSearchByPhone(true);
        user.setShowOnlineStatus(true);
        user.setShowLastOnline(true);
        user.setNeedFriendVerification(true);
        user.setDeviceLock(false);
        user.setStatus(1);
        return user;
    }
}
