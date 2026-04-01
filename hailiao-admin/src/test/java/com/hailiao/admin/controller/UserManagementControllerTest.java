package com.hailiao.admin.controller;

import com.hailiao.common.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class UserManagementControllerTest {

    @Mock
    private UserService userService;

    @Mock
    private UserManageController userManageController;

    @InjectMocks
    private UserManagementController userManagementController;

    @Test
    void getUsersDelegatesToPrimaryController() {
        ResponseEntity<?> expected = ResponseEntity.ok("ok");
        doReturn(expected).when(userManageController).getUserList("alice", null, 1, 10);

        ResponseEntity<?> actual = userManagementController.getUsers(1, 10, "alice");

        assertEquals(expected, actual);
        verify(userManageController).getUserList("alice", null, 1, 10);
    }

    @Test
    void updateUserStatusBansUserWhenStatusIsZero() {
        ResponseEntity<?> expected = ResponseEntity.ok("detail");
        doNothing().when(userService).banUser(7L, null);
        doReturn(expected).when(userManageController).getUserById(7L);

        ResponseEntity<?> actual = userManagementController.updateUserStatus(7L, 0);

        assertEquals(expected, actual);
        verify(userService).banUser(7L, null);
        verify(userManageController).getUserById(7L);
    }

    @Test
    void updateUserStatusReturnsNotFoundWhenServiceThrows() {
        doThrow(new RuntimeException("missing")).when(userService).unbanUser(9L);

        ResponseEntity<?> actual = userManagementController.updateUserStatus(9L, 1);

        assertEquals(HttpStatus.NOT_FOUND, actual.getStatusCode());
        verify(userService).unbanUser(9L);
    }

    @Test
    void deleteUserReturnsOkWhenServiceSucceeds() {
        doNothing().when(userService).deleteUser(3L);

        ResponseEntity<Void> actual = userManagementController.deleteUser(3L);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        verify(userService).deleteUser(3L);
    }
}
